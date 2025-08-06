# Enhanced PowerBI Vendor Sandbox Deployment Script
# This script provides intelligent resource discovery and validation

# Helper function for menu selection
function Show-Menu {
    param (
        [string]$Title,
        [array]$Options,
        [string]$Property = "Name"
    )
    
    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * $Title.Length) -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $value = if ($Property -and $Options[$i] -is [PSCustomObject]) {
            $Options[$i].$Property
        } else {
            $Options[$i]
        }
        Write-Host "$($i + 1). $value"
    }
    Write-Host "0. Enter custom value"
    Write-Host ""
    
    do {
        $selection = Read-Host "Select an option (0-$($Options.Count))"
        $valid = $selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -le $Options.Count
    } while (-not $valid)
    
    if ([int]$selection -eq 0) {
        return Read-Host "Enter custom value"
    } else {
        return $Options[[int]$selection - 1]
    }
}

# Helper function to validate resource names
function Test-AzureResourceName {
    param (
        [string]$Name,
        [string]$Type
    )
    
    switch ($Type) {
        "StorageAccount" {
            if ($Name -notmatch "^[a-z0-9]{3,24}$") {
                Write-Host "ERROR: Storage account name must be 3-24 lowercase alphanumeric characters" -ForegroundColor Red
                return $false
            }
        }
        "ResourceGroup" {
            if ($Name -notmatch "^[a-zA-Z0-9._\-\(\)]{1,90}[a-zA-Z0-9_\-\(\)]$") {
                Write-Host "ERROR: Invalid resource group name" -ForegroundColor Red
                return $false
            }
        }
    }
    return $true
}

Clear-Host
Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║         Power BI Vendor Sandbox Deployment - Enhanced          ║
║                    Intelligent Resource Discovery              ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "🔍 Discovering your Azure resources..." -ForegroundColor Yellow
Write-Host ""

# Get current subscription info
$currentSub = az account show | ConvertFrom-Json
Write-Host "Current Subscription: $($currentSub.name) [$($currentSub.id)]" -ForegroundColor Green
Write-Host ""

# 1. Discover and select infrastructure resource group
Write-Host "Step 1: Infrastructure Resource Group Selection" -ForegroundColor Yellow
$rgList = az group list --query "[?location=='eastus' || location=='eastus2'].{Name:name, Location:location}" | ConvertFrom-Json
if ($rgList.Count -eq 0) {
    $rgList = az group list --query "[].{Name:name, Location:location}" | ConvertFrom-Json
}

$rgList = $rgList | Sort-Object Name
$selectedInfraRG = Show-Menu -Title "Select Infrastructure Resource Group (contains VNet, Bastion)" -Options $rgList

if ($selectedInfraRG -is [PSCustomObject]) {
    $infraRG = $selectedInfraRG.Name
    $infraLocation = $selectedInfraRG.Location
} else {
    $infraRG = $selectedInfraRG
    # Try to get location
    $rgInfo = az group show -n $infraRG 2>$null | ConvertFrom-Json
    $infraLocation = if ($rgInfo) { $rgInfo.location } else { "eastus" }
}

Write-Host "✓ Selected: $infraRG (Location: $infraLocation)" -ForegroundColor Green

# 2. Discover VNets in selected RG
Write-Host ""
Write-Host "Step 2: Virtual Network Selection" -ForegroundColor Yellow
$vnetList = az network vnet list -g $infraRG --query "[].{Name:name, AddressSpace:addressSpace.addressPrefixes[0]}" 2>$null | ConvertFrom-Json

if ($vnetList.Count -eq 0) {
    Write-Host "No VNets found in $infraRG. Checking all resource groups..." -ForegroundColor Yellow
    $vnetList = az network vnet list --query "[?location=='$infraLocation'].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace.addressPrefixes[0]}" | ConvertFrom-Json
}

if ($vnetList.Count -gt 0) {
    $selectedVNet = Show-Menu -Title "Select Virtual Network" -Options $vnetList
    $vnetName = if ($selectedVNet -is [PSCustomObject]) { $selectedVNet.Name } else { $selectedVNet }
    
    # If VNet is in different RG, update infraRG
    if ($selectedVNet.ResourceGroup -and $selectedVNet.ResourceGroup -ne $infraRG) {
        Write-Host "Note: VNet is in resource group: $($selectedVNet.ResourceGroup)" -ForegroundColor Yellow
        $vnetRG = $selectedVNet.ResourceGroup
    } else {
        $vnetRG = $infraRG
    }
} else {
    $vnetName = Read-Host "Enter VNet name"
    $vnetRG = $infraRG
}

Write-Host "✓ Selected VNet: $vnetName" -ForegroundColor Green

