# Simplified PowerBI Vendor Sandbox Deployment Script
# Compatible with PowerShell on Windows

Clear-Host
Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║            Power BI Vendor Sandbox Deployment                  ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "This script will help you deploy a secure Power BI environment for vendors." -ForegroundColor Yellow
Write-Host ""

# Check Azure login
Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

$currentSub = $account | ConvertFrom-Json
Write-Host "✓ Logged in as: $($currentSub.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($currentSub.name)" -ForegroundColor Green
Write-Host ""

# Function to prompt with default
function Read-HostWithDefault {
    param(
        [string]$Prompt,
        [string]$Default
    )
    $value = Read-Host "$Prompt $(if($Default){"[$Default]"})"
    if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
    return $value
}

# 1. Resource Groups
Write-Host "=== Resource Group Configuration ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available resource groups:" -ForegroundColor Yellow
az group list --output table

Write-Host ""
$infraRG = Read-Host "Enter infrastructure resource group name (contains VNet/Bastion)"
$dataRG = Read-HostWithDefault -Prompt "Enter data resource group name (for storage)" -Default $infraRG

# Get location from infra RG
$rgInfo = az group show -n $infraRG 2>$null | ConvertFrom-Json
if (-not $rgInfo) {
    Write-Host "ERROR: Resource group '$infraRG' not found" -ForegroundColor Red
    exit 1
}
$location = $rgInfo.location
Write-Host "✓ Using location: $location" -ForegroundColor Green

# 2. Networking
Write-Host ""
Write-Host "=== Network Configuration ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available VNets in $infraRG`:" -ForegroundColor Yellow
az network vnet list -g $infraRG --output table

Write-Host ""
$vnetName = Read-Host "Enter VNet name"

# Get subnets
Write-Host ""
Write-Host "Available subnets in $vnetName`:" -ForegroundColor Yellow
az network vnet subnet list -g $infraRG --vnet-name $vnetName --output table

Write-Host ""
$mgmtSubnet = Read-Host "Enter management subnet name (for VM)"
$storageSubnet = Read-Host "Enter storage private endpoint subnet name"

# 3. Storage Account
Write-Host ""
Write-Host "=== Storage Configuration ===" -ForegroundColor Cyan
do {
    $storageAccount = Read-Host "Enter storage account name (3-24 lowercase letters and numbers only)"
    if ($storageAccount -notmatch '^[a-z0-9]{3,24}$') {
        Write-Host "Invalid format. Use only lowercase letters and numbers, 3-24 characters." -ForegroundColor Red
        continue
    }
    
    # Check availability
    $checkResult = az storage account check-name --name $storageAccount | ConvertFrom-Json
    if ($checkResult.nameAvailable -eq $false) {
        Write-Host "Name already taken. Please try another." -ForegroundColor Red
        continue
    }
    break
} while ($true)

Write-Host "✓ Storage account name available" -ForegroundColor Green

# 4. Access Configuration
Write-Host ""
Write-Host "=== Access Configuration ===" -ForegroundColor Cyan
$databricksSP = Read-Host "Enter Databricks service principal Object ID"
$vendorUPN = Read-Host "Enter vendor email address (Azure AD guest user)"

# 5. VM Configuration
Write-Host ""
Write-Host "=== VM Configuration ===" -ForegroundColor Cyan
Write-Host @"
Available VM sizes:
1. Standard_D2s_v3  (2 vCPU, 8GB RAM - Basic)
2. Standard_D4s_v3  (4 vCPU, 16GB RAM - Recommended)
3. Standard_D4as_v5 (4 vCPU, 16GB RAM - AMD, Cost-optimized)
4. Standard_D8s_v3  (8 vCPU, 32GB RAM - Performance)
"@

$vmChoice = Read-HostWithDefault -Prompt "Select VM size (1-4)" -Default "2"
$vmSize = switch ($vmChoice) {
    "1" { "Standard_D2s_v3" }
    "2" { "Standard_D4s_v3" }
    "3" { "Standard_D4as_v5" }
    "4" { "Standard_D8s_v3" }
    default { "Standard_D4s_v3" }
}

