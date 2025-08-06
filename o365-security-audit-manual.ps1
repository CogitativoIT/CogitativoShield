# Office 365 Email Security Audit - Manual Connection Version
Write-Host "=== Office 365 Email Security Audit ===" -ForegroundColor Cyan
Write-Host "This script assumes you're already connected to Exchange Online" -ForegroundColor Yellow
Write-Host "If not connected, run: Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor Yellow
Write-Host ""

# Test connection
try {
    $test = Get-OrganizationConfig -ErrorAction Stop | Out-Null
    Write-Host "✅ Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected. Please run: Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor Red
    exit
}

Write-Host "`n=== CONNECTION FILTER POLICY ===" -ForegroundColor Cyan
$cf = Get-HostedConnectionFilterPolicy -Identity Default
Write-Host "IPAllowList:`t" ($cf.IPAllowList -join ', ') 
Write-Host "IPBlockList:`t" ($cf.IPBlockList.Count) "entries"
Write-Host "EnableSafeList:`t" $cf.EnableSafeList

Write-Host "`n=== ANTI-SPAM POLICIES ===" -ForegroundColor Cyan
$filter = Get-HostedContentFilterPolicy
foreach ($policy in $filter) {
    Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor White
    Write-Host "  Spam Action: $($policy.SpamAction)"
    Write-Host "  High Confidence Spam: $($policy.HighConfidenceSpamAction)"
    Write-Host "  Phishing Action: $($policy.PhishSpamAction)"
    Write-Host "  Bulk Threshold: $($policy.BulkThreshold)"
    Write-Host "  Allowed Sender Domains: $($policy.AllowedSenderDomains.Count) domains"
    Write-Host "  Allowed Senders: $($policy.AllowedSenders.Count) senders"
    Write-Host "  Blocked Sender Domains: $($policy.BlockedSenderDomains.Count) domains"
    Write-Host "  Blocked Senders: $($policy.BlockedSenders.Count) senders"
}

Write-Host "`n=== ANTI-PHISHING POLICIES ===" -ForegroundColor Cyan
$phish = Get-AntiPhishPolicy
foreach ($policy in $phish) {
    Write-Host "`nPolicy: $($policy.Name)" -ForegroundColor White
    Write-Host "  Enabled: $($policy.Enabled)"
    Write-Host "  DMARC Action: $($policy.DmarcPolicyAction)"
    Write-Host "  Impersonation Protection: $($policy.EnableTargetedUserProtection)"
    Write-Host "  Domain Protection: $($policy.EnableTargetedDomainsProtection)"
    Write-Host "  Mailbox Intelligence: $($policy.EnableMailboxIntelligence)"
    Write-Host "  Spoof Intelligence: $($policy.EnableSpoofIntelligence)"
}

