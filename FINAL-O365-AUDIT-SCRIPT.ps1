# FINAL O365 AUDIT SCRIPT - RUNS WITHOUT POPUPS AFTER SETUP
# Run this after completing Azure AD app registration

# Configuration
$CertThumbprint = "AB551929F68F2607C5F89752A6CC827DD028C3B5"
$Organization = "cogitativo.onmicrosoft.com"

# Check if App ID is configured
$configFile = "C:\Users\andre.darby\Ops\o365-config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    $AppId = $config.AppId
    if ($AppId -eq "PASTE-YOUR-APP-ID-HERE") {
        Write-Host "ERROR: Please update o365-config.json with your App ID from Azure Portal!" -ForegroundColor Red
        Write-Host "Instructions:" -ForegroundColor Yellow
        Write-Host "1. Go to https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade"
        Write-Host "2. Find 'O365-Automation-Cogitativo' app"
        Write-Host "3. Copy the Application (client) ID"
        Write-Host "4. Update o365-config.json with the App ID"
        exit 1
    }
} else {
    Write-Host "ERROR: Configuration file not found!" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "C:\Users\andre.darby\Ops\O365-COMPLETE-AUDIT-$timestamp.txt"

Write-Host @"
================================================================================
              O365 COMPREHENSIVE SECURITY AUDIT (AUTOMATED)
                        Organization: $Organization
                        Date: $(Get-Date)
================================================================================
"@ -ForegroundColor Cyan

# Connect using certificate (NO POPUP!)
Write-Host "Connecting to Exchange Online (Certificate Auth)..." -ForegroundColor Yellow
try {
    Connect-ExchangeOnline `
        -AppId $AppId `
        -CertificateThumbprint $CertThumbprint `
        -Organization $Organization `
        -ShowBanner:$false `
        -ErrorAction Stop
    
    Write-Host "✅ Connected successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to connect. Check your App ID and permissions." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Start full audit
Start-Transcript -Path $reportFile

Write-Host "`n=== STARTING COMPREHENSIVE AUDIT ===" -ForegroundColor Cyan

# 1. Organization Info
Write-Host "`n[1/20] ORGANIZATION CONFIGURATION" -ForegroundColor Yellow
Get-OrganizationConfig | Format-List

# 2. Domains
Write-Host "`n[2/20] ACCEPTED DOMAINS" -ForegroundColor Yellow
Get-AcceptedDomain | Format-Table -AutoSize

# 3. DKIM
Write-Host "`n[3/20] DKIM CONFIGURATION" -ForegroundColor Yellow
Get-DkimSigningConfig | Format-Table -AutoSize

# 4. Anti-Spam
Write-Host "`n[4/20] ANTI-SPAM POLICIES" -ForegroundColor Yellow
Get-HostedContentFilterPolicy | ForEach-Object {
    Write-Host "Policy: $($_.Name)" -ForegroundColor Cyan
    $_ | Format-List
}

# 5. Anti-Phishing
Write-Host "`n[5/20] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
Get-AntiPhishPolicy | ForEach-Object {
    Write-Host "Policy: $($_.Name)" -ForegroundColor Cyan
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
Get-RoleGroup | Format-List

# 12. Tenant Allow/Block
Write-Host "`n[12/20] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
try {
    Get-TenantAllowBlockListSpoofItems | Format-Table -AutoSize
} catch {
    Write-Host "Unable to retrieve" -ForegroundColor Gray
}

# 13. Mobile Device Policies
Write-Host "`n[13/20] MOBILE DEVICE POLICIES" -ForegroundColor Yellow
Get-MobileDeviceMailboxPolicy | Format-List

# 14. Sharing Policies  
Write-Host "`n[14/20] SHARING POLICIES" -ForegroundColor Yellow
Get-SharingPolicy | Format-List

# 15. Quarantine Policies
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
    Write-Host "Not available (requires Defender)" -ForegroundColor Gray
}

# 17. Safe Links
Write-Host "`n[17/20] SAFE LINKS" -ForegroundColor Yellow
try {
    Get-SafeLinksPolicy | Format-List
} catch {
    Write-Host "Not available (requires Defender)" -ForegroundColor Gray
}

# 18. Mailbox Audit
Write-Host "`n[18/20] MAILBOX AUDIT SAMPLE" -ForegroundColor Yellow
Get-Mailbox -ResultSize 10 | Select DisplayName, AuditEnabled | Format-Table -AutoSize

# 19. Retention Policies
Write-Host "`n[19/20] RETENTION POLICIES" -ForegroundColor Yellow
try {
    Get-RetentionPolicy | Format-List
} catch {
    Write-Host "Requires Compliance Center access" -ForegroundColor Gray
}

# 20. Summary
Write-Host "`n[20/20] SECURITY SUMMARY" -ForegroundColor Yellow
$default = Get-HostedContentFilterPolicy -Identity Default
$phish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true}
$audit = Get-AdminAuditLogConfig

Write-Host "`n=== KEY SECURITY SETTINGS ===" -ForegroundColor Green
Write-Host "Spam Action: $($default.SpamAction)"
Write-Host "Bulk Threshold: $($default.BulkThreshold)"
Write-Host "DMARC Action: $($phish.DmarcQuarantineAction)"
Write-Host "User Notifications: $($default.EnableEndUserSpamNotifications)"
Write-Host "Audit Logging: $($audit.UnifiedAuditLogIngestionEnabled)"

Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Green

Stop-Transcript

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "FULL AUDIT COMPLETE!" -ForegroundColor Green
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "`n================================================================================`n" -ForegroundColor Cyan