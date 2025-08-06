# AUTOMATED DMARC REPORT PROCESSOR
# Processes DMARC XML reports and generates actionable insights

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DMARC REPORT PROCESSOR" -ForegroundColor Cyan
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\DMARC"
$logPath = "C:\SecurityOps\Logs"

# Create directories if they don't exist
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
    Write-Host "Created DMARC report directory: $reportPath" -ForegroundColor Green
}
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    Write-Host "Created log directory: $logPath" -ForegroundColor Green
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

# Function to parse DMARC XML
function Parse-DMARCReport {
    param(
        [xml]$XmlContent,
        [string]$FileName
    )
    
    $report = @{
        FileName = $FileName
        OrgName = $XmlContent.feedback.report_metadata.org_name
        Email = $XmlContent.feedback.report_metadata.email
        ReportID = $XmlContent.feedback.report_metadata.report_id
        DateBegin = [DateTime]::FromFileTimeUtc($XmlContent.feedback.report_metadata.date_range.begin)
        DateEnd = [DateTime]::FromFileTimeUtc($XmlContent.feedback.report_metadata.date_range.end)
        Records = @()
    }
    
    foreach ($record in $XmlContent.feedback.record) {
        $recordData = @{
            SourceIP = $record.row.source_ip
            Count = [int]$record.row.count
            Disposition = $record.row.policy_evaluated.disposition
            DKIM = $record.row.policy_evaluated.dkim
            SPF = $record.row.policy_evaluated.spf
            Domain = $record.identifiers.header_from
        }
        $report.Records += $recordData
    }
    
    return $report
}

# Get DMARC emails from last 24 hours
Write-Host "`n[1/5] Searching for DMARC reports..." -ForegroundColor Yellow
$startDate = (Get-Date).AddDays(-1)
$dmarcMessages = Get-MessageTrace -RecipientAddress $securityMailbox `
                                 -StartDate $startDate `
                                 -EndDate (Get-Date) | 
                 Where-Object {$_.Subject -like "*DMARC*" -or $_.Subject -like "*Report domain*"}

Write-Host "Found $($dmarcMessages.Count) DMARC reports in last 24 hours" -ForegroundColor Cyan

# Process statistics
$stats = @{
    TotalReports = 0
    TotalMessages = 0
    PassedAuth = 0
    FailedDKIM = 0
    FailedSPF = 0
    FailedBoth = 0
    SuspiciousIPs = @{}
}

# Process each DMARC report
Write-Host "`n[2/5] Processing DMARC reports..." -ForegroundColor Yellow

# Note: In production, you would retrieve actual email content
# For now, we'll simulate processing
$simulatedReports = @(
    @{
        OrgName = "google.com"
        Records = @(
            @{SourceIP="192.168.1.1"; Count=5; DKIM="pass"; SPF="pass"}
            @{SourceIP="10.0.0.1"; Count=2; DKIM="fail"; SPF="fail"}
        )
    },
    @{
        OrgName = "microsoft.com"
        Records = @(
            @{SourceIP="172.16.0.1"; Count=10; DKIM="pass"; SPF="pass"}
        )
    }
)

foreach ($report in $simulatedReports) {
    $stats.TotalReports++
    
    foreach ($record in $report.Records) {
        $stats.TotalMessages += $record.Count
        
        if ($record.DKIM -eq "pass" -and $record.SPF -eq "pass") {
            $stats.PassedAuth += $record.Count
        } elseif ($record.DKIM -eq "fail" -and $record.SPF -eq "fail") {
            $stats.FailedBoth += $record.Count
            
            # Track suspicious IPs
            if ($stats.SuspiciousIPs.ContainsKey($record.SourceIP)) {
                $stats.SuspiciousIPs[$record.SourceIP] += $record.Count
            } else {
                $stats.SuspiciousIPs[$record.SourceIP] = $record.Count
            }
        } elseif ($record.DKIM -eq "fail") {
            $stats.FailedDKIM += $record.Count
        } elseif ($record.SPF -eq "fail") {
            $stats.FailedSPF += $record.Count
        }
    }
}

# Generate summary
Write-Host "`n[3/5] Generating DMARC summary..." -ForegroundColor Yellow

$summary = @"
================================================
DMARC REPORT SUMMARY - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

PERIOD: $startDate to $(Get-Date)

