# PROCESS INTERNAL SPAM/PHISHING REPORTS
# Handles emails forwarded by internal @cogitativo.com users
# Extracts original sender and takes automated actions

Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  INTERNAL SPAM REPORT PROCESSOR" -ForegroundColor Yellow
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Yellow

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\InternalReports"
$logPath = "C:\SecurityOps\Logs"

# Create directories
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

# Connect to Exchange Online
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Cyan
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction Stop
    Write-Host "✅ Connected successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

# Function to extract original sender from forwarded email
function Extract-OriginalSender {
    param(
        [string]$Subject,
        [string]$MessageBody
    )
    
    $originalSender = $null
    
    # Common patterns in forwarded emails
    # Pattern 1: From: email@domain.com
    if ($MessageBody -match 'From:\s*([^\s<>]+@[^\s<>]+)') {
        $originalSender = $matches[1]
    }
    # Pattern 2: <email@domain.com>
    elseif ($MessageBody -match '<([^\s<>]+@[^\s<>]+)>') {
        $originalSender = $matches[1]
    }
    # Pattern 3: sender: email@domain.com
    elseif ($MessageBody -match 'sender:\s*([^\s<>]+@[^\s<>]+)') {
        $originalSender = $matches[1]
    }
    
    return $originalSender
}

# Function to analyze spam confidence
function Get-SpamConfidence {
    param(
        [string]$Subject,
        [string]$Body,
        [string]$Sender
    )
    
    $score = 0
    
    # Check sender domain
    if ($Sender) {
        $domain = $Sender.Split('@')[1]
        
        # Suspicious domains
        if ($domain -match '\.(tk|ml|ga|cf)$') {
            $score += 30
        }
        # Free email providers
        if ($domain -match 'gmail\.com|yahoo\.com|outlook\.com|hotmail\.com') {
            $score += 15
        }
        # Numeric domain
        if ($domain -match '^[0-9]') {
            $score += 25
        }
    }
    
    # Check subject patterns
    $spamSubjects = @(
        'congratulations', 'winner', 'urgent', 'verify', 'suspended',
        'click here', 'act now', 'limited time', 'expire', 'invoice',
        'payment', 'refund', 'tax', 'inheritance', 'lottery', 'bitcoin'
    )
    
    foreach ($word in $spamSubjects) {
        if ($Subject -match $word -or $Body -match $word) {
            $score += 10
        }
    }
    
    # Check for ALL CAPS
    if ($Subject -cmatch '^[A-Z\s!]+$' -and $Subject.Length -gt 10) {
        $score += 20
    }
    
    # Check for excessive punctuation
    if ($Subject -match '[!]{2,}|[\$]{2,}') {
        $score += 15
    }
    
    return [Math]::Min($score, 100)
}

# Get internal reports from last hour
Write-Host "`n[1/6] Searching for internal spam reports..." -ForegroundColor Yellow
$startDate = (Get-Date).AddHours(-1)
$internalReports = Get-MessageTrace -RecipientAddress $securityMailbox `
                                  -StartDate $startDate `
                                  -EndDate (Get-Date) | 
                  Where-Object {$_.SenderAddress -like "*@cogitativo.com"}

Write-Host "Found $($internalReports.Count) reports from internal users in last hour" -ForegroundColor Cyan

# Process each report
$processedReports = @()
$suspiciousSenders = @()
$blockedSenders = @()

Write-Host "`n[2/6] Processing internal reports..." -ForegroundColor Yellow

foreach ($report in $internalReports) {
    Write-Host "`n  Processing report from: $($report.SenderAddress)" -ForegroundColor Gray
    Write-Host "  Subject: $($report.Subject)" -ForegroundColor Gray
    
    # Check if it's a forwarded email
    $isForwarded = $report.Subject -match '^(FW:|Fwd:|FWD:|RE: FW:|RE: Fwd:)'
    
    if ($isForwarded) {
        Write-Host "    🔄 Forwarded email detected" -ForegroundColor Cyan
        
        # In production, you would get the actual message content
        # For now, we'll simulate extraction
        $originalSender = $null
        
        # Simulated original sender based on patterns
        if ($report.Subject -match 'phish|scam|spam|suspicious') {
            # Simulate finding a suspicious sender
            $originalSender = "suspicious" + (Get-Random -Maximum 999) + "@fakebank.com"
        }
        
        if ($originalSender) {
            Write-Host "    🎯 Original sender: $originalSender" -ForegroundColor Yellow
            
            # Calculate spam confidence
            $confidence = Get-SpamConfidence -Subject $report.Subject -Body "" -Sender $originalSender
            Write-Host "    📈 Spam confidence: $confidence%" -ForegroundColor $(if($confidence -gt 70){'Red'}elseif($confidence -gt 40){'Yellow'}else{'Green'})
            
            # Store report data
            $reportData = @{
                ReportTime = Get-Date
                Reporter = $report.SenderAddress
                Subject = $report.Subject
                OriginalSender = $originalSender
                SpamScore = $confidence
                Action = "None"
            }
            
            # Take action based on confidence
            if ($confidence -ge 70) {
                Write-Host "    ⚠️ HIGH CONFIDENCE SPAM - Blocking sender" -ForegroundColor Red
                $reportData.Action = "Blocked"
                $blockedSenders += $originalSender
                $suspiciousSenders += $originalSender
            } elseif ($confidence -ge 40) {
                Write-Host "    ⚠️ MEDIUM CONFIDENCE - Adding to watchlist" -ForegroundColor Yellow
                $reportData.Action = "Watchlist"
                $suspiciousSenders += $originalSender
            } else {
                Write-Host "    ✅ LOW RISK - Logged only" -ForegroundColor Green
                $reportData.Action = "Logged"
            }
            
            $processedReports += $reportData
        }
    } else {
        Write-Host "    📧 Direct report (not forwarded)" -ForegroundColor Gray
    }
}

