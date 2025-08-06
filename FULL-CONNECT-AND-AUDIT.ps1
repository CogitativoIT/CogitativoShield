# CONNECT TO EXCHANGE ONLINE AND RUN FULL AUDIT
Write-Host "=== CONNECTING TO EXCHANGE ONLINE ===" -ForegroundColor Cyan

# Import the module
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Connect
Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "Connected! Starting audit..." -ForegroundColor Green

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "C:\Users\andre.darby\Ops\O365-FULL-AUDIT-$timestamp.txt"

Start-Transcript -Path $reportFile

Write-Host @"

================================================================================
              COMPREHENSIVE O365 SECURITY AUDIT
                        Organization: Cogitativo.com
                        Date: $(Get-Date)
================================================================================
"@ -ForegroundColor Cyan

# Quick audit to verify connection
Write-Host "`n[TESTING CONNECTION]" -ForegroundColor Yellow
Get-OrganizationConfig | Select Name, DisplayName | Format-List

Write-Host "`n[1/20] ACCEPTED DOMAINS" -ForegroundColor Yellow
Get-AcceptedDomain | Format-Table Name, DomainName, DomainType, Default -AutoSize

Write-Host "`n[2/20] DKIM CONFIGURATION" -ForegroundColor Yellow
Get-DkimSigningConfig | Format-Table Domain, Enabled, Status -AutoSize

Write-Host "`n[3/20] ANTI-SPAM POLICIES" -ForegroundColor Yellow
Get-HostedContentFilterPolicy | Select Name, SpamAction, BulkSpamAction, BulkThreshold, EnableEndUserSpamNotifications | Format-Table -AutoSize

Write-Host "`n[4/20] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
Get-AntiPhishPolicy | Select Name, IsDefault, DmarcQuarantineAction, DmarcRejectAction | Format-Table -AutoSize

Write-Host "`n[5/20] CONNECTION FILTERS" -ForegroundColor Yellow
$cf = Get-HostedConnectionFilterPolicy -Identity Default
Write-Host "IP Allow List: $($cf.IPAllowList.Count) entries"
Write-Host "IP Block List: $($cf.IPBlockList.Count) entries"
Write-Host "Enable Safe List: $($cf.EnableSafeList)"

Write-Host "`n[6/20] MAIL FLOW RULES" -ForegroundColor Yellow
$rules = Get-TransportRule
Write-Host "Total Mail Flow Rules: $($rules.Count)"
if ($rules.Count -gt 0) {
    $rules | Select Name, State, Priority | Format-Table -AutoSize
}

Write-Host "`n[7/20] OUTBOUND SPAM FILTER" -ForegroundColor Yellow
Get-HostedOutboundSpamFilterPolicy | Select Name, RecipientLimitPerDay, AutoForwardingMode | Format-Table -AutoSize

Write-Host "`n[8/20] MALWARE FILTER" -ForegroundColor Yellow
Get-MalwareFilterPolicy | Select Name, Action, EnableFileFilter, ZapEnabled | Format-Table -AutoSize

Write-Host "`n[9/20] ADMIN AUDIT CONFIG" -ForegroundColor Yellow
Get-AdminAuditLogConfig | Select AdminAuditLogEnabled, UnifiedAuditLogIngestionEnabled | Format-List

Write-Host "`n[10/20] ADMIN ROLES" -ForegroundColor Yellow
Get-RoleGroup | Where-Object {$_.Members.Count -gt 0} | Select Name, Members | Format-Table -AutoSize

Write-Host "`n[11/20] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
try {
    $spoofItems = Get-TenantAllowBlockListSpoofItems -ErrorAction SilentlyContinue
    Write-Host "Spoof Allow Items: $(($spoofItems | Where-Object {$_.Action -eq 'Allow'}).Count)"
} catch {
    Write-Host "Unable to retrieve spoof items"
}

Write-Host "`n[12/20] MOBILE DEVICE POLICIES" -ForegroundColor Yellow
Get-MobileDeviceMailboxPolicy | Select Name, PasswordEnabled, MinPasswordLength | Format-Table -AutoSize

Write-Host "`n[13/20] SHARING POLICIES" -ForegroundColor Yellow
Get-SharingPolicy | Select Name, Enabled, Default | Format-Table -AutoSize

Write-Host "`n[14/20] QUARANTINE POLICIES" -ForegroundColor Yellow
try {
    Get-QuarantinePolicy -ErrorAction SilentlyContinue | Select Name | Format-Table -AutoSize
} catch {
    Write-Host "Not accessible"
}

Write-Host "`n[15/20] SAFE ATTACHMENTS" -ForegroundColor Yellow
try {
    Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue | Select Name, Action, Enable | Format-Table -AutoSize
} catch {
    Write-Host "Not available (requires Defender)"
}

Write-Host "`n[16/20] SAFE LINKS" -ForegroundColor Yellow
try {
    Get-SafeLinksPolicy -ErrorAction SilentlyContinue | Select Name, IsEnabled, ScanUrls | Format-Table -AutoSize
} catch {
    Write-Host "Not available (requires Defender)"
}

Write-Host "`n[17/20] MAILBOX AUDIT SAMPLE" -ForegroundColor Yellow
Get-Mailbox -ResultSize 10 | Select DisplayName, AuditEnabled | Format-Table -AutoSize

Write-Host "`n[18/20] ALL POLICIES SUMMARY" -ForegroundColor Yellow
Write-Host "Content Filter Policies: $((Get-HostedContentFilterPolicy).Count)"
Write-Host "Anti-Phish Policies: $((Get-AntiPhishPolicy).Count)"
Write-Host "Malware Filter Policies: $((Get-MalwareFilterPolicy).Count)"
Write-Host "Transport Rules: $((Get-TransportRule).Count)"

Write-Host "`n[19/20] ALLOWED LISTS DETAIL" -ForegroundColor Yellow
$default = Get-HostedContentFilterPolicy -Identity Default
Write-Host "Allowed Sender Domains: $($default.AllowedSenderDomains.Count)"
if ($default.AllowedSenderDomains.Count -gt 0 -and $default.AllowedSenderDomains.Count -le 10) {
    $default.AllowedSenderDomains | ForEach-Object { Write-Host "  - $_" }
}
Write-Host "Allowed Senders: $($default.AllowedSenders.Count)"
if ($default.AllowedSenders.Count -gt 0 -and $default.AllowedSenders.Count -le 10) {
    $default.AllowedSenders | ForEach-Object { Write-Host "  - $_" }
}

Write-Host "`n[20/20] FINAL SECURITY SUMMARY" -ForegroundColor Yellow
$defaultPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true}
$audit = Get-AdminAuditLogConfig

Write-Host "`n=== CURRENT SECURITY POSTURE ===" -ForegroundColor Green
Write-Host "✓ Spam Action: $($default.SpamAction)"
Write-Host "✓ Bulk Threshold: $($default.BulkThreshold)"
Write-Host "✓ DMARC Quarantine: $($defaultPhish.DmarcQuarantineAction)"
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
Write-Host "AUDIT COMPLETE!" -ForegroundColor Green
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false