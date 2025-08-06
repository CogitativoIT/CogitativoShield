# COMPREHENSIVE O365 AUDIT - RUNS IN YOUR EXISTING SESSION
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "C:\Users\andre.darby\Ops\O365-COMPLETE-AUDIT-$timestamp.txt"

Start-Transcript -Path $reportFile

Write-Host @"
================================================================================
              COMPREHENSIVE O365 SECURITY AUDIT
                        Organization: Cogitativo.com
                        Date: $(Get-Date)
================================================================================
"@ -ForegroundColor Cyan

# 1. Organization
Write-Host "`n[1/20] ORGANIZATION CONFIGURATION" -ForegroundColor Yellow
Get-OrganizationConfig | Format-List

# 2. Domains
Write-Host "`n[2/20] ACCEPTED DOMAINS" -ForegroundColor Yellow
Get-AcceptedDomain | Format-Table -AutoSize

# 3. DKIM
Write-Host "`n[3/20] DKIM CONFIGURATION" -ForegroundColor Yellow
Get-DkimSigningConfig | Format-Table -AutoSize

# 4. Anti-Spam Policies
Write-Host "`n[4/20] ANTI-SPAM POLICIES" -ForegroundColor Yellow
Get-HostedContentFilterPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 5. Anti-Phishing
Write-Host "`n[5/20] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
Get-AntiPhishPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 6. Connection Filters
Write-Host "`n[6/20] CONNECTION FILTERS" -ForegroundColor Yellow
Get-HostedConnectionFilterPolicy | Format-List

# 7. Mail Flow Rules
Write-Host "`n[7/20] MAIL FLOW RULES" -ForegroundColor Yellow
Get-TransportRule | Format-List

# 8. Outbound Spam
Write-Host "`n[8/20] OUTBOUND SPAM FILTER" -ForegroundColor Yellow
Get-HostedOutboundSpamFilterPolicy | Format-List

# 9. Malware Filter
Write-Host "`n[9/20] MALWARE FILTER" -ForegroundColor Yellow
Get-MalwareFilterPolicy | Format-List

# 10. Admin Audit
Write-Host "`n[10/20] ADMIN AUDIT CONFIGURATION" -ForegroundColor Yellow
Get-AdminAuditLogConfig | Format-List

# 11. Role Groups
Write-Host "`n[11/20] ADMIN ROLE GROUPS" -ForegroundColor Yellow
Get-RoleGroup | Where-Object {$_.Members.Count -gt 0} | Format-List

# 12. Tenant Allow/Block
Write-Host "`n[12/20] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
try {
    Get-TenantAllowBlockListSpoofItems | Format-Table -AutoSize
} catch {
    Write-Host "Unable to retrieve" -ForegroundColor Gray
}

# 13. Mobile Device
Write-Host "`n[13/20] MOBILE DEVICE POLICIES" -ForegroundColor Yellow
Get-MobileDeviceMailboxPolicy | Format-List

# 14. Sharing
Write-Host "`n[14/20] SHARING POLICIES" -ForegroundColor Yellow
Get-SharingPolicy | Format-List

# 15. Quarantine
Write-Host "`n[15/20] QUARANTINE POLICIES" -ForegroundColor Yellow
try {
    Get-QuarantinePolicy | Format-List
} catch {
    Write-Host "Not accessible" -ForegroundColor Gray
}

# 16. Safe Attachments
Write-Host "`n[16/20] SAFE ATTACHMENTS" -ForegroundColor Yellow
try {
    Get-SafeAttachmentPolicy | Format-List
} catch {
    Write-Host "Not available" -ForegroundColor Gray
}

# 17. Safe Links
Write-Host "`n[17/20] SAFE LINKS" -ForegroundColor Yellow
try {
    Get-SafeLinksPolicy | Format-List
} catch {
    Write-Host "Not available" -ForegroundColor Gray
}

# 18. Sample Mailboxes
Write-Host "`n[18/20] MAILBOX AUDIT SAMPLE" -ForegroundColor Yellow
Get-Mailbox -ResultSize 10 | Select DisplayName, AuditEnabled, AuditLogAgeLimit | Format-Table -AutoSize

# 19. Retention
Write-Host "`n[19/20] RETENTION POLICIES" -ForegroundColor Yellow
try {
    Get-RetentionPolicy | Format-List
} catch {
    Write-Host "Requires Compliance Center" -ForegroundColor Gray
}

# 20. Summary
Write-Host "`n[20/20] SECURITY SUMMARY" -ForegroundColor Yellow
$default = Get-HostedContentFilterPolicy -Identity Default
$phish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true}
$audit = Get-AdminAuditLogConfig
$cf = Get-HostedConnectionFilterPolicy -Identity Default

Write-Host "`n=== KEY SECURITY SETTINGS ===" -ForegroundColor Green
Write-Host "✓ Spam Action: $($default.SpamAction)"
Write-Host "✓ Bulk Threshold: $($default.BulkThreshold)"
Write-Host "✓ DMARC Action: $($phish.DmarcQuarantineAction)"
Write-Host "✓ User Notifications: $($default.EnableEndUserSpamNotifications)"
Write-Host "✓ Audit Logging: $($audit.UnifiedAuditLogIngestionEnabled)"
Write-Host "✓ IP Allow List: $($cf.IPAllowList.Count) entries"

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Yellow
$dkim = Get-DkimSigningConfig | Where-Object {$_.Domain -like "*cogitativo*"}
if ($dkim -and !$dkim.Enabled) {
    Write-Host "❗ Enable DKIM for cogitativo.com"
}
if ($cf.IPAllowList.Count -gt 0) {
    Write-Host "⚠️ Review IP Allow List ($($cf.IPAllowList.Count) entries)"
}
if (!$audit.UnifiedAuditLogIngestionEnabled) {
    Write-Host "❗ Enable Unified Audit Logging"
}

Stop-Transcript

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "COMPREHENSIVE AUDIT COMPLETE!" -ForegroundColor Green
Write-Host "Full report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "`n================================================================================`n" -ForegroundColor Cyan