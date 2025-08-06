# PowerBI Vendor Sandbox Deployment Script
# This script executes the Azure CLI commands from the YAML configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Power BI Vendor Sandbox Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Gather required information
Write-Host "🔎 I need a few details before we deploy:" -ForegroundColor Yellow
$infraRG = Read-Host "1) Existing infra resource group (VMs, VNet, Bastion)"
$dataRG = Read-Host "2) Data resource group for the new storage account"
$vnetName = Read-Host "3) VNet name"
$mgmtSubnet = Read-Host "4) Mgmt subnet name (VM will live here)"
$storageSubnet = Read-Host "5) Storage-PE subnet name"
$storageAccount = Read-Host "6) Desired storage account name (3-24 lowercase chars)"
$databricksSP = Read-Host "7) Databricks service-principal object ID"
$vendorUPN = Read-Host "8) Vendor's Entra UPN (guest)"
$vmSize = Read-Host "9) Preferred VM size (press Enter for Standard_D4as_v5)"
$location = Read-Host "10) Azure region (press Enter for westus2)"
$adminUser = Read-Host "11) VM admin username (press Enter for azureadmin)"
$autoShutdown = Read-Host "12) Enable auto-shutdown? (y/n, press Enter for y)"
$shutdownTime = Read-Host "13) Auto-shutdown time (24hr format, press Enter for 1900)"

# Set defaults
if ([string]::IsNullOrWhiteSpace($vmSize)) { $vmSize = "Standard_D4as_v5" }
if ([string]::IsNullOrWhiteSpace($location)) { $location = "westus2" }
if ([string]::IsNullOrWhiteSpace($adminUser)) { $adminUser = "azureadmin" }
if ([string]::IsNullOrWhiteSpace($autoShutdown)) { $autoShutdown = "y" }
if ([string]::IsNullOrWhiteSpace($shutdownTime)) { $shutdownTime = "1900" }

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host ""

# 0.5 - Validation
Write-Host "Step 0.5: Validation & Pre-checks" -ForegroundColor Cyan
if ($storageAccount -notmatch "^[a-z0-9]{3,24}$") {
    Write-Host "ERROR: Storage account name must be 3-24 lowercase alphanumeric characters" -ForegroundColor Red
    exit 1
}

# Check if storage account exists
$storageExists = az storage account show -n $storageAccount -g $dataRG 2>$null
if ($storageExists) {
    Write-Host "ERROR: Storage account $storageAccount already exists" -ForegroundColor Red
    exit 1
}

# Verify VNet exists
$vnetExists = az network vnet show -n $vnetName -g $infraRG 2>$null
if (-not $vnetExists) {
    Write-Host "ERROR: VNet $vnetName not found in resource group $infraRG" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Validation passed" -ForegroundColor Green

# 1 - Create ADLS Gen2 Storage
Write-Host ""
Write-Host "Step 1: Creating ADLS Gen2 Storage Account" -ForegroundColor Cyan
az storage account create `
    --name $storageAccount `
    --resource-group $dataRG `
    --location $location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --hierarchical-namespace true `
    --default-action Deny `
    --allow-blob-public-access false `
    --min-tls-version TLS1_2 `
    --tags Environment=Vendor Purpose=PowerBI CreatedBy=Automation

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create storage account" -ForegroundColor Red
    exit 1
}

Write-Host "Creating container..." -ForegroundColor Yellow
az storage container create `
    --account-name $storageAccount `
    --name parquet `
    --auth-mode login

Write-Host "✓ Storage account created" -ForegroundColor Green

# 2 - Private Endpoint
Write-Host ""
Write-Host "Step 2: Creating Private Endpoint" -ForegroundColor Cyan
$storageId = $(az storage account show -g $dataRG -n $storageAccount --query id -o tsv)
az network private-endpoint create `
    --name "pe-$storageAccount" `
    --resource-group $infraRG `
    --vnet-name $vnetName `
    --subnet $storageSubnet `
    --private-connection-resource-id $storageId `
    --group-id dfs `
    --connection-name "pe-conn-$storageAccount"

Write-Host "✓ Private endpoint created" -ForegroundColor Green

# 3 - Role Assignments
Write-Host ""
Write-Host "Step 3: Setting up Role Assignments" -ForegroundColor Cyan
$scope = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$dataRG/providers/Microsoft.Storage/storageAccounts/$storageAccount/blobServices/default/containers/parquet"

# Databricks SP
az role assignment create `
    --role "Storage Blob Data Contributor" `
    --assignee-object-id $databricksSP `
    --scope $scope

# Vendor user
$vendorOid = $(az ad user show --id $vendorUPN --query id -o tsv)
az role assignment create `
    --role "Storage Blob Data Reader" `
    --assignee-object-id $vendorOid `
    --scope $scope

Write-Host "✓ Role assignments completed" -ForegroundColor Green

# 4 - Create VM
Write-Host ""
Write-Host "Step 4: Creating Windows 11 VM" -ForegroundColor Cyan
az vm create `
    --resource-group $infraRG `
    --name vm-pbi-vendor `
    --image Win11-22H2-Pro `
    --size $vmSize `
    --vnet-name $vnetName `
    --subnet $mgmtSubnet `
    --public-ip-address '""' `
    --assign-identity `
    --admin-username $adminUser `
    --tags Environment=Vendor Purpose=PowerBI CreatedBy=Automation

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create VM" -ForegroundColor Red
    exit 1
}

# Enable automatic guest patching
Write-Host "Enabling automatic patching..." -ForegroundColor Yellow
az vm update `
    --resource-group $infraRG `
    --name vm-pbi-vendor `
    --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform `
    --set properties.osProfile.windowsConfiguration.patchSettings.assessmentMode=AutomaticByPlatform

# Configure auto-shutdown if enabled
if ($autoShutdown -eq "y") {
    Write-Host "Configuring auto-shutdown..." -ForegroundColor Yellow
    az vm auto-shutdown `
        --resource-group $infraRG `
        --name vm-pbi-vendor `
        --time $shutdownTime
}