Write-Host "`n=== SAFE ATTACHMENTS ===" -ForegroundColor Cyan
try {
    $safeAttach = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
    if ($safeAttach) {
        foreach ($policy in $safeAttach) {
            Write-Host "Policy: $($policy.Name)" -ForegroundColor White
            Write-Host "  Action: $($policy.Action)"
            Write-Host "  Redirect: $($policy.Redirect)"
        }
    } else {
        Write-Host "⚠️ No Safe Attachment policies configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Safe Attachments not available in your subscription" -ForegroundColor Yellow
}

Write-Host "`n=== SAFE LINKS ===" -ForegroundColor Cyan
try {
    $safeLinks = Get-SafeLinksPolicy -ErrorAction SilentlyContinue
    if ($safeLinks) {
        foreach ($policy in $safeLinks) {
            Write-Host "Policy: $($policy.Name)" -ForegroundColor White
            Write-Host "  Scan URLs: $($policy.ScanUrls)"
            Write-Host "  Track Clicks: $($policy.TrackClicks)"
        }
    } else {
        Write-Host "⚠️ No Safe Links policies configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Safe Links not available in your subscription" -ForegroundColor Yellow
}

Write-Host "`n=== TENANT ALLOW/BLOCK LIST ===" -ForegroundColor Cyan
Write-Host "`nSpoofed Senders (Allowed):" -ForegroundColor White
try {
    $spoof = Get-TenantAllowBlockListSpoofItems -Action Allow -ErrorAction SilentlyContinue
    if ($spoof) {
        $spoof | Format-Table SpoofedUser,SendingInfrastructure,SpoofType -AutoSize
    } else {
        Write-Host "  None configured"
    }
} catch {
    Write-Host "  Unable to retrieve spoof items"
}

Write-Host "`nAllowed Senders/Domains:" -ForegroundColor White
try {
    $allowed = Get-TenantAllowBlockListItems -ListType Sender -Allow -ErrorAction SilentlyContinue
    if ($allowed) {
        $allowed | Format-Table Identity,Entries,ExpirationDate -AutoSize
    } else {
        Write-Host "  None configured"
    }
} catch {
    Write-Host "  Unable to retrieve allow list items"
}

Write-Host "`n=== DKIM CONFIGURATION ===" -ForegroundColor Cyan
$dkim = Get-DkimSigningConfig
foreach ($domain in $dkim) {
    Write-Host "Domain: $($domain.Domain)" -ForegroundColor White
    Write-Host "  Enabled: $($domain.Enabled)"
    Write-Host "  Status: $($domain.Status)"
    if (!$domain.Enabled) {
        Write-Host "  ⚠️ DKIM not enabled for this domain" -ForegroundColor Yellow
    }
}

Write-Host "`n=== SPF RECORDS ===" -ForegroundColor Cyan
Write-Host "Checking cogitativo.com..." -ForegroundColor White
try {
    $spf = Resolve-DnsName -Name cogitativo.com -Type TXT -ErrorAction SilentlyContinue | Where-Object {$_.Strings -like "*spf*"}
    if ($spf) {
        Write-Host "  ✅ SPF Record found: $($spf.Strings)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No SPF record found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Unable to check SPF record"
}

Write-Host "`n=== MAIL FLOW RULES ===" -ForegroundColor Cyan
$rules = Get-TransportRule
Write-Host "Total Rules: $($rules.Count)" -ForegroundColor White
if ($rules.Count -gt 0) {
    Write-Host "`nTop 10 Rules:" -ForegroundColor White
    $rules | Select-Object -First 10 | Format-Table Name,State,Priority -AutoSize
}

Write-Host "`n=== AUDIT LOGGING ===" -ForegroundColor Cyan
$auditConfig = Get-AdminAuditLogConfig
Write-Host "Admin Audit Log: $($auditConfig.AdminAuditLogEnabled)"
Write-Host "Unified Audit Log: $($auditConfig.UnifiedAuditLogIngestionEnabled)"

Write-Host "`n=== MAILBOX AUDITING SAMPLE ===" -ForegroundColor Cyan
$mailboxes = Get-Mailbox -ResultSize 10
Write-Host "Checking first 10 mailboxes:" -ForegroundColor White
$auditEnabled = 0
foreach ($mb in $mailboxes) {
    if ($mb.AuditEnabled) { $auditEnabled++ }
}
Write-Host "  Audit Enabled: $auditEnabled out of $($mailboxes.Count) mailboxes"

Write-Host "`n=== SECURITY RECOMMENDATIONS ===" -ForegroundColor Cyan

$recommendations = @()

# Check Connection Filter
if ($cf.IPAllowList.Count -gt 0) {
    $recommendations += "❗ Remove IP Allow List entries (currently $($cf.IPAllowList.Count) entries) - these bypass spam filtering"
}
if ($cf.EnableSafeList) {
    $recommendations += "❗ Disable SafeList to prevent bypassing filters"
}

# Check Anti-Spam
$weakSpam = $filter | Where-Object {$_.BulkThreshold -gt 7}
if ($weakSpam) {
    $recommendations += "⚠️ Lower Bulk Email threshold to 6 or below (currently >7 in some policies)"
}

$allowedDomains = ($filter | Measure-Object -Property AllowedSenderDomains -Sum).Sum
if ($allowedDomains -gt 10) {
    $recommendations += "⚠️ Review allowed sender domains (currently $allowedDomains total) - minimize to reduce spoofing risk"
}

# Check Anti-Phishing
$weakPhish = $phish | Where-Object {!$_.EnableTargetedUserProtection -or !$_.EnableTargetedDomainsProtection}
if ($weakPhish) {
    $recommendations += "⚠️ Enable impersonation protection in anti-phishing policies"
}

# Check DKIM
$dkimDisabled = $dkim | Where-Object {!$_.Enabled}
if ($dkimDisabled) {
    $recommendations += "❗ Enable DKIM for domains: $($dkimDisabled.Domain -join ', ')"
}

# Check Safe Attachments/Links
if (!$safeAttach) {
    $recommendations += "⚠️ Consider enabling Safe Attachments for enhanced malware protection (requires Defender for Office 365)"
}
if (!$safeLinks) {
    $recommendations += "⚠️ Consider enabling Safe Links for URL protection (requires Defender for Office 365)"
}

# Check Audit
if (!$auditConfig.UnifiedAuditLogIngestionEnabled) {
    $recommendations += "❗ Enable Unified Audit Logging for better security visibility"
}

# Display recommendations
if ($recommendations.Count -gt 0) {
    Write-Host "`nKey Recommendations:" -ForegroundColor Yellow
    foreach ($rec in $recommendations) {
        Write-Host "  $rec" -ForegroundColor White
    }
} else {
    Write-Host "✅ Email security configuration looks good!" -ForegroundColor Green
}

Write-Host "`n=== ADDITIONAL CHECKS TO CONSIDER ===" -ForegroundColor Cyan
Write-Host "1. Review MFA status: Get-MsolUser -All | Where-Object {$_.StrongAuthenticationMethods.Count -eq 0}"
Write-Host "2. Check conditional access policies in Azure AD portal"
Write-Host "3. Review admin roles and privileged accounts"
Write-Host "4. Check for forwarding rules: Get-Mailbox -ResultSize Unlimited | Where {$_.ForwardingAddress -ne `$null}"
Write-Host "5. Review OAuth app permissions in Azure AD"

Write-Host "`n=== Audit Complete ===" -ForegroundColor Green