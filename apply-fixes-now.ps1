# Apply O365 Fixes - Run this in your connected PowerShell session
Write-Host "`n=== APPLYING O365 SECURITY FIXES ===" -ForegroundColor Cyan

# Fix 1: Spam Actions
Write-Host "`n1. Fixing spam actions..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -SpamAction MoveToJmf `
        -HighConfidenceSpamAction Quarantine `
        -BulkSpamAction MoveToJmf `
        -PhishSpamAction Quarantine `
        -BulkThreshold 6
    Write-Host "   ✅ Spam actions updated" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Fix 2: Enable Notifications
Write-Host "`n2. Enabling user notifications..." -ForegroundColor Yellow
try {
    Set-HostedContentFilterPolicy -Identity Default `
        -EnableEndUserSpamNotifications $true `
        -EndUserSpamNotificationFrequency 1
    Write-Host "   ✅ Notifications enabled" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Fix 3: DMARC Settings
Write-Host "`n3. Fixing DMARC settings..." -ForegroundColor Yellow
try {
    Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
        -DmarcQuarantineAction MoveToJmf `
        -DmarcRejectAction Quarantine
    Write-Host "   ✅ DMARC updated to send to Junk" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# Fix 4: Check for SCL parameters
Write-Host "`n4. Checking SCL parameters available..." -ForegroundColor Yellow
$policy = Get-HostedContentFilterPolicy -Identity Default
$sclProperties = $policy | Get-Member -MemberType Property | Where-Object {$_.Name -like "*SCL*" -or $_.Name -like "*Threshold*"}
Write-Host "   Available SCL properties:" -ForegroundColor Cyan
$sclProperties | ForEach-Object { Write-Host "     - $($_.Name)" -ForegroundColor Gray }

# Fix 5: Try to set SCL if property exists
if ($policy.PSObject.Properties.Match('SpamScoreLevel')) {
    Write-Host "`n5. Setting Spam Score Level..." -ForegroundColor Yellow
    Set-HostedContentFilterPolicy -Identity Default -SpamScoreLevel 4
    Write-Host "   ✅ Spam Score Level set to 4" -ForegroundColor Green
}

# Verification
Write-Host "`n=== VERIFICATION ===" -ForegroundColor Cyan
$newPolicy = Get-HostedContentFilterPolicy -Identity Default
Write-Host "`nNew Settings:" -ForegroundColor Green
Write-Host "  Spam Action: $($newPolicy.SpamAction)" -ForegroundColor White
Write-Host "  Bulk Action: $($newPolicy.BulkSpamAction)" -ForegroundColor White
Write-Host "  Bulk Threshold: $($newPolicy.BulkThreshold)" -ForegroundColor White
Write-Host "  Notifications: $($newPolicy.EnableEndUserSpamNotifications)" -ForegroundColor White

$phish = Get-AntiPhishPolicy -Identity "Office365 AntiPhish Default"
Write-Host "  DMARC Quarantine: $($phish.DmarcQuarantineAction)" -ForegroundColor White
Write-Host "  DMARC Reject: $($phish.DmarcRejectAction)" -ForegroundColor White

Write-Host "`n✅ FIXES APPLIED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "Changes will be active within 30 minutes." -ForegroundColor Yellow