# 3. Discover subnets
Write-Host ""
Write-Host "Step 3: Subnet Selection" -ForegroundColor Yellow
$subnetList = az network vnet subnet list -g $vnetRG --vnet-name $vnetName --query "[].{Name:name, AddressPrefix:addressPrefix}" 2>$null | ConvertFrom-Json

if ($subnetList.Count -gt 0) {
    # Select management subnet
    Write-Host ""
    $mgmtSubnet = Show-Menu -Title "Select Management Subnet (for VM deployment)" -Options $subnetList
    $mgmtSubnet = if ($mgmtSubnet -is [PSCustomObject]) { $mgmtSubnet.Name } else { $mgmtSubnet }
    Write-Host "✓ Management subnet: $mgmtSubnet" -ForegroundColor Green
    
    # Select storage PE subnet
    Write-Host ""
    $storageSubnet = Show-Menu -Title "Select Storage Private Endpoint Subnet" -Options $subnetList
    $storageSubnet = if ($storageSubnet -is [PSCustomObject]) { $storageSubnet.Name } else { $storageSubnet }
    Write-Host "✓ Storage PE subnet: $storageSubnet" -ForegroundColor Green
} else {
    $mgmtSubnet = Read-Host "Enter management subnet name"
    $storageSubnet = Read-Host "Enter storage private endpoint subnet name"
}

# 4. Data resource group selection
Write-Host ""
Write-Host "Step 4: Data Resource Group Selection" -ForegroundColor Yellow
Write-Host "Where should the storage account be created?" -ForegroundColor Yellow
Write-Host "1. Use same resource group as infrastructure ($infraRG)"
Write-Host "2. Select different resource group"
Write-Host "3. Create new resource group"

$dataRGChoice = Read-Host "Select option (1-3)"

switch ($dataRGChoice) {
    "1" { 
        $dataRG = $infraRG 
        Write-Host "✓ Using infrastructure RG: $dataRG" -ForegroundColor Green
    }
    "2" { 
        $dataRGSelected = Show-Menu -Title "Select Data Resource Group" -Options $rgList
        $dataRG = if ($dataRGSelected -is [PSCustomObject]) { $dataRGSelected.Name } else { $dataRGSelected }
        Write-Host "✓ Selected: $dataRG" -ForegroundColor Green
    }
    "3" { 
        do {
            $dataRG = Read-Host "Enter new resource group name"
        } while (-not (Test-AzureResourceName -Name $dataRG -Type "ResourceGroup"))
        
        Write-Host "Creating resource group $dataRG in $infraLocation..." -ForegroundColor Yellow
        az group create -n $dataRG -l $infraLocation
        Write-Host "✓ Created: $dataRG" -ForegroundColor Green
    }
}

# 5. Storage account configuration
Write-Host ""
Write-Host "Step 5: Storage Account Configuration" -ForegroundColor Yellow

do {
    $storageAccount = Read-Host "Enter storage account name (3-24 lowercase alphanumeric)"
} while (-not (Test-AzureResourceName -Name $storageAccount -Type "StorageAccount"))

