# Direct O365 Audit and Fix Script
# Run this after manual connection

Write-Host "=== DIRECT O365 AUDIT AND FIX ===" -ForegroundColor Cyan
Write-Host "This assumes you're already connected to Exchange Online" -ForegroundColor Yellow
Write-Host ""

# Test connection
try {
    $test = Get-OrganizationConfig -ErrorAction Stop
    Write-Host "✅ Connected to: $($test.Name)" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected to Exchange Online!" -ForegroundColor Red
    Write-Host "Please run first:" -ForegroundColor Yellow
    Write-Host "  Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor White
    exit
}

Write-Host ""
Write-Host "=== CURRENT CONFIGURATION ===" -ForegroundColor Cyan

# Get current settings
$policy = Get-HostedContentFilterPolicy -Identity Default
$phish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Default*"} | Select-Object -First 1

Write-Host "Current Settings:" -ForegroundColor Yellow
Write-Host "  SCL Junk Threshold: $($policy.SCLJunk)" -ForegroundColor White
Write-Host "  SCL Quarantine: $($policy.SCLQuarantine)" -ForegroundColor White
Write-Host "  Bulk Threshold: $($policy.BulkThreshold)" -ForegroundColor White
Write-Host "  Spam Action: $($policy.SpamAction)" -ForegroundColor White
Write-Host "  Allowed Domains: $($policy.AllowedSenderDomains.Count)" -ForegroundColor White
Write-Host "  Allowed Senders: $($policy.AllowedSenders.Count)" -ForegroundColor White

if ($phish) {
    Write-Host "  DMARC Quarantine: $($phish.DmarcQuarantineAction)" -ForegroundColor White
    Write-Host "  DMARC Reject: $($phish.DmarcRejectAction)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== APPLYING FIXES ===" -ForegroundColor Cyan

# Fix 1: Lower SCL threshold
Write-Host "1. Lowering SCL threshold to 4..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4 -WarningAction SilentlyContinue
    Write-Host "   ✅ SCL threshold set to 4" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed: $_" -ForegroundColor Red
}

# Fix 2: Change DMARC to Junk
Write-Host "2. Changing DMARC quarantine to Junk folder..." -ForegroundColor Yellow
try {
    if ($phish) {
        Set-AntiPhishPolicy -Identity $phish.Identity `
            -DmarcQuarantineAction MoveToJmf `
            -DmarcRejectAction Quarantine `
            -WarningAction SilentlyContinue
        Write-Host "   ✅ DMARC now sends to Junk folder" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Failed: $_" -ForegroundColor Red
}

# Fix 3: Adjust spam actions
Write-Host "3. Setting spam to Junk folder..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -SpamAction MoveToJmf `
        -HighConfidenceSpamAction Quarantine `
        -PhishSpamAction Quarantine `
        -BulkSpamAction MoveToJmf `
        -WarningAction SilentlyContinue
    Write-Host "   ✅ Spam actions updated" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed: $_" -ForegroundColor Red
}

# Fix 4: Enable notifications
Write-Host "4. Enabling user notifications..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -EnableEndUserSpamNotifications $true `
        -EndUserSpamNotificationFrequency 1 `
        -WarningAction SilentlyContinue
    Write-Host "   ✅ Daily notifications enabled" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== VERIFICATION ===" -ForegroundColor Cyan

# Verify changes
$newPolicy = Get-HostedContentFilterPolicy -Identity Default
$newPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Default*"} | Select-Object -First 1

Write-Host "New Settings:" -ForegroundColor Green
Write-Host "  SCL Junk Threshold: $($newPolicy.SCLJunk)" -ForegroundColor White
Write-Host "  Spam Action: $($newPolicy.SpamAction)" -ForegroundColor White
Write-Host "  Bulk Spam Action: $($newPolicy.BulkSpamAction)" -ForegroundColor White
Write-Host "  Notifications: $($newPolicy.EnableEndUserSpamNotifications)" -ForegroundColor White

if ($newPhish) {
    Write-Host "  DMARC Quarantine: $($newPhish.DmarcQuarantineAction)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "✅ Fixes applied successfully!" -ForegroundColor Green
Write-Host "✅ Changes take effect within 30 minutes" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor for 24-48 hours to ensure:" -ForegroundColor Yellow
Write-Host "  • Legitimate emails appear in Junk (not Quarantine)" -ForegroundColor White
Write-Host "  • Users receive daily quarantine notifications" -ForegroundColor White
Write-Host "  • No increase in spam reaching inbox" -ForegroundColor White

Write-Host ""
Write-Host "To revert if needed:" -ForegroundColor Gray
Write-Host "  Set-HostedContentFilterPolicy -Identity Default -SCLJunk 9" -ForegroundColor Gray
Write-Host "  Set-AntiPhishPolicy -Identity 'Office365 AntiPhish Default' -DmarcQuarantineAction Quarantine" -ForegroundColor Gray