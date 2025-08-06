# Quick Office 365 Security Check
# Based on user's previous successful commands

Write-Host "`n=== QUICK O365 SECURITY CHECK ===" -ForegroundColor Cyan
Write-Host "Run this after connecting with: Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor Yellow

# 1. Connection Filter Policy Checks
$cf = Get-HostedConnectionFilterPolicy -Identity Default
Write-Host "`n--- Connection Filter Policy ---" -ForegroundColor Yellow
Write-Host "IPAllowList: " ($cf.IPAllowList -join ', ') 
Write-Host "EnableSafeList: " $cf.EnableSafeList

# 2. Anti-Spam Policy
$filter = Get-HostedContentFilterPolicy -Identity Default
Write-Host "`n--- Content Filter Policy ---" -ForegroundColor Yellow
Write-Host "Allowed Sender Domains:" ($filter.AllowedSenderDomains -join ', ')
Write-Host "Allowed Senders:" ($filter.AllowedSenders -join ', ')
Write-Host "Spam Action:" $filter.SpamAction
Write-Host "High Confidence Spam Action:" $filter.HighConfidenceSpamAction
Write-Host "Phishing Action:" $filter.PhishSpamAction
Write-Host "Bulk Threshold:" $filter.BulkThreshold

# 3. Tenant Allow/Block List
Write-Host "`n--- Spoofed Sender Entries ---" -ForegroundColor Yellow
$spoofItems = Get-TenantAllowBlockListSpoofItems -Action Allow -ErrorAction SilentlyContinue
if ($spoofItems) {
    $spoofItems | Format-Table SpoofedUser,SendingInfrastructure,SpoofType,Action -AutoSize
} else {
    Write-Host "No allowed spoof items found"
}

# 4. Tenant Allow List
Write-Host "`n--- Domain & Sender Allow Entries ---" -ForegroundColor Yellow
$allowItems = Get-TenantAllowBlockListItems -ListType Sender -Allow -ErrorAction SilentlyContinue
if ($allowItems) {
    $allowItems | Format-Table Identity,Entries,ExpirationDate,Notes -AutoSize
} else {
    Write-Host "No sender allow list items found"
}

# 5. DMARC Check
Write-Host "`n--- DMARC Enforcement ---" -ForegroundColor Yellow
Get-AntiPhishPolicy | Format-Table Name,DmarcPolicyAction,Enabled -AutoSize

# 6. DKIM Check
Write-Host "`n--- DKIM Configuration ---" -ForegroundColor Yellow
Get-DkimSigningConfig | Format-Table Domain,Enabled,Status -AutoSize

# 7. Summary
Write-Host "`n=== SECURITY ASSESSMENT ===" -ForegroundColor Cyan

$issues = @()

if ($cf.IPAllowList.Count -gt 0) {
    $issues += "⚠️ IP Allow List contains $($cf.IPAllowList.Count) entries - consider removing per CIS guidelines"
}

if ($cf.EnableSafeList) {
    $issues += "⚠️ SafeList is enabled - should be disabled to prevent bypassing filters"
}

if ($filter.AllowedSenderDomains.Count -gt 5) {
    $issues += "⚠️ Many allowed sender domains ($($filter.AllowedSenderDomains.Count)) - review for necessity"
}

if ($filter.BulkThreshold -gt 6) {
    $issues += "⚠️ Bulk threshold is high ($($filter.BulkThreshold)) - consider lowering to 6 or below"
}

if ($issues.Count -gt 0) {
    Write-Host "Issues Found:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  $issue"
    }
} else {
    Write-Host "✅ Basic security configuration looks good!" -ForegroundColor Green
}

Write-Host "`nAllowed domains count:" $filter.AllowedSenderDomains.Count
Write-Host "Allowed senders count:" $filter.AllowedSenders.Count

Write-Host "`nTo disconnect, run: Disconnect-ExchangeOnline -Confirm:`$false" -ForegroundColor Yellow