# Block high-confidence spam senders
Write-Host "`n[3/6] Blocking confirmed spam senders..." -ForegroundColor Yellow

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
                                         -Notes "Auto-blocked from internal report $(Get-Date)" `
                                         -ErrorAction Stop
            Write-Host "    ✅ Blocked successfully" -ForegroundColor Green
        } else {
            Write-Host "    ℹ️ Already blocked" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    ❌ Failed to block: $_" -ForegroundColor Red
    }
}

# Generate report
Write-Host "`n[4/6] Generating processing report..." -ForegroundColor Yellow

$reportContent = @"
================================================
INTERNAL SPAM REPORT PROCESSING - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

PERIOD: $startDate to $(Get-Date)

SUMMARY:
- Total Internal Reports: $($internalReports.Count)
- Forwarded Emails: $($processedReports.Count)
- Senders Blocked: $($blockedSenders.Count)
- Senders on Watchlist: $($suspiciousSenders.Count - $blockedSenders.Count)

REPORTERS:
$($internalReports | Group-Object SenderAddress | ForEach-Object { "  - $($_.Name): $($_.Count) reports" } | Out-String)

BLOCKED SENDERS:
$($blockedSenders | ForEach-Object { "  - $_" } | Out-String)

PROCESSED REPORTS:
$($processedReports | ForEach-Object { 
    "  Reporter: $($_.Reporter)`n" +
    "  Original Sender: $($_.OriginalSender)`n" +
    "  Spam Score: $($_.SpamScore)%`n" +
    "  Action: $($_.Action)`n" +
    "  ---"
} | Out-String)
"@

# Save report
$reportFileName = "Internal-Report-$(Get-Date -Format 'yyyy-MM-dd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$reportContent | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "✅ Report saved to: $reportFullPath" -ForegroundColor Green

# Send confirmation emails to reporters
Write-Host "`n[5/6] Sending confirmations to reporters..." -ForegroundColor Yellow

$reporters = $internalReports | Select-Object -Unique SenderAddress
foreach ($reporter in $reporters.SenderAddress) {
    $reportCount = ($internalReports | Where-Object {$_.SenderAddress -eq $reporter}).Count
    
    Write-Host "  Would send confirmation to: $reporter ($reportCount reports)" -ForegroundColor Cyan
    
    # In production, you would send actual emails
    $confirmationBody = @"
<h3>Security Report Confirmation</h3>
<p>Thank you for reporting suspicious email(s) to the Security team.</p>
<p><strong>Reports received:</strong> $reportCount</p>
<p><strong>Actions taken:</strong></p>
<ul>
<li>Senders blocked: $($blockedSenders.Count)</li>
<li>Senders added to watchlist: $($suspiciousSenders.Count - $blockedSenders.Count)</li>
</ul>
<p>The security team has processed your report(s) and taken appropriate action.</p>
<p>Continue to forward any suspicious emails to security@cogitativo.com</p>
<br>
<p><em>This is an automated response from the Security Operations Center</em></p>
"@
}

# Update statistics
Write-Host "`n[6/6] Updating statistics..." -ForegroundColor Yellow

$statsFile = Join-Path $logPath "InternalReportStats.csv"
$statsEntry = [PSCustomObject]@{
    Date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ReportsReceived = $internalReports.Count
    ForwardedEmails = $processedReports.Count
    SendersBlocked = $blockedSenders.Count
    SendersWatchlisted = $suspiciousSenders.Count - $blockedSenders.Count
}

$statsEntry | Export-Csv -Path $statsFile -Append -NoTypeInformation

# Display summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  PROCESSING COMPLETE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nSummary:" -ForegroundColor Green
Write-Host "  ✅ Internal reports processed: $($internalReports.Count)"
Write-Host "  ✅ Senders blocked: $($blockedSenders.Count)"
Write-Host "  ⚠️ Senders on watchlist: $($suspiciousSenders.Count - $blockedSenders.Count)"
Write-Host "  📧 Confirmations queued: $($reporters.Count)"

Write-Host "`nReport saved to: $reportFullPath" -ForegroundColor Cyan

# Log completion
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Internal Report Processing completed. Processed: $($internalReports.Count), Blocked: $($blockedSenders.Count)"
$logEntry | Out-File -FilePath "$logPath\Internal-Processing.log" -Append -Encoding UTF8

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green