$adminUser = Read-HostWithDefault -Prompt "VM admin username" -Default "azureadmin"
$autoShutdown = Read-HostWithDefault -Prompt "Enable auto-shutdown? (y/n)" -Default "y"
if ($autoShutdown -eq "y") {
    $shutdownTime = Read-HostWithDefault -Prompt "Auto-shutdown time (24hr format)" -Default "1900"
}

# 6. Review
Write-Host ""
Write-Host "=== Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Infrastructure RG: $infraRG"
Write-Host "Data RG: $dataRG"
Write-Host "Location: $location"
Write-Host "VNet: $vnetName"
Write-Host "Subnets: $mgmtSubnet (VM), $storageSubnet (PE)"
Write-Host "Storage: $storageAccount"
Write-Host "VM Size: $vmSize"
Write-Host "Admin: $adminUser"
if ($autoShutdown -eq "y") {
    Write-Host "Auto-shutdown: $shutdownTime"
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
$startTime = Get-Date

try {
    # Create data RG if different
    if ($dataRG -ne $infraRG) {
        $dataRGExists = az group show -n $dataRG 2>$null
        if (-not $dataRGExists) {
            Write-Host "Creating resource group '$dataRG'..." -ForegroundColor Yellow
            az group create -n $dataRG -l $location
        }
    }

    # 1. Storage Account
    Write-Host ""
    Write-Host "[1/5] Creating storage account..." -ForegroundColor Cyan
    az storage account create `
        --name $storageAccount `
        --resource-group $dataRG `
        --location $location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --hierarchical-namespace true `
        --default-action Deny `
        --allow-blob-public-access false `
        --min-tls-version TLS1_2

    # Create container (need temporary access)
    Write-Host "Creating container..." -ForegroundColor Yellow
    az storage account update -n $storageAccount -g $dataRG --default-action Allow | Out-Null
    Start-Sleep -Seconds 10
    
    az storage container create `
        --account-name $storageAccount `
        --name parquet `
        --auth-mode login
    
    az storage account update -n $storageAccount -g $dataRG --default-action Deny | Out-Null
    Write-Host "✓ Storage account created" -ForegroundColor Green

    # 2. Private Endpoint
    Write-Host ""
    Write-Host "[2/5] Creating private endpoint..." -ForegroundColor Cyan
    $storageId = az storage account show -g $dataRG -n $storageAccount --query id -o tsv
    
    az network private-endpoint create `
        --name "pe-$storageAccount" `
        --resource-group $infraRG `
        --vnet-name $vnetName `
        --subnet $storageSubnet `
        --private-connection-resource-id $storageId `
        --group-id dfs `
        --connection-name "pe-conn-$storageAccount"
    
    Write-Host "✓ Private endpoint created" -ForegroundColor Green

    # 3. Role Assignments
    Write-Host ""
    Write-Host "[3/5] Configuring access permissions..." -ForegroundColor Cyan
    $subId = $currentSub.id
    $scope = "/subscriptions/$subId/resourceGroups/$dataRG/providers/Microsoft.Storage/storageAccounts/$storageAccount/blobServices/default/containers/parquet"
    
    # Databricks
    Write-Host "Assigning Databricks permissions..." -ForegroundColor Yellow
    az role assignment create `
        --role "Storage Blob Data Contributor" `
        --assignee-object-id $databricksSP `
        --scope $scope | Out-Null
    
    # Vendor
    Write-Host "Assigning vendor permissions..." -ForegroundColor Yellow
    $userCheck = az ad user show --id $vendorUPN 2>$null
    if ($userCheck) {
        $vendorOid = $userCheck | ConvertFrom-Json | Select-Object -ExpandProperty id
        az role assignment create `
            --role "Storage Blob Data Reader" `
            --assignee-object-id $vendorOid `
            --scope $scope | Out-Null
    } else {
        Write-Host "WARNING: User $vendorUPN not found. Add manually later." -ForegroundColor Yellow
    }
    Write-Host "✓ Permissions configured" -ForegroundColor Green

    # 4. Create VM
    Write-Host ""
    Write-Host "[4/5] Creating VM (this will take 5-10 minutes)..." -ForegroundColor Cyan
    
    # Generate secure password
    Add-Type -AssemblyName System.Web
    $vmPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)
    
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
    $credFile = "vm-credentials-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
@"
VM Credentials
==============
VM Name: vm-pbi-vendor
Username: $adminUser
Password: $vmPassword

