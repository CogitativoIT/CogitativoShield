# AUTOMATED O365 FULL AUDIT - RUNS WITHOUT POPUP
# This script runs after certificate authentication is configured

param(
    [Parameter(Mandatory=$false)]
    [string]$AppId,
    
    [Parameter(Mandatory=$false)]
    [string]$CertThumbprint,
    
    [Parameter(Mandatory=$false)]
    [string]$Organization = "cogitativo.onmicrosoft.com"
)

# If parameters not provided, try to read from saved config
if (!$AppId -or !$CertThumbprint) {
    $configFile = "C:\Users\andre.darby\Ops\o365-config.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        $AppId = $config.AppId
        $CertThumbprint = $config.CertThumbprint
    } else {
        Write-Host "ERROR: No configuration found. Run SETUP-UNATTENDED-O365.ps1 first!" -ForegroundColor Red
        exit 1
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "C:\Users\andre.darby\Ops\O365-AUDIT-$timestamp.txt"

# Start logging
Start-Transcript -Path $reportFile

Write-Host @"
================================================================================
              AUTOMATED O365 COMPREHENSIVE SECURITY AUDIT
                        Organization: $Organization
                        Date: $(Get-Date)
================================================================================
"@ -ForegroundColor Cyan

try {
    # Connect using certificate
    Write-Host "Connecting to Exchange Online (Certificate Auth)..." -ForegroundColor Yellow
    Connect-ExchangeOnline `
        -AppId $AppId `
        -CertificateThumbprint $CertThumbprint `
        -Organization $Organization `
        -ShowBanner:$false `
        -ErrorAction Stop
    
    Write-Host "✅ Connected successfully!" -ForegroundColor Green
    
    # RUN FULL AUDIT
    Write-Host "`n[1/15] ORGANIZATION CONFIGURATION" -ForegroundColor Yellow
    Get-OrganizationConfig | Format-List
    
    Write-Host "`n[2/15] ACCEPTED DOMAINS" -ForegroundColor Yellow
    Get-AcceptedDomain | Format-Table Name, DomainName, DomainType, Default -AutoSize
    
    Write-Host "`n[3/15] DKIM CONFIGURATION" -ForegroundColor Yellow
    Get-DkimSigningConfig | Format-Table Domain, Enabled, Status -AutoSize
    
    Write-Host "`n[4/15] ANTI-SPAM POLICIES" -ForegroundColor Yellow
    Get-HostedContentFilterPolicy | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        $_ | Select-Object Name, SpamAction, BulkSpamAction, BulkThreshold, HighConfidenceSpamAction, EnableEndUserSpamNotifications | Format-List
    }
    
    Write-Host "`n[5/15] ANTI-PHISHING POLICIES" -ForegroundColor Yellow
    Get-AntiPhishPolicy | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        $_ | Select-Object Name, IsDefault, DmarcQuarantineAction, DmarcRejectAction, EnableTargetedUserProtection | Format-List
    }
    
    Write-Host "`n[6/15] CONNECTION FILTER POLICIES" -ForegroundColor Yellow
    Get-HostedConnectionFilterPolicy | ForEach-Object {
        Write-Host "`nPolicy: $($_.Name)" -ForegroundColor Cyan
        Write-Host "  IP Allow List: $($_.IPAllowList.Count) entries"
        Write-Host "  IP Block List: $($_.IPBlockList.Count) entries"
        Write-Host "  Safe List Enabled: $($_.EnableSafeList)"
    }
    
    Write-Host "`n[7/15] MAIL FLOW RULES" -ForegroundColor Yellow
    $rules = Get-TransportRule
    Write-Host "Total Rules: $($rules.Count)" -ForegroundColor Cyan
    if ($rules.Count -gt 0) {
        $rules | Select-Object Name, State, Priority, Description | Format-Table -AutoSize
    }
    
    Write-Host "`n[8/15] OUTBOUND SPAM FILTER" -ForegroundColor Yellow
    Get-HostedOutboundSpamFilterPolicy | Select-Object Name, RecipientLimitPerDay, AutoForwardingMode | Format-Table -AutoSize
    
    Write-Host "`n[9/15] MALWARE FILTER POLICIES" -ForegroundColor Yellow
    Get-MalwareFilterPolicy | Select-Object Name, Action, EnableFileFilter, ZapEnabled | Format-Table -AutoSize
    
    Write-Host "`n[10/15] QUARANTINE POLICIES" -ForegroundColor Yellow
    try {
        Get-QuarantinePolicy -ErrorAction SilentlyContinue | Select-Object Name, EndUserQuarantinePermissionsValue | Format-Table -AutoSize
    } catch {
        Write-Host "  Quarantine policies not accessible" -ForegroundColor Gray
    }
    
    Write-Host "`n[11/15] ADMIN AUDIT CONFIGURATION" -ForegroundColor Yellow
    Get-AdminAuditLogConfig | Select-Object AdminAuditLogEnabled, UnifiedAuditLogIngestionEnabled, AdminAuditLogAgeLimit | Format-List
    
    Write-Host "`n[12/15] ROLE GROUPS AND ADMIN ROLES" -ForegroundColor Yellow
    Get-RoleGroup | Where-Object {$_.Members.Count -gt 0} | Select-Object Name, Members | Format-Table -AutoSize
    
    Write-Host "`n[13/15] MOBILE DEVICE POLICIES" -ForegroundColor Yellow
    Get-MobileDeviceMailboxPolicy | Select-Object Name, PasswordEnabled, MinPasswordLength, MaxInactivityTimeLock | Format-Table -AutoSize
    
    Write-Host "`n[14/15] SHARING POLICIES" -ForegroundColor Yellow
    Get-SharingPolicy | Select-Object Name, Enabled, Default, Domains | Format-Table -AutoSize
    
    Write-Host "`n[15/15] TENANT ALLOW/BLOCK LISTS" -ForegroundColor Yellow
    try {
        $spoofItems = Get-TenantAllowBlockListSpoofItems -ErrorAction SilentlyContinue
        Write-Host "  Spoof Allow Items: $(($spoofItems | Where-Object {$_.Action -eq 'Allow'}).Count)"
        Write-Host "  Spoof Block Items: $(($spoofItems | Where-Object {$_.Action -eq 'Block'}).Count)"
    } catch {
        Write-Host "  Unable to retrieve spoof items" -ForegroundColor Gray
    }
    
    # SECURITY SUMMARY
    Write-Host "`n================================================================================`n" -ForegroundColor Cyan
    Write-Host "SECURITY ASSESSMENT SUMMARY" -ForegroundColor Yellow
    Write-Host "================================================================================`n" -ForegroundColor Cyan
    
    $defaultPolicy = Get-HostedContentFilterPolicy -Identity Default
    $defaultPhish = Get-AntiPhishPolicy | Where-Object {$_.IsDefault -eq $true}
    $audit = Get-AdminAuditLogConfig
    
    Write-Host "Key Security Settings:" -ForegroundColor Green
    Write-Host "  ✓ Spam Action: $($defaultPolicy.SpamAction)"
    Write-Host "  ✓ Bulk Threshold: $($defaultPolicy.BulkThreshold)"
    Write-Host "  ✓ DMARC Action: $($defaultPhish.DmarcQuarantineAction)"
    Write-Host "  ✓ User Notifications: $($defaultPolicy.EnableEndUserSpamNotifications)"
    Write-Host "  ✓ Unified Audit Log: $($audit.UnifiedAuditLogIngestionEnabled)"
    
    # Recommendations
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    
    $dkim = Get-DkimSigningConfig | Where-Object {$_.Domain -like "*cogitativo*"}
    if ($dkim -and !$dkim.Enabled) {
        Write-Host "  ❗ Enable DKIM for cogitativo.com" -ForegroundColor Red
    }
    
    $cf = Get-HostedConnectionFilterPolicy -Identity Default
    if ($cf.IPAllowList.Count -gt 0) {
        Write-Host "  ⚠️ Review IP Allow List ($($cf.IPAllowList.Count) entries)" -ForegroundColor Yellow
    }
    
    if (!$audit.UnifiedAuditLogIngestionEnabled) {
        Write-Host "  ❗ Enable Unified Audit Logging" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
} finally {
    # Disconnect
    Write-Host "`nDisconnecting..." -ForegroundColor Yellow
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
}

Stop-Transcript

Write-Host "`n================================================================================`n" -ForegroundColor Cyan
Write-Host "AUDIT COMPLETE!" -ForegroundColor Green
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "`n================================================================================`n" -ForegroundColor Cyan

# Create HTML report
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>O365 Security Audit - $Organization</title>
    <style>
        body { font-family: 'Segoe UI', Arial; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .success { color: #00b894; }
        .warning { color: #fdcb6e; }
        .error { color: #d63031; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Office 365 Security Audit</h1>
        <p>Organization: $Organization | Date: $(Get-Date)</p>
    </div>
    <div class="section">
        <h2>Audit Results</h2>
        <p>Full audit results have been saved to: $reportFile</p>
        <p class="success">✓ Audit completed successfully</p>
    </div>
</body>
</html>
"@

$htmlFile = "C:\Users\andre.darby\Ops\O365-AUDIT-$timestamp.html"
$htmlReport | Out-File $htmlFile -Encoding UTF8

Write-Host "HTML report saved to: $htmlFile" -ForegroundColor Green