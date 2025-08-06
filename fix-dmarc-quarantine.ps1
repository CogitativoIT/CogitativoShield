# Fix DMARC Quarantine Issues - Reduce False Positives
# This script adjusts settings to prevent legitimate emails from being quarantined

Write-Host "=== FIXING DMARC QUARANTINE ISSUES ===" -ForegroundColor Cyan
Write-Host "This will adjust settings to reduce false positives while maintaining security" -ForegroundColor Yellow
Write-Host ""

# Test connection
try {
    $test = Get-OrganizationConfig -ErrorAction Stop | Out-Null
    Write-Host "✅ Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected. Please run: Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor Red
    exit
}

# 1. SHOW CURRENT SETTINGS
Write-Host "`n📊 CURRENT SETTINGS:" -ForegroundColor Yellow
$currentPolicy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "  SCL Junk Threshold: $($currentPolicy.SCLJunk)"
Write-Host "  SCL Quarantine Threshold: $($currentPolicy.SCLQuarantine)" 
Write-Host "  Bulk Threshold: $($currentPolicy.BulkThreshold)"
Write-Host "  Spam Action: $($currentPolicy.SpamAction)"
Write-Host "  High Confidence Spam Action: $($currentPolicy.HighConfidenceSpamAction)"

$phishPolicy = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Default*"} | Select-Object -First 1
if ($phishPolicy) {
    Write-Host "  DMARC Quarantine Action: $($phishPolicy.DmarcQuarantineAction)"
    Write-Host "  DMARC Reject Action: $($phishPolicy.DmarcRejectAction)"
}

# 2. APPLY FIXES
Write-Host "`n🔧 APPLYING FIXES..." -ForegroundColor Cyan

# Fix 1: Adjust SCL threshold to 4 (moves more to Junk instead of Quarantine)
Write-Host "`n1. Setting SCL Junk threshold to 4..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4
    Write-Host "   ✅ SCL threshold adjusted to 4" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to adjust SCL threshold: $_" -ForegroundColor Red
}

# Fix 2: Change DMARC quarantine action to move to Junk instead
Write-Host "`n2. Changing DMARC quarantine action to Junk folder..." -ForegroundColor Yellow
try {
    if ($phishPolicy) {
        Set-AntiPhishPolicy -Identity $phishPolicy.Identity `
            -DmarcQuarantineAction MoveToJmf `
            -DmarcRejectAction Quarantine
        Write-Host "   ✅ DMARC quarantine now moves to Junk, only reject goes to quarantine" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ No default anti-phish policy found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Failed to adjust DMARC action: $_" -ForegroundColor Red
}

# Fix 3: Ensure spam goes to Junk not Quarantine for normal spam
Write-Host "`n3. Setting regular spam to go to Junk folder..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -SpamAction MoveToJmf `
        -HighConfidenceSpamAction Quarantine `
        -PhishSpamAction Quarantine `
        -HighConfidencePhishAction Quarantine `
        -BulkSpamAction MoveToJmf
    Write-Host "   ✅ Regular spam → Junk, High confidence → Quarantine" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to adjust spam actions: $_" -ForegroundColor Red
}

# Fix 4: Enable end-user spam notifications
Write-Host "`n4. Enabling end-user quarantine notifications..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -EnableEndUserSpamNotifications $true `
        -EndUserSpamNotificationFrequency 1
    Write-Host "   ✅ Users will receive daily quarantine notifications" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to enable notifications: $_" -ForegroundColor Red
}

# Fix 5: Verify allowed lists are properly configured
Write-Host "`n5. Verifying allowed lists..." -ForegroundColor Yellow
$policy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "   Allowed Sender Domains: $($policy.AllowedSenderDomains.Count) configured"
Write-Host "   Allowed Senders: $($policy.AllowedSenders.Count) configured"

# 3. VERIFY NEW SETTINGS
Write-Host "`n✅ NEW SETTINGS APPLIED:" -ForegroundColor Green
$newPolicy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "  SCL Junk Threshold: $($newPolicy.SCLJunk)" -ForegroundColor White
Write-Host "  Spam Action: $($newPolicy.SpamAction)" -ForegroundColor White
Write-Host "  Bulk Spam Action: $($newPolicy.BulkSpamAction)" -ForegroundColor White
Write-Host "  End User Notifications: $($newPolicy.EnableEndUserSpamNotifications)" -ForegroundColor White

$newPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true -or $_.Name -like "*Default*"} | Select-Object -First 1
if ($newPhish) {
    Write-Host "  DMARC Quarantine Action: $($newPhish.DmarcQuarantineAction)" -ForegroundColor White
}

# 4. ADDITIONAL RECOMMENDATIONS
Write-Host "`n📋 ADDITIONAL STEPS TO CONSIDER:" -ForegroundColor Cyan
Write-Host "1. Monitor quarantine for next 24-48 hours" -ForegroundColor White
Write-Host "2. Add any legitimate senders still being blocked to allowed lists" -ForegroundColor White
Write-Host "3. Consider creating mail flow rules for known good senders" -ForegroundColor White
Write-Host "4. Review DMARC reports to identify authentication failures" -ForegroundColor White

Write-Host "`n💡 TO ADD MORE ALLOWED SENDERS:" -ForegroundColor Yellow
Write-Host '   $newDomains = @("example.com", "trusted.org")' -ForegroundColor Gray
Write-Host '   Set-HostedContentFilterPolicy -Identity Default -AllowedSenderDomains @{Add=$newDomains}' -ForegroundColor Gray

Write-Host "`n🔄 TO REVERT CHANGES IF NEEDED:" -ForegroundColor Yellow
Write-Host "   Set-HostedContentFilterPolicy -Identity Default -SCLJunk 9" -ForegroundColor Gray
Write-Host "   Set-AntiPhishPolicy -Identity 'Office365 AntiPhish Default' -DmarcQuarantineAction Quarantine" -ForegroundColor Gray

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Green
Write-Host "Changes take effect within 30 minutes" -ForegroundColor Yellow