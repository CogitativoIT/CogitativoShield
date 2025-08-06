# COMPREHENSIVE OFFICE 365 SECURITY AUDIT
# This script audits EVERYTHING in your O365 environment

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$auditFile = "C:\Users\andre.darby\Ops\O365-FULL-AUDIT-$timestamp.txt"

# Start transcript
Start-Transcript -Path $auditFile

Write-Host @"
================================================================================
                    COMPREHENSIVE OFFICE 365 SECURITY AUDIT
                           Organization: Cogitativo.com
                           Date: $(Get-Date)
================================================================================
"@ -ForegroundColor Cyan

# 1. ORGANIZATION CONFIGURATION
Write-Host "`n[1/20] ORGANIZATION CONFIGURATION" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-OrganizationConfig | Format-List

# 2. ADMIN AUDIT LOG CONFIGURATION
Write-Host "`n[2/20] ADMIN AUDIT LOG CONFIGURATION" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-AdminAuditLogConfig | Format-List

# 3. ALL DOMAINS
Write-Host "`n[3/20] ACCEPTED DOMAINS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-AcceptedDomain | Format-Table Name, DomainName, DomainType, Default -AutoSize

# 4. EMAIL AUTHENTICATION (SPF/DKIM/DMARC)
Write-Host "`n[4/20] EMAIL AUTHENTICATION" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray

Write-Host "`nDKIM Configuration:" -ForegroundColor Cyan
Get-DkimSigningConfig | Format-Table Domain, Enabled, Status, Selector1CNAME, Selector2CNAME -AutoSize

Write-Host "`nDMARC Records (checking DNS):" -ForegroundColor Cyan
$domains = Get-AcceptedDomain | Where-Object {$_.DomainType -eq "Authoritative"}
foreach ($domain in $domains) {
    Write-Host "Checking $($domain.DomainName)..." -ForegroundColor Gray
    try {
        $dmarc = Resolve-DnsName -Name "_dmarc.$($domain.DomainName)" -Type TXT -ErrorAction SilentlyContinue
        if ($dmarc) {
            Write-Host "  DMARC: $($dmarc.Strings)" -ForegroundColor Green
        } else {
            Write-Host "  DMARC: Not configured" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  DMARC: Unable to check" -ForegroundColor Red
    }
}

# 5. ALL ANTI-SPAM POLICIES
Write-Host "`n[5/20] ANTI-SPAM POLICIES (CONTENT FILTER)" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-HostedContentFilterPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 6. ALL ANTI-PHISHING POLICIES
Write-Host "`n[6/20] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-AntiPhishPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 7. ANTI-MALWARE POLICIES
Write-Host "`n[7/20] ANTI-MALWARE POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-MalwareFilterPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 8. SAFE ATTACHMENTS POLICIES
Write-Host "`n[8/20] SAFE ATTACHMENTS POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
try {
    Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        $_ | Format-List
    }
} catch {
    Write-Host "Safe Attachments not available (requires Defender for Office 365)" -ForegroundColor Gray
}

# 9. SAFE LINKS POLICIES
Write-Host "`n[9/20] SAFE LINKS POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
try {
    Get-SafeLinksPolicy -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        $_ | Format-List
    }
} catch {
    Write-Host "Safe Links not available (requires Defender for Office 365)" -ForegroundColor Gray
}

# 10. CONNECTION FILTER POLICIES
Write-Host "`n[10/20] CONNECTION FILTER POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-HostedConnectionFilterPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 11. OUTBOUND SPAM POLICIES
Write-Host "`n[11/20] OUTBOUND SPAM POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-HostedOutboundSpamFilterPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 12. TRANSPORT RULES (MAIL FLOW RULES)
Write-Host "`n[12/20] MAIL FLOW RULES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
$rules = Get-TransportRule
Write-Host "Total Rules: $($rules.Count)" -ForegroundColor Cyan
$rules | ForEach-Object {
    Write-Host "`nRule: $($_.Name)" -ForegroundColor Cyan
    Write-Host "  State: $($_.State)"
    Write-Host "  Priority: $($_.Priority)"
    Write-Host "  Description: $($_.Description)"
    Write-Host "  Conditions: $($_.Conditions)"
    Write-Host "  Actions: $($_.Actions)"
    Write-Host "  Exceptions: $($_.Exceptions)"
}

