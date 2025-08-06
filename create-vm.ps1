# Create VM for Power BI Vendor
Write-Host "Creating Windows 11 VM for Power BI vendor..." -ForegroundColor Yellow

# Generate secure password
Add-Type -AssemblyName System.Web
$vmPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)
$adminUser = "azureadmin"

# Create VM
az vm create `
    --resource-group vision `
    --name vm-pbi-vendor `
    --image Win11-22H2-Pro `
    --size Standard_D4s_v3 `
    --vnet-name vision-vnet `
    --subnet default `
    --public-ip-address '""' `
    --admin-username $adminUser `
    --admin-password $vmPassword `
    --assign-identity `
    --tags Environment=Vendor Purpose=PowerBI CreatedBy=ClaudeCode

# Save credentials
$credContent = @"
================================
VM Credentials - KEEP SECURE!
================================
VM Name: vm-pbi-vendor
Resource Group: vision
Username: $adminUser
Password: $vmPassword

IMPORTANT: Change this password on first login!
================================
"@

$credContent | Out-File -FilePath "vm-credentials-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Write-Host "VM credentials saved to file" -ForegroundColor Green

# Configure auto-patching
Write-Host "Configuring automatic patching..." -ForegroundColor Yellow
az vm update `
    --resource-group vision `
    --name vm-pbi-vendor `
    --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform

# Configure auto-shutdown
Write-Host "Setting up auto-shutdown at 7 PM..." -ForegroundColor Yellow
az vm auto-shutdown `
    --resource-group vision `
    --name vm-pbi-vendor `
    --time 1900

# Install Power BI Desktop
Write-Host "Installing Power BI Desktop (this may take a few minutes)..." -ForegroundColor Yellow
$installScript = 'winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements'
az vm run-command invoke `
    --resource-group vision `
    --name vm-pbi-vendor `
    --command-id RunPowerShellScript `
    --scripts $installScript

Write-Host ""
Write-Host "VM deployment completed!" -ForegroundColor Green
Write-Host "Storage endpoint: https://pbivend9084.dfs.core.windows.net/parquet" -ForegroundColor Cyan