IMPORTANT: Change this password on first login!
"@ | Out-File -FilePath $credFile
    
    Write-Host "✓ VM created (credentials saved to file)" -ForegroundColor Green
    
    # Configure VM
    Write-Host "Configuring VM settings..." -ForegroundColor Yellow
    
    # Auto-patching
    az vm update `
        --resource-group $infraRG `
        --name vm-pbi-vendor `
        --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform | Out-Null
    
    # Auto-shutdown
    if ($autoShutdown -eq "y") {
        az vm auto-shutdown `
            --resource-group $infraRG `
            --name vm-pbi-vendor `
            --time $shutdownTime | Out-Null
    }
    
    # Install Power BI
    Write-Host "Installing Power BI Desktop..." -ForegroundColor Yellow
    $installScript = @'
$ProgressPreference = 'SilentlyContinue'
winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements
'@
    
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($installScript))
    
    az vm run-command invoke `
        --resource-group $infraRG `
        --name vm-pbi-vendor `
        --command-id RunPowerShellScript `
        --scripts "powershell -EncodedCommand $encodedCommand" | Out-Null
    
    Write-Host "✓ VM configured" -ForegroundColor Green

    # 5. NSG Configuration
    Write-Host ""
    Write-Host "[5/5] Configuring network security..." -ForegroundColor Cyan
    
    # Get NSG info
    $subnetInfo = az network vnet subnet show -g $infraRG --vnet-name $vnetName -n $mgmtSubnet | ConvertFrom-Json
    if ($subnetInfo.networkSecurityGroup) {
        $nsgId = $subnetInfo.networkSecurityGroup.id
        $nsgName = Split-Path $nsgId -Leaf
        $nsgRG = ($nsgId -split '/')[4]
        
        # Get PE IP
        $peInfo = az network private-endpoint show -n "pe-$storageAccount" -g $infraRG | ConvertFrom-Json
        $peIP = $peInfo.customDnsConfigs[0].ipAddresses[0]
        
        Write-Host "Adding security rules to NSG '$nsgName'..." -ForegroundColor Yellow
        
        # Storage rule
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
            --destination-port-ranges 443 | Out-Null
        
        # Windows Update
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
            --destination-port-ranges 80 443 | Out-Null
        
        # Azure AD
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
            --destination-port-ranges 443 | Out-Null
        
        Write-Host "✓ Network security configured" -ForegroundColor Green
    } else {
        Write-Host "WARNING: No NSG found on subnet. Configure manually." -ForegroundColor Yellow
    }

    # Success!
    $duration = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "           ✅ DEPLOYMENT COMPLETED SUCCESSFULLY!                 " -ForegroundColor Green
    Write-Host "             Duration: $($duration.ToString('mm\:ss'))          " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    
    # Generate summary
    $summary = @"

Power BI Vendor Sandbox - Deployment Summary
==========================================

RESOURCE DETAILS
---------------
Storage Account: $storageAccount
Storage Endpoint: https://$storageAccount.dfs.core.windows.net/parquet
VM Name: vm-pbi-vendor
Resource Groups: $infraRG (infra), $dataRG (data)

ACCESS DETAILS
-------------
Vendor User: $vendorUPN
VM Admin: $adminUser (see vm-credentials-*.txt file)
Databricks SP: $databricksSP

NEXT STEPS
----------
1. Access VM via Azure Bastion in the portal
2. Login with saved credentials and change password
3. Verify Power BI Desktop is installed
4. Test storage connectivity
5. Share access details with vendor

PORTAL LINKS
-----------
VM: https://portal.azure.com/#@$($currentSub.tenantId)/resource/subscriptions/$($currentSub.id)/resourceGroups/$infraRG/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor
Storage: https://portal.azure.com/#@$($currentSub.tenantId)/resource/subscriptions/$($currentSub.id)/resourceGroups/$dataRG/providers/Microsoft.Storage/storageAccounts/$storageAccount
"@

    Write-Host $summary
    $summary | Out-File -FilePath "deployment-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    Write-Host ""
    Write-Host "Summary saved to: deployment-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt" -ForegroundColor Yellow

} catch {
    Write-Host ""
    Write-Host "❌ DEPLOYMENT FAILED!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Check Azure Activity Log for details" -ForegroundColor Yellow
    exit 1
}