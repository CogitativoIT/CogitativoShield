# Automated App Registration Creation
# Uses existing authentication to create the app

$tenantId = "24317511-81a4-42fb-bea5-f4b0735acba5"
$certThumbprint = "AB551929F68F2607C5F89752A6CC827DD028C3B5"

Write-Host "Attempting to create app registration automatically..." -ForegroundColor Cyan

# Try using Azure CLI which might already be authenticated
$appName = "O365-Automation-Cogitativo"

Write-Host "Creating app using Azure CLI..." -ForegroundColor Yellow

# Create the app
$result = az ad app create --display-name $appName --query appId -o tsv 2>$null

if ($result) {
    Write-Host "✅ App created successfully!" -ForegroundColor Green
    Write-Host "App ID: $result" -ForegroundColor Cyan
    
    # Save to config
    $config = @{
        AppId = $result
        CertThumbprint = $certThumbprint
        Organization = "cogitativo.onmicrosoft.com"
    }
    
    $config | ConvertTo-Json | Out-File "C:\Users\andre.darby\Ops\o365-config.json"
    Write-Host "✅ Configuration saved!" -ForegroundColor Green
    
    # Upload certificate
    $certPath = "C:\Users\andre.darby\Ops\O365-Automation.cer"
    az ad app credential reset --id $result --cert "@$certPath" --append
    
    # Add permissions
    # Exchange.ManageAsApp permission ID
    $exchangeAppId = "00000002-0000-0ff1-ce00-000000000000"
    $permissionId = "dc50a0fb-09a3-484d-be87-e023b12c6440"
    
    az ad app permission add --id $result --api $exchangeAppId --api-permissions "$permissionId=Role"
    az ad app permission admin-consent --id $result
    
    Write-Host "✅ Permissions configured!" -ForegroundColor Green
    Write-Host "`nApp ID: $result" -ForegroundColor Green
    Write-Host "You can now run the audit script!" -ForegroundColor Cyan
    
} else {
    Write-Host "Azure CLI not authenticated. Trying alternative method..." -ForegroundColor Yellow
    
    # Generate a simple App ID for manual creation
    $suggestedAppId = [guid]::NewGuid().ToString()
    
    Write-Host "`n=== MANUAL APP REGISTRATION REQUIRED ===" -ForegroundColor Yellow
    Write-Host "Since we can't auto-create, here's what to do:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Open: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/CreateApplicationBlade/quickStartType~/null/isMSAApp~/false" -ForegroundColor White
    Write-Host "2. Name: O365-Automation-Cogitativo" -ForegroundColor White
    Write-Host "3. After creation, copy the Application ID" -ForegroundColor White
    Write-Host "4. Upload certificate: C:\Users\andre.darby\Ops\O365-Automation.cer" -ForegroundColor White
    Write-Host "5. Add API permission: Office 365 Exchange Online -> Exchange.ManageAsApp" -ForegroundColor White
    Write-Host "6. Grant admin consent" -ForegroundColor White
    Write-Host ""
    Write-Host "Then update the config with your App ID:" -ForegroundColor Yellow
    Write-Host '$appId = "YOUR-APP-ID-HERE"' -ForegroundColor Gray
    Write-Host '@{AppId=$appId; CertThumbprint="AB551929F68F2607C5F89752A6CC827DD028C3B5"; Organization="cogitativo.onmicrosoft.com"} | ConvertTo-Json | Out-File "C:\Users\andre.darby\Ops\o365-config.json"' -ForegroundColor Gray
}