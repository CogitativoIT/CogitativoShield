# Office 365 Email Security Audit Script
Write-Host "=== Office 365 Email Security Audit ===" -ForegroundColor Cyan
Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow

# Install required module if not present
if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing Exchange Online Management module..." -ForegroundColor Yellow
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
}

# Import the module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
try {
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false
    Write-Host "Connected successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to connect. Please login when prompted." -ForegroundColor Red
    Connect-ExchangeOnline
}

Write-Host "`n=== Email Security Configuration ===" -ForegroundColor Cyan

# 1. Check Anti-Spam Policies
Write-Host "`n1. ANTI-SPAM POLICIES:" -ForegroundColor Yellow
$spamPolicies = Get-HostedContentFilterPolicy
foreach ($policy in $spamPolicies) {
    Write-Host "  Policy: $($policy.Name)" -ForegroundColor White
    Write-Host "    - Spam Action: $($policy.SpamAction)"
    Write-Host "    - High Confidence Spam: $($policy.HighConfidenceSpamAction)"
    Write-Host "    - Phishing Action: $($policy.PhishSpamAction)"
    Write-Host "    - Bulk Threshold: $($policy.BulkThreshold)"
    Write-Host "    - Quarantine Retention: $($policy.QuarantineRetentionPeriod) days"
}

# 2. Check Anti-Phishing Policies
Write-Host "`n2. ANTI-PHISHING POLICIES:" -ForegroundColor Yellow
$phishPolicies = Get-AntiPhishPolicy
foreach ($policy in $phishPolicies) {
    Write-Host "  Policy: $($policy.Name)" -ForegroundColor White
    Write-Host "    - Enabled: $($policy.Enabled)"
    Write-Host "    - Impersonation Protection: $($policy.EnableTargetedUserProtection)"
    Write-Host "    - Domain Protection: $($policy.EnableTargetedDomainsProtection)"
    Write-Host "    - Mailbox Intelligence: $($policy.EnableMailboxIntelligence)"
}

# 3. Check Safe Attachments
Write-Host "`n3. SAFE ATTACHMENTS:" -ForegroundColor Yellow
$safeAttach = Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue
if ($safeAttach) {
    foreach ($policy in $safeAttach) {
        Write-Host "  Policy: $($policy.Name)" -ForegroundColor White
        Write-Host "    - Action: $($policy.Action)"
        Write-Host "    - Redirect: $($policy.Redirect)"
    }
} else {
    Write-Host "  ⚠️ No Safe Attachment policies found" -ForegroundColor Red
}

# 4. Check Safe Links
Write-Host "`n4. SAFE LINKS:" -ForegroundColor Yellow
$safeLinks = Get-SafeLinksPolicy -ErrorAction SilentlyContinue
if ($safeLinks) {
    foreach ($policy in $safeLinks) {
        Write-Host "  Policy: $($policy.Name)" -ForegroundColor White
        Write-Host "    - Scan URLs: $($policy.ScanUrls)"
        Write-Host "    - Track Clicks: $($policy.TrackClicks)"
    }
} else {
    Write-Host "  ⚠️ No Safe Links policies found" -ForegroundColor Red
}

# 5. Check DKIM
Write-Host "`n5. DKIM CONFIGURATION:" -ForegroundColor Yellow
$dkim = Get-DkimSigningConfig
foreach ($domain in $dkim) {
    Write-Host "  Domain: $($domain.Domain)" -ForegroundColor White
    Write-Host "    - Enabled: $($domain.Enabled)"
    Write-Host "    - Status: $($domain.Status)"
}

# 6. Check SPF Records
Write-Host "`n6. SPF RECORDS:" -ForegroundColor Yellow
Write-Host "  Checking cogitativo.com..." -ForegroundColor White
$spf = Resolve-DnsName -Name cogitativo.com -Type TXT | Where-Object {$_.Strings -like "*spf*"}
if ($spf) {
    Write-Host "    - SPF Record: $($spf.Strings)" -ForegroundColor Green
} else {
    Write-Host "    - ⚠️ No SPF record found" -ForegroundColor Red
}

# 7. Check Mail Flow Rules
Write-Host "`n7. MAIL FLOW RULES:" -ForegroundColor Yellow
$rules = Get-TransportRule | Select-Object Name, State, Priority
Write-Host "  Total Rules: $($rules.Count)" -ForegroundColor White
foreach ($rule in $rules | Select-Object -First 5) {
    Write-Host "    - $($rule.Name) (State: $($rule.State), Priority: $($rule.Priority))"
}

# 8. Check Admin Audit Logging
Write-Host "`n8. AUDIT LOGGING:" -ForegroundColor Yellow
$auditConfig = Get-AdminAuditLogConfig
Write-Host "  Admin Audit Log: $($auditConfig.AdminAuditLogEnabled)" -ForegroundColor White
Write-Host "  Unified Audit Log: $($auditConfig.UnifiedAuditLogIngestionEnabled)" -ForegroundColor White

# 9. Check Mailbox Audit
Write-Host "`n9. MAILBOX AUDITING:" -ForegroundColor Yellow
$mailboxes = Get-Mailbox -ResultSize 5
foreach ($mb in $mailboxes) {
    Write-Host "  $($mb.UserPrincipalName): Audit Enabled = $($mb.AuditEnabled)" -ForegroundColor White
}

# 10. Generate Recommendations
Write-Host "`n=== SECURITY RECOMMENDATIONS ===" -ForegroundColor Cyan

$recommendations = @()

# Check for missing policies
if (!$safeAttach) { $recommendations += "❗ Enable Safe Attachments for enhanced malware protection" }
if (!$safeLinks) { $recommendations += "❗ Enable Safe Links for URL protection" }

# Check DKIM
$dkimDisabled = $dkim | Where-Object {$_.Enabled -eq $false}
if ($dkimDisabled) { $recommendations += "⚠️ Enable DKIM for domains: $($dkimDisabled.Domain -join ', ')" }

# Check spam settings
$weakSpam = $spamPolicies | Where-Object {$_.BulkThreshold -gt 7}
if ($weakSpam) { $recommendations += "⚠️ Lower Bulk Email threshold (currently >7)" }

# Display recommendations
if ($recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    foreach ($rec in $recommendations) {
        Write-Host "  $rec" -ForegroundColor White
    }
} else {
    Write-Host "✅ Email security configuration looks good!" -ForegroundColor Green
}

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "`n=== Audit Complete ===" -ForegroundColor Green