# Power BI Vendor Sandbox - Quick Deployment Script
# Run this to deploy a secure Power BI environment for vendors

Write-Host ""
Write-Host "Power BI Vendor Sandbox Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if logged in
try {
    $account = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Azure CLI not found or not logged in." -ForegroundColor Red
    exit 1
}

$currentSub = $account | ConvertFrom-Json
Write-Host "Subscription: $($currentSub.name)" -ForegroundColor Green
Write-Host "User: $($currentSub.user.name)" -ForegroundColor Green
Write-Host ""

# Show available resource groups
Write-Host "Available Resource Groups:" -ForegroundColor Yellow
az group list --output table
Write-Host ""

# Gather inputs
Write-Host "Please provide the following information:" -ForegroundColor Yellow
Write-Host ""

$infraRG = Read-Host "1. Infrastructure resource group name"
$vnetName = Read-Host "2. Virtual network name"
$mgmtSubnet = Read-Host "3. Management subnet name (for VM)"
$storageSubnet = Read-Host "4. Storage PE subnet name"
$storageAccount = Read-Host "5. Storage account name (lowercase, 3-24 chars)"
$databricksSP = Read-Host "6. Databricks service principal ID"
$vendorEmail = Read-Host "7. Vendor email address"

# Optional parameters with defaults
Write-Host ""
Write-Host "Optional (press Enter for defaults):" -ForegroundColor Yellow
$dataRG = Read-Host "8. Data resource group [$infraRG]"
if (-not $dataRG) { $dataRG = $infraRG }

$vmSize = Read-Host "9. VM size [Standard_D4s_v3]"
if (-not $vmSize) { $vmSize = "Standard_D4s_v3" }

$adminUser = Read-Host "10. VM admin username [azureadmin]"
if (-not $adminUser) { $adminUser = "azureadmin" }

# Get location
$rgInfo = az group show -n $infraRG 2>$null | ConvertFrom-Json
$location = $rgInfo.location

# Confirm
Write-Host ""
Write-Host "Ready to deploy with these settings:" -ForegroundColor Cyan
Write-Host "  Location: $location"
Write-Host "  Infra RG: $infraRG"
Write-Host "  Data RG: $dataRG"
Write-Host "  VNet/Subnets: $vnetName / $mgmtSubnet, $storageSubnet"
Write-Host "  Storage: $storageAccount"
Write-Host "  VM: vm-pbi-vendor ($vmSize)"
Write-Host ""

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne 'y') { exit 0 }

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Green

# Generate password
Add-Type -AssemblyName System.Web
$vmPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)

# Deploy storage
Write-Host "Creating storage account..." -ForegroundColor Yellow
az storage account create `
    --name $storageAccount `
    --resource-group $dataRG `
    --location $location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --hierarchical-namespace true `
    --default-action Deny `
    --min-tls-version TLS1_2

# Create container
az storage account update -n $storageAccount -g $dataRG --default-action Allow
Start-Sleep -Seconds 5
az storage container create --account-name $storageAccount --name parquet --auth-mode login
az storage account update -n $storageAccount -g $dataRG --default-action Deny

Write-Host "Creating private endpoint..." -ForegroundColor Yellow
$storageId = az storage account show -g $dataRG -n $storageAccount --query id -o tsv
az network private-endpoint create `
    --name "pe-$storageAccount" `
    --resource-group $infraRG `
    --vnet-name $vnetName `
    --subnet $storageSubnet `
    --private-connection-resource-id $storageId `
    --group-id dfs `
    --connection-name "pe-conn-$storageAccount"

Write-Host "Setting permissions..." -ForegroundColor Yellow
$scope = "/subscriptions/$($currentSub.id)/resourceGroups/$dataRG/providers/Microsoft.Storage/storageAccounts/$storageAccount/blobServices/default/containers/parquet"
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $databricksSP --scope $scope

# Try to add vendor
$userInfo = az ad user show --id $vendorEmail 2>$null
if ($userInfo) {
    $vendorId = ($userInfo | ConvertFrom-Json).id
    az role assignment create --role "Storage Blob Data Reader" --assignee-object-id $vendorId --scope $scope
}

Write-Host "Creating VM..." -ForegroundColor Yellow
az vm create `
    --resource-group $infraRG `
    --name vm-pbi-vendor `
    --image Win11-22H2-Pro `
    --size $vmSize `
    --vnet-name $vnetName `
    --subnet $mgmtSubnet `
    --public-ip-address '""' `
    --admin-username $adminUser `
    --admin-password $vmPassword `
    --assign-identity

# Save credentials
"VM: vm-pbi-vendor`nUsername: $adminUser`nPassword: $vmPassword" | Out-File "vm-credentials.txt"

Write-Host "Configuring VM..." -ForegroundColor Yellow
az vm update -g $infraRG -n vm-pbi-vendor --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform
az vm auto-shutdown -g $infraRG -n vm-pbi-vendor --time 1900

# Install Power BI
$script = 'winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements'
az vm run-command invoke -g $infraRG -n vm-pbi-vendor --command-id RunPowerShellScript --scripts $script

Write-Host ""
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Storage endpoint: https://$storageAccount.dfs.core.windows.net/parquet" -ForegroundColor Cyan
Write-Host "VM credentials saved to: vm-credentials.txt" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access the VM via Azure Bastion in the portal." -ForegroundColor Yellow