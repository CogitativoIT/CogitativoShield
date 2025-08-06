# O365 Fix with Device Code Authentication
Write-Host "=== O365 SECURITY FIX - DEVICE CODE AUTH ===" -ForegroundColor Cyan

# Import module
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Try device code authentication (works without window)
Write-Host "`nConnecting with device code authentication..." -ForegroundColor Yellow
Write-Host "You'll get a code to enter at microsoft.com/devicelogin" -ForegroundColor Cyan

try {
    # Device code auth doesn't require window handle
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -Device -ShowBanner:$false
    Write-Host "✅ Connected successfully!" -ForegroundColor Green
} catch {
    Write-Host "Trying app-only authentication..." -ForegroundColor Yellow
    # Try certificate-based if available
    Connect-ExchangeOnline -AppId "YOUR_APP_ID" -CertificateThumbprint "YOUR_CERT" -Organization "cogitativo.onmicrosoft.com" -ShowBanner:$false
}

Write-Host "`n=== APPLYING FIXES ===" -ForegroundColor Cyan

# Apply all fixes
Write-Host "Setting SCL threshold to 4..." -ForegroundColor Yellow
Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4

Write-Host "Changing DMARC to Junk folder..." -ForegroundColor Yellow  
Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" -DmarcQuarantineAction MoveToJmf -DmarcRejectAction Quarantine

Write-Host "Setting spam to Junk folder..." -ForegroundColor Yellow
Set-HostedContentFilterPolicy -Identity Default -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -BulkSpamAction MoveToJmf

Write-Host "Enabling notifications..." -ForegroundColor Yellow
Set-HostedContentFilterPolicy -Identity Default -EnableEndUserSpamNotifications $true -EndUserSpamNotificationFrequency 1

Write-Host "`n✅ ALL FIXES APPLIED!" -ForegroundColor Green

# Verify
$policy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "`nNew Settings:" -ForegroundColor Cyan
Write-Host "  SCL: $($policy.SCLJunk)" -ForegroundColor White
Write-Host "  Spam Action: $($policy.SpamAction)" -ForegroundColor White
Write-Host "  Notifications: $($policy.EnableEndUserSpamNotifications)" -ForegroundColor White

Disconnect-ExchangeOnline -Confirm:$false