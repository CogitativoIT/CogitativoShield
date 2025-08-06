# O365 COMPREHENSIVE AUDIT - SECTION BY SECTION
Write-Host "`n=== STARTING COMPREHENSIVE O365 AUDIT ===" -ForegroundColor Cyan

# SECTION 1: Basic Organization Info
Write-Host "`n[SECTION 1] ORGANIZATION & DOMAINS" -ForegroundColor Yellow
Get-OrganizationConfig | Select Name, DisplayName, IsDehydrated, MailTipsAllTipsEnabled | Format-List
Get-AcceptedDomain | Format-Table Name, DomainName, DomainType, Default -AutoSize

# SECTION 2: Email Authentication
Write-Host "`n[SECTION 2] EMAIL AUTHENTICATION (SPF/DKIM/DMARC)" -ForegroundColor Yellow
Get-DkimSigningConfig | Format-Table Domain, Enabled, Status -AutoSize

# SECTION 3: Anti-Spam Configuration
Write-Host "`n[SECTION 3] ANTI-SPAM POLICIES" -ForegroundColor Yellow
Get-HostedContentFilterPolicy | Format-Table Name, SpamAction, BulkThreshold, EnableEndUserSpamNotifications -AutoSize

# SECTION 4: Anti-Phishing Configuration
Write-Host "`n[SECTION 4] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
Get-AntiPhishPolicy | Format-Table Name, IsDefault, DmarcQuarantineAction, EnableTargetedUserProtection -AutoSize

# SECTION 5: Connection Filters
Write-Host "`n[SECTION 5] CONNECTION FILTERS" -ForegroundColor Yellow
$cf = Get-HostedConnectionFilterPolicy -Identity Default
Write-Host "IP Allow List Count: $($cf.IPAllowList.Count)"
Write-Host "IP Block List Count: $($cf.IPBlockList.Count)"
Write-Host "Safe List Enabled: $($cf.EnableSafeList)"

# SECTION 6: Mail Flow Rules
Write-Host "`n[SECTION 6] MAIL FLOW RULES" -ForegroundColor Yellow
$rules = Get-TransportRule
Write-Host "Total Mail Flow Rules: $($rules.Count)"
if ($rules.Count -gt 0) {
    $rules | Select-Object -First 10 | Format-Table Name, State, Priority -AutoSize
}

# SECTION 7: Admin Roles
Write-Host "`n[SECTION 7] ADMIN ROLES" -ForegroundColor Yellow
Get-RoleGroup | Where-Object {$_.Members.Count -gt 0} | ForEach-Object {
    Write-Host "$($_.Name): $($_.Members -join ', ')"
}

# SECTION 8: Audit Configuration
Write-Host "`n[SECTION 8] AUDIT CONFIGURATION" -ForegroundColor Yellow
$audit = Get-AdminAuditLogConfig
Write-Host "Admin Audit Log: $($audit.AdminAuditLogEnabled)"
Write-Host "Unified Audit Log: $($audit.UnifiedAuditLogIngestionEnabled)"

# SECTION 9: Tenant Allow/Block Lists
Write-Host "`n[SECTION 9] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
try {
    $spoofItems = Get-TenantAllowBlockListSpoofItems -ErrorAction SilentlyContinue
    Write-Host "Spoof Allow Items: $(($spoofItems | Where-Object {$_.Action -eq 'Allow'}).Count)"
} catch {
    Write-Host "Unable to retrieve spoof items"
}

# SECTION 10: Mobile Device Policies
Write-Host "`n[SECTION 10] MOBILE DEVICE POLICIES" -ForegroundColor Yellow
Get-MobileDeviceMailboxPolicy | Select Name, PasswordEnabled, MinPasswordLength | Format-Table -AutoSize

Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Green