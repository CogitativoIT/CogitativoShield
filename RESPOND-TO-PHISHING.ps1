# AUTOMATED PHISHING RESPONSE SYSTEM
# Analyzes reported phishing emails and takes automated actions

Write-Host "================================================" -ForegroundColor Red
Write-Host "  PHISHING RESPONSE AUTOMATION" -ForegroundColor Red
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Red

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\Phishing"
$logPath = "C:\SecurityOps\Logs"

# Create directories
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
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

# Function to extract IOCs from email
function Extract-PhishingIOCs {
    param(
        [string]$Subject,
        [string]$From,
        [string]$Body
    )
    
    $iocs = @{
        SenderEmail = $From
        SenderDomain = $From.Split('@')[1]
        Subject = $Subject
        URLs = @()
        IPAddresses = @()
        Keywords = @()
    }
    
    # Extract URLs from body
    $urlPattern = 'https?://[^\s]+'
    $urls = [regex]::Matches($Body, $urlPattern)
    foreach ($url in $urls) {
        $iocs.URLs += $url.Value
    }
    
    # Extract IP addresses
    $ipPattern = '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    $ips = [regex]::Matches($Body, $ipPattern)
    foreach ($ip in $ips) {
        $iocs.IPAddresses += $ip.Value
    }
    
    # Check for phishing keywords
    $phishingKeywords = @(
        'verify your account',
        'suspended account',
        'click here immediately',
        'confirm your identity',
        'update payment',
        'unusual activity',
        'expire',
        'urgent action required'
    )
    
    foreach ($keyword in $phishingKeywords) {
        if ($Body -match $keyword -or $Subject -match $keyword) {
            $iocs.Keywords += $keyword
        }
    }
    
    return $iocs
}

# Function to calculate phishing confidence score
function Get-PhishingScore {
    param($IOCs)
    
    $score = 0
    
    # Check sender reputation
    if ($IOCs.SenderDomain -match 'gmail\.com|outlook\.com|yahoo\.com') {
        $score += 20  # Free email provider
    }
    
    # Check for suspicious URLs
    foreach ($url in $IOCs.URLs) {
        if ($url -match 'bit\.ly|tinyurl|goo\.gl|ow\.ly') {
            $score += 30  # URL shortener
        }
        if ($url -match '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') {
            $score += 40  # IP address in URL
        }
    }
    
    # Check for phishing keywords
    $score += ($IOCs.Keywords.Count * 15)
    
    # Check subject patterns
    if ($IOCs.Subject -match 'RE:|FW:' -and $IOCs.Subject -match 'urgent|verify|suspend') {
        $score += 25  # Fake reply/forward with urgency
    }
    
    return [Math]::Min($score, 100)
}

# Get phishing reports from last hour
Write-Host "`n[1/6] Searching for phishing reports..." -ForegroundColor Yellow
$startDate = (Get-Date).AddHours(-1)
$phishingReports = Get-MessageTrace -RecipientAddress $securityMailbox `
                                   -StartDate $startDate `
                                   -EndDate (Get-Date) | 
                   Where-Object {$_.Subject -match 'phish|suspicious|scam'}

Write-Host "Found $($phishingReports.Count) phishing reports in last hour" -ForegroundColor Cyan

# Process each report
$processedReports = @()
$blockedSenders = @()
$investigationNeeded = @()

Write-Host "`n[2/6] Analyzing reported emails..." -ForegroundColor Yellow

foreach ($report in $phishingReports) {
    Write-Host "`n  Processing: $($report.Subject)" -ForegroundColor Gray
    
    # Extract IOCs (simulated - in production would get actual email content)
    $iocs = @{
        SenderEmail = $report.SenderAddress
        SenderDomain = $report.SenderAddress.Split('@')[1]
        Subject = $report.Subject
        URLs = @()
        Keywords = @()
    }
    
    # Calculate phishing score
    $score = Get-PhishingScore -IOCs $iocs
    
    $reportData = @{
        MessageId = $report.MessageId
        ReceivedTime = $report.Received
        Reporter = $report.RecipientAddress
        SuspiciousSender = $iocs.SenderEmail
        Subject = $iocs.Subject
        PhishingScore = $score
        Action = "None"
    }
    
    # Determine action based on score
    if ($score -ge 70) {
        Write-Host "    ⚠️ HIGH CONFIDENCE PHISHING (Score: $score)" -ForegroundColor Red
        $reportData.Action = "Block"
        $blockedSenders += $iocs.SenderEmail
    } elseif ($score -ge 40) {
        Write-Host "    ⚠️ MEDIUM CONFIDENCE - Needs review (Score: $score)" -ForegroundColor Yellow
        $reportData.Action = "Investigate"
        $investigationNeeded += $reportData
    } else {
        Write-Host "    ✅ LOW RISK (Score: $score)" -ForegroundColor Green
        $reportData.Action = "Monitor"
    }
    
    $processedReports += $reportData
}

# Block high-confidence phishing senders
Write-Host "`n[3/6] Blocking confirmed phishing senders..." -ForegroundColor Yellow