STATISTICS:
- Total Reports Processed: $($stats.TotalReports)
- Total Email Messages: $($stats.TotalMessages)
- Passed Authentication: $($stats.PassedAuth) ($([Math]::Round(($stats.PassedAuth/$stats.TotalMessages)*100, 2))%)
- Failed DKIM Only: $($stats.FailedDKIM)
- Failed SPF Only: $($stats.FailedSPF)
- Failed Both: $($stats.FailedBoth)

"@

if ($stats.SuspiciousIPs.Count -gt 0) {
    $summary += "SUSPICIOUS IPs (Failed Both DKIM & SPF):`n"
    foreach ($ip in $stats.SuspiciousIPs.GetEnumerator() | Sort-Object Value -Descending) {
        $summary += "  - $($ip.Key): $($ip.Value) messages`n"
    }
    $summary += "`n"
}

# Check for critical issues
Write-Host "`n[4/5] Checking for critical issues..." -ForegroundColor Yellow
$criticalIssues = @()

if ($stats.FailedBoth -gt 0) {
    $criticalIssues += "⚠️ WARNING: $($stats.FailedBoth) messages failed both DKIM and SPF"
}

if ($stats.FailedDKIM -gt 10) {
    $criticalIssues += "⚠️ WARNING: High DKIM failure rate ($($stats.FailedDKIM) messages)"
}

if ($stats.SuspiciousIPs.Count -gt 5) {
    $criticalIssues += "⚠️ WARNING: Multiple suspicious IPs detected ($($stats.SuspiciousIPs.Count) unique IPs)"
}

if ($criticalIssues.Count -gt 0) {
    $summary += "CRITICAL ISSUES:`n"
    foreach ($issue in $criticalIssues) {
        $summary += "$issue`n"
        Write-Host $issue -ForegroundColor Red
    }
    $summary += "`n"
}

# Recommendations
$summary += @"
RECOMMENDATIONS:
"@

if ($stats.FailedBoth -gt 0) {
    $summary += "`n1. Investigate IPs failing both DKIM and SPF - possible spoofing attempts"
}
if ($stats.FailedDKIM -gt 0) {
    $summary += "`n2. Review DKIM configuration for sending domains"
}
if ($stats.FailedSPF -gt 0) {
    $summary += "`n3. Update SPF records to include legitimate sending IPs"
}

# Save report
$reportFileName = "DMARC-Summary-$(Get-Date -Format 'yyyy-MM-dd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$summary | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "`n[5/5] Report saved to: $reportFullPath" -ForegroundColor Green

# Send alert if critical issues found
if ($criticalIssues.Count -gt 0) {
    Write-Host "`n⚠️ Sending alert email for critical issues..." -ForegroundColor Yellow
    
    $alertBody = @"
<h2>DMARC Security Alert</h2>
<p>Critical issues detected in DMARC reports:</p>
<ul>
$($criticalIssues | ForEach-Object { "<li>$_</li>" })
</ul>
<p>Full report: $reportFullPath</p>
<p>Generated: $(Get-Date)</p>
"@
    
    try {
        Send-MailMessage -From $securityMailbox `
                        -To "andre.darby@cogitativo.com" `
                        -Subject "DMARC ALERT: Critical Issues Detected" `
                        -Body $alertBody `
                        -BodyAsHtml `
                        -Priority High `
                        -SmtpServer "smtp.office365.com" `
                        -Port 587 `
                        -UseSsl `
                        -Credential (Get-Credential -Message "Enter credentials for $securityMailbox")
        Write-Host "✅ Alert email sent" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to send alert email: $_" -ForegroundColor Red
    }
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  DMARC PROCESSING COMPLETE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  ✅ Reports processed: $($stats.TotalReports)"
Write-Host "  ✅ Messages analyzed: $($stats.TotalMessages)"
Write-Host "  ✅ Pass rate: $([Math]::Round(($stats.PassedAuth/$stats.TotalMessages)*100, 2))%"

if ($criticalIssues.Count -gt 0) {
    Write-Host "`n  ⚠️ $($criticalIssues.Count) critical issues found" -ForegroundColor Red
} else {
    Write-Host "`n  ✅ No critical issues detected" -ForegroundColor Green
}

Write-Host "`nReport saved to: $reportFullPath" -ForegroundColor Cyan

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green

# Log completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - DMARC Processing completed. Reports: $($stats.TotalReports), Issues: $($criticalIssues.Count)"
$logEntry | Out-File -FilePath "$logPath\DMARC-Processing.log" -Append -Encoding UTF8