# O365 Security Fix - Manual Commands
# Copy and paste these commands after connecting

# STEP 1: CONNECT (Run this first)
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com

# STEP 2: CHECK CURRENT SETTINGS
Write-Host "`n=== CURRENT SETTINGS ===" -ForegroundColor Cyan
$policy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "SCL Junk: $($policy.SCLJunk)" -ForegroundColor Yellow
Write-Host "Spam Action: $($policy.SpamAction)" -ForegroundColor Yellow
Write-Host "Allowed Domains: $($policy.AllowedSenderDomains.Count)" -ForegroundColor Yellow
$phish = Get-AntiPhishPolicy | Where-Object {$_.Name -like "*Default*"} | Select-Object -First 1
Write-Host "DMARC Action: $($phish.DmarcQuarantineAction)" -ForegroundColor Yellow

# STEP 3: APPLY ALL FIXES
Write-Host "`n=== APPLYING FIXES ===" -ForegroundColor Cyan

# Fix SCL threshold
Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4
Write-Host "✅ SCL threshold set to 4" -ForegroundColor Green

# Fix DMARC to Junk
Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" -DmarcQuarantineAction MoveToJmf -DmarcRejectAction Quarantine
Write-Host "✅ DMARC now goes to Junk" -ForegroundColor Green

# Fix spam actions
Set-HostedContentFilterPolicy -Identity Default -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -BulkSpamAction MoveToJmf
Write-Host "✅ Spam goes to Junk" -ForegroundColor Green

# Enable notifications
Set-HostedContentFilterPolicy -Identity Default -EnableEndUserSpamNotifications $true -EndUserSpamNotificationFrequency 1
Write-Host "✅ Notifications enabled" -ForegroundColor Green

# STEP 4: VERIFY CHANGES
Write-Host "`n=== VERIFICATION ===" -ForegroundColor Cyan
$newPolicy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "NEW SCL Junk: $($newPolicy.SCLJunk)" -ForegroundColor Green
Write-Host "NEW Spam Action: $($newPolicy.SpamAction)" -ForegroundColor Green
Write-Host "Notifications: $($newPolicy.EnableEndUserSpamNotifications)" -ForegroundColor Green

Write-Host "`n✅ ALL FIXES APPLIED!" -ForegroundColor Green
Write-Host "Changes take effect in 30 minutes" -ForegroundColor Yellow

# STEP 5: DISCONNECT
Disconnect-ExchangeOnline -Confirm:$false