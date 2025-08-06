# SETUP UNATTENDED O365 ACCESS WITH CERTIFICATE AUTHENTICATION
# This script sets up app-only authentication for automated Exchange Online access

Write-Host @"
================================================================================
           SETTING UP UNATTENDED O365 ACCESS WITH CERTIFICATE
================================================================================
This will:
1. Create a self-signed certificate
2. Register an app in Azure AD
3. Configure permissions
4. Enable unattended script execution
================================================================================
"@ -ForegroundColor Cyan

# Step 1: Create Self-Signed Certificate
Write-Host "`n[STEP 1] Creating Self-Signed Certificate..." -ForegroundColor Yellow

$certName = "O365-Automation-Cogitativo"
$cert = New-SelfSignedCertificate -Subject "CN=$certName" `
    -CertStoreLocation "cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(5)

Write-Host "✅ Certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Export certificate to file
$certPath = "C:\Users\andre.darby\Ops\O365-Automation.cer"
Export-Certificate -Cert $cert -FilePath $certPath
Write-Host "✅ Certificate exported to: $certPath" -ForegroundColor Green

# Step 2: Create Azure AD App Registration
Write-Host "`n[STEP 2] Creating Azure AD App Registration..." -ForegroundColor Yellow
Write-Host "Opening Azure Portal for app registration..." -ForegroundColor Cyan

# Generate the app registration URL
$tenantId = "cogitativo.onmicrosoft.com"
$portalUrl = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade"

Write-Host @"

MANUAL STEPS REQUIRED IN AZURE PORTAL:
=======================================
1. Go to: $portalUrl
2. Click 'New registration'
3. Name: O365-Automation-Cogitativo
4. Supported account types: Single tenant
5. Click 'Register'
6. Copy the Application (client) ID

After registration, continue with these steps:
"@ -ForegroundColor Yellow

$appId = Read-Host "Enter the Application ID from Azure Portal"

# Step 3: Upload Certificate to App
Write-Host "`n[STEP 3] Certificate Upload Instructions..." -ForegroundColor Yellow
Write-Host @"
In Azure Portal:
1. Go to your app registration
2. Click 'Certificates & secrets' in left menu
3. Click 'Upload certificate'
4. Upload: $certPath
5. Click 'Add'
"@ -ForegroundColor Cyan

Read-Host "Press Enter after uploading certificate"

# Step 4: Configure API Permissions
Write-Host "`n[STEP 4] API Permissions Configuration..." -ForegroundColor Yellow
Write-Host @"
In Azure Portal (still in your app):
1. Click 'API permissions' in left menu
2. Click 'Add a permission'
3. Select 'APIs my organization uses'
4. Search for 'Office 365 Exchange Online'
5. Select 'Application permissions'
6. Check 'Exchange.ManageAsApp'
7. Click 'Add permissions'
8. Click 'Grant admin consent for Cogitativo'
"@ -ForegroundColor Cyan

Read-Host "Press Enter after granting permissions"

# Step 5: Assign Exchange Administrator Role
Write-Host "`n[STEP 5] Assigning Exchange Administrator Role..." -ForegroundColor Yellow

# Connect to Azure AD
Write-Host "Connecting to Azure AD..." -ForegroundColor Gray
Connect-AzureAD

# Get the app's service principal
$servicePrincipal = Get-AzureADServicePrincipal -Filter "AppId eq '$appId'"

# Get the Exchange Administrator role
$exchangeAdminRole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq "Exchange Administrator"}

if (!$exchangeAdminRole) {
    # Activate the role if not already activated
    $roleTemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Exchange Administrator"}
    $exchangeAdminRole = Enable-AzureADDirectoryRole -RoleTemplateId $roleTemplate.ObjectId
}

# Add the service principal to the role
Add-AzureADDirectoryRoleMember -ObjectId $exchangeAdminRole.ObjectId -RefObjectId $servicePrincipal.ObjectId
Write-Host "✅ Exchange Administrator role assigned" -ForegroundColor Green

# Step 6: Create Connection Script
Write-Host "`n[STEP 6] Creating Connection Script..." -ForegroundColor Yellow

$connectionScript = @"
# UNATTENDED O365 CONNECTION SCRIPT
`$AppId = '$appId'
`$CertThumbprint = '$($cert.Thumbprint)'
`$Organization = 'cogitativo.onmicrosoft.com'

Write-Host "Connecting to Exchange Online (unattended)..." -ForegroundColor Yellow
Connect-ExchangeOnline ``
    -AppId `$AppId ``
    -CertificateThumbprint `$CertThumbprint ``
    -Organization `$Organization ``
    -ShowBanner:`$false

Write-Host "✅ Connected successfully!" -ForegroundColor Green
"@

$connectionScript | Out-File -FilePath "C:\Users\andre.darby\Ops\Connect-O365-Unattended.ps1" -Encoding UTF8
Write-Host "✅ Connection script created: Connect-O365-Unattended.ps1" -ForegroundColor Green

# Step 7: Create Full Audit Script with Unattended Auth
Write-Host "`n[STEP 7] Creating Full Audit Script..." -ForegroundColor Yellow

$auditScript = @"
# FULL O365 AUDIT WITH UNATTENDED AUTHENTICATION
`$AppId = '$appId'
`$CertThumbprint = '$($cert.Thumbprint)'
`$Organization = 'cogitativo.onmicrosoft.com'

# Connect unattended
Connect-ExchangeOnline ``
    -AppId `$AppId ``
    -CertificateThumbprint `$CertThumbprint ``
    -Organization `$Organization ``
    -ShowBanner:`$false

Write-Host "Connected! Running full audit..." -ForegroundColor Green

# [INSERT FULL AUDIT COMMANDS HERE]
Get-OrganizationConfig | Format-List
Get-AcceptedDomain | Format-Table
Get-HostedContentFilterPolicy | Format-List
Get-AntiPhishPolicy | Format-List
Get-TransportRule | Format-List
Get-AdminAuditLogConfig | Format-List

# Disconnect
Disconnect-ExchangeOnline -Confirm:`$false
Write-Host "Audit complete!" -ForegroundColor Green
"@

$auditScript | Out-File -FilePath "C:\Users\andre.darby\Ops\Run-O365-Audit-Unattended.ps1" -Encoding UTF8
Write-Host "✅ Audit script created: Run-O365-Audit-Unattended.ps1" -ForegroundColor Green

# Final Summary
Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "`nSaved Information:" -ForegroundColor Yellow
Write-Host "  App ID: $appId"
Write-Host "  Certificate Thumbprint: $($cert.Thumbprint)"
Write-Host "  Organization: cogitativo.onmicrosoft.com"

Write-Host "`nYou can now run unattended scripts using:" -ForegroundColor Cyan
Write-Host "  .\Connect-O365-Unattended.ps1" -ForegroundColor White
Write-Host "  .\Run-O365-Audit-Unattended.ps1" -ForegroundColor White

Write-Host "`n================================================================================`n" -ForegroundColor Cyan