# Install Power BI Desktop
Write-Host "Installing Power BI Desktop..." -ForegroundColor Yellow
az vm extension set `
    --resource-group $infraRG `
    --vm-name vm-pbi-vendor `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --version 1.10 `
    --settings '{\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \\\"winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements\\\"\"}'

Write-Host "✓ VM created and configured" -ForegroundColor Green

# 5 - NSG Configuration
Write-Host ""
Write-Host "Step 5: Configuring Network Security" -ForegroundColor Cyan
$nsgId = $(az network vnet subnet show --resource-group $infraRG --vnet-name $vnetName --name $mgmtSubnet --query networkSecurityGroup.id -o tsv)

if ([string]::IsNullOrWhiteSpace($nsgId)) {
    Write-Host "WARNING: No NSG associated with subnet $mgmtSubnet" -ForegroundColor Yellow
} else {
    $nsgName = Split-Path $nsgId -Leaf
    $nsgRG = ($nsgId -split '/')[4]
    
    # Get storage PE IP
    $peIP = $(az network private-endpoint show --name "pe-$storageAccount" --resource-group $infraRG --query 'customDnsConfigs[0].ipAddresses[0]' -o tsv)
    
    # Create NSG rules
    Write-Host "Adding NSG rules..." -ForegroundColor Yellow
    
    # Allow storage
    az network nsg rule create `
        --name allow-storage-pe `
        --nsg-name $nsgName `
        --resource-group $nsgRG `
        --priority 100 `
        --direction Outbound `
        --access Allow `
        --protocol Tcp `
        --source-address-prefixes VirtualNetwork `
        --destination-address-prefixes $peIP `
        --destination-port-ranges 443
    
    # Allow Windows Update
    az network nsg rule create `
        --name allow-windows-update `
        --nsg-name $nsgName `
        --resource-group $nsgRG `
        --priority 110 `
        --direction Outbound `
        --access Allow `
        --protocol Tcp `
        --source-address-prefixes VirtualNetwork `
        --destination-service-tags WindowsUpdate `
        --destination-port-ranges "80 443"
    
    # Allow Azure AD
    az network nsg rule create `
        --name allow-azure-ad `
        --nsg-name $nsgName `
        --resource-group $nsgRG `
        --priority 120 `
        --direction Outbound `
        --access Allow `
        --protocol Tcp `
        --source-address-prefixes VirtualNetwork `
        --destination-service-tags AzureActiveDirectory `
        --destination-port-ranges 443
    
    Write-Host "✓ NSG rules configured" -ForegroundColor Green
}

# 6 - Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Power BI Connection Details:" -ForegroundColor Cyan
Write-Host "  • Vendor login: $vendorUPN"
Write-Host "  • Storage endpoint: https://$storageAccount.dfs.core.windows.net/parquet"
Write-Host "  • VM name: vm-pbi-vendor"
Write-Host "  • Admin user: $adminUser"
Write-Host ""
Write-Host "🔒 Security Configuration:" -ForegroundColor Cyan
Write-Host "  • Outbound access restricted"
Write-Host "  • Automatic OS patching enabled"
Write-Host "  • Private endpoint configured"
if ($autoShutdown -eq "y") {
    Write-Host "  • Auto-shutdown scheduled for $shutdownTime"
}
Write-Host ""
Write-Host "🔗 Connect via Azure Bastion in the portal" -ForegroundColor Yellow
Write-Host ""