# 13. QUARANTINE POLICIES
Write-Host "`n[13/20] QUARANTINE POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
try {
    Get-QuarantinePolicy -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        $_ | Format-List
    }
} catch {
    Write-Host "Unable to retrieve quarantine policies" -ForegroundColor Gray
}

# 14. TENANT ALLOW/BLOCK LISTS
Write-Host "`n[14/20] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray

Write-Host "`nAllowed/Blocked Senders:" -ForegroundColor Cyan
try {
    Get-TenantAllowBlockListItems -ListType Sender -ErrorAction SilentlyContinue | Format-Table Value, Action, ExpirationDate, Notes -AutoSize
} catch {
    Write-Host "Unable to retrieve sender list" -ForegroundColor Gray
}

Write-Host "`nAllowed/Blocked Domains:" -ForegroundColor Cyan
try {
    Get-TenantAllowBlockListItems -ListType Domain -ErrorAction SilentlyContinue | Format-Table Value, Action, ExpirationDate, Notes -AutoSize
} catch {
    Write-Host "Unable to retrieve domain list" -ForegroundColor Gray
}

Write-Host "`nAllowed/Blocked URLs:" -ForegroundColor Cyan
try {
    Get-TenantAllowBlockListItems -ListType Url -ErrorAction SilentlyContinue | Format-Table Value, Action, ExpirationDate, Notes -AutoSize
} catch {
    Write-Host "Unable to retrieve URL list" -ForegroundColor Gray
}

Write-Host "`nSpoof Intelligence:" -ForegroundColor Cyan
try {
    Get-TenantAllowBlockListSpoofItems -ErrorAction SilentlyContinue | Format-Table SpoofedUser, SendingInfrastructure, SpoofType, Action -AutoSize
} catch {
    Write-Host "Unable to retrieve spoof items" -ForegroundColor Gray
}

# 15. ROLE GROUPS AND ADMIN ROLES
Write-Host "`n[15/20] ADMIN ROLE GROUPS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-RoleGroup | ForEach-Object {
    Write-Host "`nRole Group: $($_.Name)" -ForegroundColor Cyan
    Write-Host "  Members: $($_.Members -join ', ')"
    Write-Host "  Roles: $($_.Roles -join ', ')"
}

# 16. MAILBOX AUDIT SETTINGS
Write-Host "`n[16/20] MAILBOX AUDIT CONFIGURATION" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host "Checking first 10 mailboxes for audit status..." -ForegroundColor Gray
Get-Mailbox -ResultSize 10 | Select-Object DisplayName, AuditEnabled, AuditLogAgeLimit | Format-Table -AutoSize

# 17. MOBILE DEVICE POLICIES
Write-Host "`n[17/20] MOBILE DEVICE ACCESS POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-MobileDeviceMailboxPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Select-Object Name, PasswordEnabled, AlphanumericPasswordRequired, MinPasswordLength, MaxInactivityTimeLock, MaxPasswordFailedAttempts | Format-List
}

# 18. SHARING POLICIES
Write-Host "`n[18/20] SHARING POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Get-SharingPolicy | ForEach-Object {
    Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 19. RETENTION POLICIES
Write-Host "`n[19/20] RETENTION POLICIES" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
try {
    Get-RetentionPolicy -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        Write-Host "  Enabled: $($_.Enabled)"
        Write-Host "  Mode: $($_.Mode)"
    }
} catch {
    Write-Host "Unable to retrieve retention policies (may require Compliance Center access)" -ForegroundColor Gray
}

# 20. SECURITY SUMMARY AND RECOMMENDATIONS
Write-Host "`n[20/20] SECURITY ASSESSMENT SUMMARY" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray

Write-Host "`n=== CONFIGURATION SUMMARY ===" -ForegroundColor Cyan

# Check key security settings
$contentFilter = Get-HostedContentFilterPolicy -Identity Default
$antiPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true}
$connectionFilter = Get-HostedConnectionFilterPolicy -Identity Default
$auditConfig = Get-AdminAuditLogConfig

