# Create App Registration for O365 Automation
# This script creates the app registration programmatically

Write-Host "Creating Azure AD App Registration for O365 Automation..." -ForegroundColor Cyan

# First, let's connect using your existing credentials
$tenantId = "24317511-81a4-42fb-bea5-f4b0735acba5"
$tenantDomain = "cogitativo.onmicrosoft.com"

# Install required module if not present
if (!(Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Host "Installing Azure PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name Az.Resources -Force -AllowClobber -Scope CurrentUser
}

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Yellow
Connect-AzAccount -TenantId $tenantId

# Create the app registration
$appName = "O365-Automation-Cogitativo-$(Get-Date -Format 'yyyyMMdd')"
Write-Host "Creating app: $appName" -ForegroundColor Yellow

$app = New-AzADApplication -DisplayName $appName -IdentifierUris "https://$tenantDomain/$appName"

Write-Host "✅ App created!" -ForegroundColor Green
Write-Host "App ID: $($app.ApplicationId)" -ForegroundColor Cyan

# Upload the certificate
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Thumbprint -eq "AB551929F68F2607C5F89752A6CC827DD028C3B5"}
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

$endDate = (Get-Date).AddYears(5)
New-AzADAppCredential -ApplicationId $app.ApplicationId -CertValue $keyValue -EndDate $endDate

Write-Host "✅ Certificate uploaded!" -ForegroundColor Green

# Create service principal
$sp = New-AzADServicePrincipal -ApplicationId $app.ApplicationId
Write-Host "✅ Service Principal created!" -ForegroundColor Green

# Add Exchange.ManageAsApp permission
# This requires Graph API permissions which we'll need to add manually

Write-Host "`n=== MANUAL STEPS REQUIRED ===" -ForegroundColor Yellow
Write-Host "1. Go to: https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade"
Write-Host "2. Find app: $appName"
Write-Host "3. Go to API Permissions"
Write-Host "4. Add permission -> Office 365 Exchange Online -> Application -> Exchange.ManageAsApp"
Write-Host "5. Grant admin consent"

# Save the App ID to config
$config = @{
    AppId = $app.ApplicationId.ToString()
    CertThumbprint = "AB551929F68F2607C5F89752A6CC827DD028C3B5"
    Organization = "cogitativo.onmicrosoft.com"
}

$config | ConvertTo-Json | Out-File "C:\Users\andre.darby\Ops\o365-config.json"
Write-Host "`n✅ Configuration saved to o365-config.json" -ForegroundColor Green
Write-Host "App ID: $($app.ApplicationId)" -ForegroundColor Cyan