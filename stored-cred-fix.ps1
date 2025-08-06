# Use stored credential approach
$username = "andre.darby@cogitativo.com"

Write-Host "=== O365 FIX WITH STORED CREDENTIALS ===" -ForegroundColor Cyan

# Create credential object (will prompt once)
$password = Read-Host -AsSecureString "Enter password for $username"
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Connect with credential
Write-Host "Connecting..." -ForegroundColor Yellow
Connect-ExchangeOnline -Credential $credential -ShowBanner:$false

Write-Host "Connected! Applying fixes..." -ForegroundColor Green

# Apply all fixes
Set-HostedContentFilterPolicy -Identity Default `
    -SCLJunk 4 `
    -SpamAction MoveToJmf `
    -HighConfidenceSpamAction Quarantine `
    -BulkSpamAction MoveToJmf `
    -EnableEndUserSpamNotifications $true `
    -EndUserSpamNotificationFrequency 1

Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
    -DmarcQuarantineAction MoveToJmf `
    -DmarcRejectAction Quarantine

Write-Host "✅ ALL FIXES APPLIED!" -ForegroundColor Green

# Show results
$policy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "SCL: $($policy.SCLJunk)" -ForegroundColor Green
Write-Host "Spam Action: $($policy.SpamAction)" -ForegroundColor Green

Disconnect-ExchangeOnline -Confirm:$false