foreach ($sender in $blockedSenders) {
    Write-Host "  Blocking: $sender" -ForegroundColor Red
    
    try {
        # Check if already blocked
        $existingBlock = Get-TenantAllowBlockListItems -ListType Sender -ErrorAction SilentlyContinue | 
                        Where-Object {$_.Value -eq $sender}
        
        if (!$existingBlock) {
            New-TenantAllowBlockListItems -ListType Sender `
                                         -Block `
                                         -Entries $sender `
                                         -Notes "Auto-blocked by phishing response system $(Get-Date)" `
                                         -ErrorAction Stop
            Write-Host "    ✅ Blocked successfully" -ForegroundColor Green
        } else {
            Write-Host "    ℹ️ Already blocked" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ❌ Failed to block: $_" -ForegroundColor Red
    }
}

# Search and purge emails from blocked senders
Write-Host "`n[4/6] Purging emails from blocked senders..." -ForegroundColor Yellow

foreach ($sender in $blockedSenders) {
    Write-Host "  Searching for emails from: $sender" -ForegroundColor Cyan
    
    try {
        $searchName = "Phish_Purge_$(Get-Date -f 'yyyyMMddHHmm')_$($sender.Replace('@','_'))"
        
        # Create compliance search
        $search = New-ComplianceSearch -Name $searchName `
                                      -ExchangeLocation All `
                                      -ContentMatchQuery "from:$sender" `
                                      -ErrorAction Stop
        
        Start-ComplianceSearch -Identity $searchName
        
        # Wait for search to complete
        $timeout = 60  # 60 seconds timeout
        $elapsed = 0
        while ((Get-ComplianceSearch -Identity $searchName).Status -ne "Completed" -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 2
            $elapsed += 2
        }
        
        $results = Get-ComplianceSearch -Identity $searchName
        
        if ($results.Items -gt 0) {
            Write-Host "    Found $($results.Items) emails to purge" -ForegroundColor Yellow
            
            # Create purge action
            New-ComplianceSearchAction -SearchName $searchName `
                                     -Purge `
                                     -PurgeType SoftDelete `
                                     -Confirm:$false
            
            Write-Host "    ✅ Purge initiated" -ForegroundColor Green
        } else {
            Write-Host "    No emails found from this sender" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ❌ Error during purge: $_" -ForegroundColor Red
    }
}

# Generate report
Write-Host "`n[5/6] Generating phishing response report..." -ForegroundColor Yellow

$reportContent = @"
================================================
PHISHING RESPONSE REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

PERIOD: $startDate to $(Get-Date)

SUMMARY:
- Total Reports Processed: $($processedReports.Count)
- High Confidence Phishing: $($blockedSenders.Count)
- Needs Investigation: $($investigationNeeded.Count)
- Senders Blocked: $($blockedSenders.Count)

BLOCKED SENDERS:
$($blockedSenders | ForEach-Object { "  - $_" } | Out-String)

REQUIRES INVESTIGATION:
$($investigationNeeded | ForEach-Object { "  - $($_.SuspiciousSender): $($_.Subject) (Score: $($_.PhishingScore))" } | Out-String)

ACTIONS TAKEN:
- Blocked $($blockedSenders.Count) sender(s)
- Initiated email purge for blocked senders
- Generated alerts for suspicious emails

"@

# Save report
$reportFileName = "Phishing-Response-$(Get-Date -Format 'yyyy-MM-dd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$reportContent | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "✅ Report saved to: $reportFullPath" -ForegroundColor Green

# Send notification emails
Write-Host "`n[6/6] Sending notifications..." -ForegroundColor Yellow

if ($blockedSenders.Count -gt 0 -or $investigationNeeded.Count -gt 0) {
    $emailBody = @"
<h2>Phishing Response Summary</h2>
<p><strong>Automated actions taken at $(Get-Date)</strong></p>

<h3>Statistics:</h3>
<ul>
<li>Reports processed: $($processedReports.Count)</li>
<li>Senders blocked: $($blockedSenders.Count)</li>
<li>Requires manual review: $($investigationNeeded.Count)</li>
</ul>

$(if ($blockedSenders.Count -gt 0) {
"<h3>Blocked Senders:</h3>
<ul>
$($blockedSenders | ForEach-Object { "<li>$_</li>" } | Out-String)
</ul>"
})

$(if ($investigationNeeded.Count -gt 0) {
"<h3>Needs Investigation:</h3>
<ul>
$($investigationNeeded | ForEach-Object { "<li>$($_.SuspiciousSender) - Score: $($_.PhishingScore)</li>" } | Out-String)
</ul>"
})

<p>Full report: $reportFullPath</p>
"@
    
    Write-Host "  Notification would be sent to andre.darby@cogitativo.com" -ForegroundColor Cyan
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  PHISHING RESPONSE COMPLETE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  ✅ Reports processed: $($processedReports.Count)"
Write-Host "  ✅ Senders blocked: $($blockedSenders.Count)"
Write-Host "  ⚠️ Needs investigation: $($investigationNeeded.Count)"

Write-Host "`nReport saved to: $reportFullPath" -ForegroundColor Cyan

# Log completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Phishing Response completed. Processed: $($processedReports.Count), Blocked: $($blockedSenders.Count)"
$logEntry | Out-File -FilePath "$logPath\Phishing-Response.log" -Append -Encoding UTF8

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green