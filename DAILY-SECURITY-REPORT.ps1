# DAILY SECURITY OPERATIONS REPORT GENERATOR
# Generates comprehensive daily security summary for security@cogitativo.com

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DAILY SECURITY OPERATIONS REPORT" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'MMMM dd, yyyy')" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\DailyReports"
$yesterday = (Get-Date).AddDays(-1)
$today = Get-Date

# Create report directory
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}

# Connect to Exchange Online
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction Stop
    Write-Host "✅ Connected successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

# Initialize metrics
$metrics = @{
    # Email Statistics
    TotalSecurityEmails = 0
    DMARCReports = 0
    PhishingReports = 0
    DLPIncidents = 0
    SpamReports = 0
    
    # Security Actions
    BlockedSenders = 0
    QuarantinedEmails = 0
    
    # Threat Intelligence
    SuspiciousIPs = @()
    MaliciousDomains = @()
    
    # Mailbox Stats
    InboxCount = 0
    ProcessedToday = 0
}

Write-Host "`n[1/8] Gathering email statistics..." -ForegroundColor Yellow

# Get message trace for security mailbox
$messages = Get-MessageTrace -RecipientAddress $securityMailbox `
                            -StartDate $yesterday `
                            -EndDate $today

$metrics.TotalSecurityEmails = $messages.Count

# Categorize messages
$metrics.DMARCReports = ($messages | Where-Object {$_.Subject -like "*DMARC*" -or $_.Subject -like "*Report domain*"}).Count
$metrics.PhishingReports = ($messages | Where-Object {$_.Subject -match "phish|suspicious|scam"}).Count
$metrics.DLPIncidents = ($messages | Where-Object {$_.Subject -like "*DLP*" -or $_.Subject -like "*Data Loss*"}).Count
$metrics.SpamReports = ($messages | Where-Object {$_.Subject -match "spam|junk"}).Count

Write-Host "  Found $($metrics.TotalSecurityEmails) security emails in last 24 hours" -ForegroundColor Cyan

Write-Host "`n[2/8] Checking blocked senders..." -ForegroundColor Yellow

# Get blocked senders added in last 24 hours
try {
    $blockedItems = Get-TenantAllowBlockListItems -ListType Sender | 
                   Where-Object {$_.CreatedDateTime -gt $yesterday -and $_.Action -eq "Block"}
    $metrics.BlockedSenders = $blockedItems.Count
    Write-Host "  $($metrics.BlockedSenders) senders blocked in last 24 hours" -ForegroundColor Cyan
} catch {
    Write-Host "  Unable to retrieve blocked senders" -ForegroundColor Gray
}

Write-Host "`n[3/8] Analyzing quarantine activity..." -ForegroundColor Yellow

# Get quarantine statistics
try {
    $quarantineMessages = Get-QuarantineMessage -StartReceivedDate $yesterday -EndReceivedDate $today -ErrorAction SilentlyContinue
    $metrics.QuarantinedEmails = $quarantineMessages.Count
    Write-Host "  $($metrics.QuarantinedEmails) emails quarantined" -ForegroundColor Cyan
} catch {
    Write-Host "  Unable to retrieve quarantine statistics" -ForegroundColor Gray
}

Write-Host "`n[4/8] Checking mailbox status..." -ForegroundColor Yellow

# Get mailbox folder statistics
$folderStats = Get-MailboxFolderStatistics -Identity $securityMailbox
$inboxFolder = $folderStats | Where-Object {$_.Name -eq "Inbox"}
$metrics.InboxCount = $inboxFolder.ItemsInFolder

Write-Host "  Current inbox count: $($metrics.InboxCount) items" -ForegroundColor Cyan

Write-Host "`n[5/8] Analyzing threat patterns..." -ForegroundColor Yellow

# Analyze message patterns for threats
$suspiciousSenders = $messages | Where-Object {$_.SenderAddress -match 'gmail\.com|outlook\.com|yahoo\.com'} | 
                    Group-Object SenderAddress | 
                    Where-Object {$_.Count -gt 3} | 
                    Sort-Object Count -Descending | 
                    Select-Object -First 5

if ($suspiciousSenders) {
    Write-Host "  Found suspicious sender patterns" -ForegroundColor Yellow
}