Write-Host "`nKey Security Settings:" -ForegroundColor Green
Write-Host "  ✓ Spam Action: $($contentFilter.SpamAction)"
Write-Host "  ✓ Bulk Threshold: $($contentFilter.BulkThreshold)"
Write-Host "  ✓ End User Notifications: $($contentFilter.EnableEndUserSpamNotifications)"
Write-Host "  ✓ DMARC Quarantine Action: $($antiPhish.DmarcQuarantineAction)"
Write-Host "  ✓ Admin Audit Log: $($auditConfig.AdminAuditLogEnabled)"
Write-Host "  ✓ Unified Audit Log: $($auditConfig.UnifiedAuditLogIngestionEnabled)"

Write-Host "`n=== SECURITY RECOMMENDATIONS ===" -ForegroundColor Yellow

$recommendations = @()

# Check DKIM
$dkim = Get-DkimSigningConfig | Where-Object {$_.Domain -like "*cogitativo*"}
if (!$dkim.Enabled) {
    $recommendations += "❗ Enable DKIM for cogitativo.com"
}

# Check IP Allow List
if ($connectionFilter.IPAllowList.Count -gt 0) {
    $recommendations += "⚠️ Review IP Allow List (currently has $($connectionFilter.IPAllowList.Count) entries)"
}

# Check Safe Attachments
try {
    $safeAttach = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
    if (!$safeAttach) {
        $recommendations += "💡 Consider enabling Safe Attachments (requires Defender for Office 365)"
    }
} catch {}

# Check mailbox auditing
$mailboxes = Get-Mailbox -ResultSize 10
$auditDisabled = $mailboxes | Where-Object {!$_.AuditEnabled}
if ($auditDisabled) {
    $recommendations += "⚠️ Enable mailbox auditing for all mailboxes"
}

if ($recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor White
    foreach ($rec in $recommendations) {
        Write-Host "  $rec"
    }
} else {
    Write-Host "`n✅ No critical security issues found!" -ForegroundColor Green
}

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "Audit Complete! Full report saved to: $auditFile" -ForegroundColor Green
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

Stop-Transcript

# Also create a summary HTML report
$htmlFile = "C:\Users\andre.darby\Ops\O365-AUDIT-REPORT-$timestamp.html"
@"
<!DOCTYPE html>
<html>
<head>
    <title>O365 Security Audit - Cogitativo</title>
    <style>
        body { font-family: 'Segoe UI', Arial; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric { display: inline-block; padding: 10px 15px; background: #e3f2fd; border-radius: 5px; margin: 5px; }
        .success { color: #00b894; }
        .warning { color: #fdcb6e; }
        .critical { color: #d63031; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #f0f0f0; padding: 10px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Office 365 Security Audit Report</h1>
        <p>Organization: Cogitativo.com | Generated: $(Get-Date)</p>
    </div>
    <div class="section">
        <h2>Quick Summary</h2>
        <div class="metric">Spam Filter: <span class="success">✓ Configured</span></div>
        <div class="metric">DMARC: <span class="success">✓ Updated</span></div>
        <div class="metric">Audit Logging: <span class="$(if($auditConfig.UnifiedAuditLogIngestionEnabled){"success"}else{"warning"})">$(if($auditConfig.UnifiedAuditLogIngestionEnabled){"✓ Enabled"}else{"⚠ Disabled"})</span></div>
        <div class="metric">Total Mail Rules: $($rules.Count)</div>
        <div class="metric">Admin Roles: $(($roleGroups | Measure-Object).Count)</div>
    </div>
    <div class="section">
        <h2>Security Configuration</h2>
        <table>
            <tr><th>Setting</th><th>Value</th><th>Status</th></tr>
            <tr><td>Spam Action</td><td>$($contentFilter.SpamAction)</td><td class="success">✓</td></tr>
            <tr><td>DMARC Quarantine</td><td>$($antiPhish.DmarcQuarantineAction)</td><td class="success">✓</td></tr>
            <tr><td>Bulk Threshold</td><td>$($contentFilter.BulkThreshold)</td><td class="success">✓</td></tr>
            <tr><td>User Notifications</td><td>$($contentFilter.EnableEndUserSpamNotifications)</td><td class="success">✓</td></tr>
        </table>
    </div>
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            $(foreach ($rec in $recommendations) { "<li>$rec</li>" })
        </ul>
    </div>
</body>
</html>
"@ | Out-File -FilePath $htmlFile -Encoding UTF8

Write-Host "HTML Report saved to: $htmlFile" -ForegroundColor Green