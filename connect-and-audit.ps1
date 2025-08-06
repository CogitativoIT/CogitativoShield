# Connect to Exchange Online and run security audit
Write-Host "=== Office 365 Security Audit ===" -ForegroundColor Cyan
Write-Host "Attempting device code authentication..." -ForegroundColor Yellow

# Import module
Import-Module ExchangeOnlineManagement

# Try device code authentication
try {
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -Device
    Write-Host "`nConnected successfully!" -ForegroundColor Green
} catch {
    Write-Host "Trying alternative connection method..." -ForegroundColor Yellow
    try {
        Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -UseMultiThreadedImport:$false
    } catch {
        Write-Host "Connection failed. Please run manually:" -ForegroundColor Red
        Write-Host "Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com" -ForegroundColor Yellow
        exit
    }
}

Write-Host "`nRunning security checks..." -ForegroundColor Cyan

# Quick security assessment
try {
    # Connection Filter
    Write-Host "`n--- CONNECTION FILTER POLICY ---" -ForegroundColor Yellow
    $cf = Get-HostedConnectionFilterPolicy -Identity Default -ErrorAction Stop
    Write-Host "IP Allow List entries: $($cf.IPAllowList.Count)"
    Write-Host "Safe List Enabled: $($cf.EnableSafeList)"
    
    # Anti-Spam
    Write-Host "`n--- ANTI-SPAM POLICY ---" -ForegroundColor Yellow
    $filter = Get-HostedContentFilterPolicy -Identity Default -ErrorAction Stop
    Write-Host "Spam Action: $($filter.SpamAction)"
    Write-Host "High Confidence Spam: $($filter.HighConfidenceSpamAction)"
    Write-Host "Phishing Action: $($filter.PhishSpamAction)"
    Write-Host "Bulk Threshold: $($filter.BulkThreshold)"
    Write-Host "Allowed Domains: $($filter.AllowedSenderDomains.Count)"
    Write-Host "Allowed Senders: $($filter.AllowedSenders.Count)"
    
    # Anti-Phishing
    Write-Host "`n--- ANTI-PHISHING ---" -ForegroundColor Yellow
    $phish = Get-AntiPhishPolicy | Select-Object -First 1
    if ($phish) {
        Write-Host "Policy: $($phish.Name)"
        Write-Host "DMARC Action: $($phish.DmarcPolicyAction)"
        Write-Host "Enabled: $($phish.Enabled)"
    }
    
    # DKIM
    Write-Host "`n--- DKIM STATUS ---" -ForegroundColor Yellow
    $dkim = Get-DkimSigningConfig | Where-Object {$_.Domain -like "*cogitativo*"}
    if ($dkim) {
        Write-Host "Domain: $($dkim.Domain)"
        Write-Host "DKIM Enabled: $($dkim.Enabled)"
        Write-Host "Status: $($dkim.Status)"
    }
    
    # Audit
    Write-Host "`n--- AUDIT CONFIGURATION ---" -ForegroundColor Yellow
    $audit = Get-AdminAuditLogConfig
    Write-Host "Admin Audit Log: $($audit.AdminAuditLogEnabled)"
    Write-Host "Unified Audit Log: $($audit.UnifiedAuditLogIngestionEnabled)"
    
    # Recommendations
    Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan
    
    if ($cf.IPAllowList.Count -gt 0) {
        Write-Host "❗ Remove IP Allow List entries - they bypass spam filtering" -ForegroundColor Red
    }
    
    if ($cf.EnableSafeList) {
        Write-Host "❗ Disable Safe List to prevent filter bypass" -ForegroundColor Red
    }
    
    if ($filter.BulkThreshold -gt 6) {
        Write-Host "⚠️ Lower bulk threshold to 6 or below (currently $($filter.BulkThreshold))" -ForegroundColor Yellow
    }
    
    if ($filter.AllowedSenderDomains.Count -gt 10) {
        Write-Host "⚠️ Review allowed domains list - minimize to reduce risk" -ForegroundColor Yellow
    }
    
    if ($dkim -and !$dkim.Enabled) {
        Write-Host "❗ Enable DKIM for cogitativo.com" -ForegroundColor Red
    }
    
    if (!$audit.UnifiedAuditLogIngestionEnabled) {
        Write-Host "❗ Enable Unified Audit Logging" -ForegroundColor Red
    }
    
    Write-Host "`n✅ Security audit complete!" -ForegroundColor Green
    
} catch {
    Write-Host "Error running security checks: $_" -ForegroundColor Red
}

# Disconnect
Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false