Write-Host "`n[6/8] Checking system health..." -ForegroundColor Yellow

# Check mail flow rules status
$securityRules = Get-TransportRule | Where-Object {$_.Name -like "Security-*"}
$activeRules = $securityRules | Where-Object {$_.State -eq "Enabled"}

Write-Host "  Security mail flow rules: $($activeRules.Count) active of $($securityRules.Count) total" -ForegroundColor Cyan

Write-Host "`n[7/8] Generating report..." -ForegroundColor Yellow

# Generate HTML report
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Daily Security Report - $(Get-Date -Format 'MMM dd, yyyy')</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .section { background-color: white; margin: 20px 0; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #3498db; }
        .metric-label { color: #7f8c8d; font-size: 12px; }
        table { width: 100%; border-collapse: collapse; }
        th { background-color: #ecf0f1; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ecf0f1; }
        .alert { background-color: #e74c3c; color: white; padding: 10px; border-radius: 3px; margin: 10px 0; }
        .warning { background-color: #f39c12; color: white; padding: 10px; border-radius: 3px; margin: 10px 0; }
        .success { background-color: #27ae60; color: white; padding: 10px; border-radius: 3px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Daily Security Operations Report</h1>
        <p>$(Get-Date -Format 'dddd, MMMM dd, yyyy') | Cogitativo.com</p>
    </div>
    
    <div class="section">
        <h2>24-Hour Summary</h2>
        <div class="metric">
            <div class="metric-value">$($metrics.TotalSecurityEmails)</div>
            <div class="metric-label">TOTAL EMAILS</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($metrics.DMARCReports)</div>
            <div class="metric-label">DMARC REPORTS</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($metrics.PhishingReports)</div>
            <div class="metric-label">PHISHING REPORTS</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($metrics.BlockedSenders)</div>
            <div class="metric-label">BLOCKED SENDERS</div>
        </div>
    </div>
    
    <div class="section">
        <h2>Security Actions</h2>
        <table>
            <tr><th>Action</th><th>Count</th><th>Status</th></tr>
            <tr><td>Emails Processed</td><td>$($metrics.TotalSecurityEmails)</td><td>✅ Automated</td></tr>
            <tr><td>Senders Blocked</td><td>$($metrics.BlockedSenders)</td><td>✅ Automated</td></tr>
            <tr><td>Emails Quarantined</td><td>$($metrics.QuarantinedEmails)</td><td>✅ Automated</td></tr>
            <tr><td>DLP Incidents</td><td>$($metrics.DLPIncidents)</td><td>$(if($metrics.DLPIncidents -gt 0){"⚠️ Review"}else{"✅ Clear"})</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Email Categories</h2>
        <table>
            <tr><th>Category</th><th>Count</th><th>% of Total</th></tr>
            <tr><td>DMARC Reports</td><td>$($metrics.DMARCReports)</td><td>$(if($metrics.TotalSecurityEmails -gt 0){[Math]::Round(($metrics.DMARCReports/$metrics.TotalSecurityEmails)*100,1)}else{0})%</td></tr>
            <tr><td>Phishing Reports</td><td>$($metrics.PhishingReports)</td><td>$(if($metrics.TotalSecurityEmails -gt 0){[Math]::Round(($metrics.PhishingReports/$metrics.TotalSecurityEmails)*100,1)}else{0})%</td></tr>
            <tr><td>DLP Incidents</td><td>$($metrics.DLPIncidents)</td><td>$(if($metrics.TotalSecurityEmails -gt 0){[Math]::Round(($metrics.DLPIncidents/$metrics.TotalSecurityEmails)*100,1)}else{0})%</td></tr>
            <tr><td>Spam Reports</td><td>$($metrics.SpamReports)</td><td>$(if($metrics.TotalSecurityEmails -gt 0){[Math]::Round(($metrics.SpamReports/$metrics.TotalSecurityEmails)*100,1)}else{0})%</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Mailbox Status</h2>
        <p><strong>Current Inbox Items:</strong> $($metrics.InboxCount)</p>
        $(if($metrics.InboxCount -gt 100){"<div class='warning'>⚠️ High inbox count - manual review recommended</div>"})
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        $(if($metrics.PhishingReports -gt 5){"<div class='warning'>⚠️ High phishing report volume - review patterns for user training opportunities</div>"})
        $(if($metrics.DLPIncidents -gt 0){"<div class='alert'>🚨 DLP incidents detected - review for data loss prevention</div>"})
        $(if($metrics.InboxCount -gt 100){"<div class='warning'>⚠️ Process inbox backlog to maintain efficiency</div>"})
        $(if($metrics.BlockedSenders -eq 0 -and $metrics.PhishingReports -gt 0){"<div class='warning'>⚠️ Phishing reports received but no senders blocked - review threshold settings</div>"})
    </div>
    
    <div class="section">
        <p style="text-align: center; color: #7f8c8d; font-size: 12px;">
            Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
            Next report: Tomorrow at 8:00 AM
        </p>
    </div>
</body>
</html>
"@

# Save HTML report
$htmlFileName = "Security-Report-$(Get-Date -Format 'yyyy-MM-dd').html"
$htmlFullPath = Join-Path $reportPath $htmlFileName
$htmlReport | Out-File -FilePath $htmlFullPath -Encoding UTF8

Write-Host "✅ HTML report saved to: $htmlFullPath" -ForegroundColor Green

# Generate text summary
$textSummary = @"
DAILY SECURITY OPERATIONS SUMMARY
$(Get-Date -Format 'dddd, MMMM dd, yyyy')
=====================================

24-HOUR METRICS:
- Total Security Emails: $($metrics.TotalSecurityEmails)
- DMARC Reports: $($metrics.DMARCReports)
- Phishing Reports: $($metrics.PhishingReports)
- DLP Incidents: $($metrics.DLPIncidents)
- Spam Reports: $($metrics.SpamReports)

SECURITY ACTIONS:
- Senders Blocked: $($metrics.BlockedSenders)
- Emails Quarantined: $($metrics.QuarantinedEmails)

MAILBOX STATUS:
- Current Inbox Count: $($metrics.InboxCount) items

$(if($metrics.PhishingReports -gt 5 -or $metrics.DLPIncidents -gt 0 -or $metrics.InboxCount -gt 100){
"ACTION ITEMS:"
})
$(if($metrics.PhishingReports -gt 5){"- Review phishing patterns for training opportunities`n"})
$(if($metrics.DLPIncidents -gt 0){"- Investigate DLP incidents for data loss prevention`n"})
$(if($metrics.InboxCount -gt 100){"- Process inbox backlog`n"})

Report Location: $htmlFullPath
"@

# Save text report
$textFileName = "Security-Summary-$(Get-Date -Format 'yyyy-MM-dd').txt"
$textFullPath = Join-Path $reportPath $textFileName
$textSummary | Out-File -FilePath $textFullPath -Encoding UTF8

Write-Host "✅ Text summary saved to: $textFullPath" -ForegroundColor Green

Write-Host "`n[8/8] Sending report email..." -ForegroundColor Yellow

# Email the report
$emailBody = $htmlReport

try {
    # Note: In production, you would configure proper SMTP settings
    Write-Host "  Report would be emailed to:" -ForegroundColor Cyan
    Write-Host "    - andre.darby@cogitativo.com" -ForegroundColor Gray
    Write-Host "    - david.buhler@cogitativo.com" -ForegroundColor Gray
    Write-Host "  Subject: Daily Security Report - $(Get-Date -Format 'MMM dd, yyyy')" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Failed to send email: $_" -ForegroundColor Red
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  DAILY REPORT COMPLETE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  ✅ Processed $($metrics.TotalSecurityEmails) security emails"
Write-Host "  ✅ Blocked $($metrics.BlockedSenders) senders"
Write-Host "  ✅ Generated HTML and text reports"

if ($metrics.PhishingReports -gt 5 -or $metrics.DLPIncidents -gt 0) {
    Write-Host "`n  ⚠️ Action items identified - review report" -ForegroundColor Yellow
}

Write-Host "`nReports saved to:" -ForegroundColor Cyan
Write-Host "  HTML: $htmlFullPath"
Write-Host "  Text: $textFullPath"

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green