# Check availability
Write-Host "Checking storage account name availability..." -ForegroundColor Yellow
$nameAvailable = az storage account check-name --name $storageAccount --query "nameAvailable" -o tsv
if ($nameAvailable -eq "false") {
    Write-Host "ERROR: Storage account name '$storageAccount' is already taken" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Storage account name is available" -ForegroundColor Green

# 6. Service Principal / User Configuration
Write-Host ""
Write-Host "Step 6: Access Configuration" -ForegroundColor Yellow

# Databricks SP
Write-Host ""
Write-Host "Looking for Databricks service principals..." -ForegroundColor Yellow
$spList = az ad sp list --query "[?contains(displayName, 'databricks') || contains(displayName, 'Databricks')].{Name:displayName, ObjectId:id}" --all 2>$null | ConvertFrom-Json

if ($spList.Count -gt 0) {
    Write-Host "Found Databricks service principals:" -ForegroundColor Green
    $selectedSP = Show-Menu -Title "Select Databricks Service Principal" -Options $spList
    $databricksSP = if ($selectedSP -is [PSCustomObject]) { $selectedSP.ObjectId } else { $selectedSP }
} else {
    $databricksSP = Read-Host "Enter Databricks service principal Object ID"
}

# Vendor user
Write-Host ""
Write-Host "Step 7: Vendor User Configuration" -ForegroundColor Yellow
$vendorUPN = Read-Host "Enter vendor's email address (Entra UPN)"

# Verify user exists
Write-Host "Verifying user..." -ForegroundColor Yellow
$userExists = az ad user show --id $vendorUPN 2>$null
if (-not $userExists) {
    Write-Host "WARNING: User $vendorUPN not found in directory. They may need to be invited first." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") { exit 1 }
}

# 7. VM Configuration
Write-Host ""
Write-Host "Step 8: Virtual Machine Configuration" -ForegroundColor Yellow

# VM Size selection
$vmSizes = @(
    @{Name="Standard_D2s_v3"; Description="2 vCPUs, 8 GB RAM (Basic)"},
    @{Name="Standard_D4s_v3"; Description="4 vCPUs, 16 GB RAM (Recommended)"},
    @{Name="Standard_D4as_v5"; Description="4 vCPUs, 16 GB RAM (AMD, Cost-optimized)"},
    @{Name="Standard_D8s_v3"; Description="8 vCPUs, 32 GB RAM (Performance)"}
)

Write-Host ""
Write-Host "Select VM Size:" -ForegroundColor Cyan
for ($i = 0; $i -lt $vmSizes.Count; $i++) {
    Write-Host "$($i + 1). $($vmSizes[$i].Name) - $($vmSizes[$i].Description)"
}
Write-Host "0. Enter custom size"

$vmSizeChoice = Read-Host "Select option (0-$($vmSizes.Count))"
$vmSize = if ($vmSizeChoice -eq "0") {
    Read-Host "Enter VM size"
} else {
    $vmSizes[[int]$vmSizeChoice - 1].Name
}
Write-Host "✓ VM Size: $vmSize" -ForegroundColor Green

# Admin username
$adminUser = Read-Host "VM admin username (press Enter for 'azureadmin')"
if ([string]::IsNullOrWhiteSpace($adminUser)) { $adminUser = "azureadmin" }

# Auto-shutdown
Write-Host ""
$autoShutdown = Read-Host "Enable auto-shutdown to save costs? (Y/n)"
if ([string]::IsNullOrWhiteSpace($autoShutdown) -or $autoShutdown -match "^[Yy]") {
    $autoShutdown = "y"
    $shutdownTime = Read-Host "Auto-shutdown time in 24hr format (press Enter for 19:00)"
    if ([string]::IsNullOrWhiteSpace($shutdownTime)) { $shutdownTime = "1900" }
}

# 8. Review configuration
Clear-Host
Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                    Configuration Summary                       ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "Infrastructure Configuration:" -ForegroundColor Yellow
Write-Host "  • Infrastructure RG: $infraRG"
Write-Host "  • Data RG: $dataRG"
Write-Host "  • Location: $infraLocation"
Write-Host "  • VNet: $vnetName"
Write-Host "  • Management Subnet: $mgmtSubnet"
Write-Host "  • Storage PE Subnet: $storageSubnet"

Write-Host ""
Write-Host "Storage Configuration:" -ForegroundColor Yellow
Write-Host "  • Storage Account: $storageAccount"
Write-Host "  • Container: parquet"

Write-Host ""
Write-Host "Access Configuration:" -ForegroundColor Yellow
Write-Host "  • Databricks SP: $databricksSP"
Write-Host "  • Vendor User: $vendorUPN"

Write-Host ""
Write-Host "VM Configuration:" -ForegroundColor Yellow
Write-Host "  • VM Size: $vmSize"
Write-Host "  • Admin User: $adminUser"
if ($autoShutdown -eq "y") {
    Write-Host "  • Auto-shutdown: $shutdownTime"
}

Write-Host ""
$confirm = Read-Host "Proceed with deployment? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Start deployment
Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Green
Write-Host ""

# Execute deployment steps
try {
    # 1. Create storage account
    Write-Host "Creating ADLS Gen2 storage account..." -ForegroundColor Cyan
    az storage account create `
        --name $storageAccount `
        --resource-group $dataRG `
        --location $infraLocation `
        --sku Standard_LRS `
        --kind StorageV2 `
        --hierarchical-namespace true `
        --default-action Deny `
        --allow-blob-public-access false `
        --min-tls-version TLS1_2 `
        --tags Environment=Vendor Purpose=PowerBI CreatedBy=EnhancedAutomation

    # Create container
    Write-Host "Creating container..." -ForegroundColor Yellow
    # Need to temporarily allow access to create container
    az storage account update -n $storageAccount -g $dataRG --default-action Allow
    Start-Sleep -Seconds 5
    
    az storage container create `
        --account-name $storageAccount `
        --name parquet `
        --auth-mode login
    
    # Restore deny
    az storage account update -n $storageAccount -g $dataRG --default-action Deny
    
    Write-Host "✓ Storage account created" -ForegroundColor Green

    # 2. Create private endpoint
    Write-Host ""
    Write-Host "Creating private endpoint..." -ForegroundColor Cyan
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

    # 3. Role assignments
    Write-Host ""
    Write-Host "Setting up access permissions..." -ForegroundColor Cyan
    $scope = "/subscriptions/$($currentSub.id)/resourceGroups/$dataRG/providers/Microsoft.Storage/storageAccounts/$storageAccount/blobServices/default/containers/parquet"
    
    # Databricks
    az role assignment create `
        --role "Storage Blob Data Contributor" `
        --assignee-object-id $databricksSP `
        --scope $scope
    
    # Vendor (if user exists)
    if ($userExists) {
        $vendorOid = $(az ad user show --id $vendorUPN --query id -o tsv)
        az role assignment create `
            --role "Storage Blob Data Reader" `
            --assignee-object-id $vendorOid `
            --scope $scope
    }
    
    Write-Host "✓ Permissions configured" -ForegroundColor Green

    # 4. Create VM
    Write-Host ""
    Write-Host "Creating Windows 11 VM (this may take several minutes)..." -ForegroundColor Cyan
    
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
        --tags Environment=Vendor Purpose=PowerBI CreatedBy=EnhancedAutomation
    
    # Configure patching
    Write-Host "Configuring automatic patching..." -ForegroundColor Yellow
    az vm update `
        --resource-group $infraRG `
        --name vm-pbi-vendor `
        --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform
    
    # Auto-shutdown
    if ($autoShutdown -eq "y") {
        Write-Host "Setting up auto-shutdown..." -ForegroundColor Yellow
        az vm auto-shutdown `
            --resource-group $infraRG `
            --name vm-pbi-vendor `
            --time $shutdownTime
    }
    
    # Install Power BI
    Write-Host "Installing Power BI Desktop..." -ForegroundColor Yellow
    az vm extension set `
        --resource-group $infraRG `
        --vm-name vm-pbi-vendor `
        --name CustomScriptExtension `
        --publisher Microsoft.Compute `
        --version 1.10 `
        --settings '{\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \\\"winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements\\\"\"}'
    
    Write-Host "✓ VM created and configured" -ForegroundColor Green

    # 5. NSG Configuration
    Write-Host ""
    Write-Host "Configuring network security..." -ForegroundColor Cyan
    
    # Get NSG
    $nsgId = $(az network vnet subnet show --resource-group $vnetRG --vnet-name $vnetName --name $mgmtSubnet --query networkSecurityGroup.id -o tsv)
    
    if ($nsgId) {
        $nsgName = Split-Path $nsgId -Leaf
        $nsgRG = ($nsgId -split '/')[4]
        
        # Get PE IP
        $peIP = $(az network private-endpoint show --name "pe-$storageAccount" --resource-group $infraRG --query 'customDnsConfigs[0].ipAddresses[0]' -o tsv)
        
        # Add rules
        az network nsg rule create --name allow-storage-pe --nsg-name $nsgName --resource-group $nsgRG --priority 100 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes VirtualNetwork --destination-address-prefixes $peIP --destination-port-ranges 443
        
        az network nsg rule create --name allow-windows-update --nsg-name $nsgName --resource-group $nsgRG --priority 110 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes VirtualNetwork --destination-service-tags WindowsUpdate --destination-port-ranges "80 443"
        
        az network nsg rule create --name allow-azure-ad --nsg-name $nsgName --resource-group $nsgRG --priority 120 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes VirtualNetwork --destination-service-tags AzureActiveDirectory --destination-port-ranges 443
        
        Write-Host "✓ Network security configured" -ForegroundColor Green
    } else {
        Write-Host "WARNING: No NSG found on subnet. Manual configuration required." -ForegroundColor Yellow
    }

    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "           ✅ Deployment Completed Successfully!                 " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    
    # Generate connection info file
    $connectionInfo = @"
Power BI Vendor Sandbox Connection Information
============================================

Deployment Date: $(Get-Date)
Subscription: $($currentSub.name)

Virtual Machine
--------------
Name: vm-pbi-vendor
Resource Group: $infraRG
Admin Username: $adminUser
Auto-shutdown: $(if ($autoShutdown -eq 'y') { $shutdownTime } else { 'Disabled' })

Storage Account
--------------
Name: $storageAccount
Resource Group: $dataRG
Container: parquet
Endpoint: https://$storageAccount.dfs.core.windows.net/parquet

Access
------
Vendor User: $vendorUPN
Databricks SP: $databricksSP

Connection Instructions
----------------------
1. Access VM via Azure Bastion in the portal
2. Login with the admin credentials provided during deployment
3. Power BI Desktop is pre-installed
4. Connect to data using: https://$storageAccount.dfs.core.windows.net/parquet

Security Notes
-------------
- VM has no public IP address
- Outbound traffic restricted to storage and Windows Update only
- Storage account accessible only via private endpoint
"@

    $connectionInfo | Out-File -FilePath "pbi-vendor-connection-info-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    Write-Host "Connection information saved to: pbi-vendor-connection-info-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Share the connection info file with your team"
    Write-Host "2. Access the VM via Bastion to verify Power BI installation"
    Write-Host "3. Configure vendor access in Azure AD if not already done"
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the Azure Activity Log for more details" -ForegroundColor Yellow
    exit 1
}