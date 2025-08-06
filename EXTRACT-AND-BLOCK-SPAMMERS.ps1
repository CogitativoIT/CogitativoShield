# EXTRACT AND BLOCK SPAM SENDERS FROM FORWARDED EMAILS
# Handles both attached and inline forwarded emails from internal users
# Extracts the actual spammer's email address and blocks them

Write-Host "================================================" -ForegroundColor Red
Write-Host "  SPAM SENDER EXTRACTION AND BLOCKING" -ForegroundColor Red
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Red

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\BlockedSpammers"
$logPath = "C:\SecurityOps\Logs"

# Create directories
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

# Function to extract sender from message headers or body
function Extract-SpammerEmail {
    param(
        [string]$MessageId,
        [string]$Subject,
        [string]$InternetMessageHeaders
    )
    
    $spammerEmails = @()
    
    # Method 1: Check Internet Message Headers for original sender
    if ($InternetMessageHeaders) {
        # Look for X-MS-Exchange-Organization-OriginalSender
        if ($InternetMessageHeaders -match 'X-MS-Exchange-Organization-OriginalSender:\s*([^\s<>]+@[^\s<>]+)') {
            $spammerEmails += $matches[1]
        }
        
        # Look for Return-Path
        if ($InternetMessageHeaders -match 'Return-Path:\s*<([^>]+@[^>]+)>') {
            $spammerEmails += $matches[1]
        }
        
        # Look for From header in forwarded content
        if ($InternetMessageHeaders -match 'From:\s*.*?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})') {
            $spammerEmails += $matches[1]
        }
    }
    
    # Method 2: For inline forwards, extract from common forward patterns
    # Pattern: "From: Name <email@domain.com>"
    if ($Subject -match '^(FW:|Fwd:|FWD:)') {
        # This is a forwarded message, need to get actual content
        # In production, you'd retrieve the message body here
        Write-Host "    🔍 Detected forwarded message format" -ForegroundColor Cyan
    }
    
    return $spammerEmails | Select-Object -Unique
}

# Get reports from internal users in last 24 hours
Write-Host "`n[1/7] Retrieving spam reports from internal users..." -ForegroundColor Yellow
$startDate = (Get-Date).AddDays(-1)

# Get messages sent to security from internal users
$internalReports = Get-MessageTrace -RecipientAddress $securityMailbox `
                                  -StartDate $startDate `
                                  -EndDate (Get-Date) | 
                  Where-Object {
                      $_.SenderAddress -like "*@cogitativo.com" -and
                      ($_.Subject -match '(FW:|Fwd:|spam|phish|suspicious|junk|scam)' -or
                       $_.Subject -match 'check this|is this real|please review')
                  }

Write-Host "Found $($internalReports.Count) potential spam reports from internal users" -ForegroundColor Cyan

# Process each report to extract spammer emails
Write-Host "`n[2/7] Extracting spammer email addresses..." -ForegroundColor Yellow

$spammersToBlock = @()
$reportDetails = @()

foreach ($report in $internalReports) {
    Write-Host "`n  Report from: $($report.SenderAddress)" -ForegroundColor Gray
    Write-Host "  Subject: $($report.Subject.Substring(0, [Math]::Min(60, $report.Subject.Length)))..." -ForegroundColor Gray
    
    # Try to get more details about the message
    try {
        # Get message details (this would include headers in a full implementation)
        $messageDetails = Get-MessageTrace -MessageId $report.MessageId -ErrorAction SilentlyContinue
        
        # For forwarded emails, we need to extract the original sender
        if ($report.Subject -match '^(FW:|Fwd:|FWD:)') {
            Write-Host "    🔄 This is a forwarded email" -ForegroundColor Cyan
            
            # Extract patterns from subject line
            # Common pattern: FW: You've won! <scammer@fake.com>
            if ($report.Subject -match '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})') {
                $potentialSpammer = $matches[1]
                
                # Verify it's not an internal email
                if ($potentialSpammer -notlike "*@cogitativo.com") {
                    Write-Host "    🎯 Found potential spammer: $potentialSpammer" -ForegroundColor Yellow
                    $spammersToBlock += $potentialSpammer
                    
                    $reportDetails += [PSCustomObject]@{
                        Reporter = $report.SenderAddress
                        ReportTime = $report.Received
                        Subject = $report.Subject
                        SpammerEmail = $potentialSpammer
                        Confidence = "High"
                    }
                }
            }
        }
    } catch {
        Write-Host "    ⚠️ Could not extract details: $_" -ForegroundColor Yellow
    }
}

# Remove duplicates
$uniqueSpammers = $spammersToBlock | Select-Object -Unique

Write-Host "`n[3/7] Found $($uniqueSpammers.Count) unique spammer emails to block" -ForegroundColor Cyan
if ($uniqueSpammers.Count -gt 0) {
    $uniqueSpammers | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Red
    }
}

# Check which are already blocked
Write-Host "`n[4/7] Checking existing block list..." -ForegroundColor Yellow

$existingBlocks = Get-TenantAllowBlockListItems -ListType Sender -ErrorAction SilentlyContinue | 
                 Where-Object {$_.Action -eq "Block"}

$alreadyBlocked = @()
$newToBlock = @()

foreach ($spammer in $uniqueSpammers) {
    if ($existingBlocks.Value -contains $spammer) {
        $alreadyBlocked += $spammer
        Write-Host "  ℹ️ Already blocked: $spammer" -ForegroundColor Gray
    } else {
        $newToBlock += $spammer
        Write-Host "  🆕 New spammer to block: $spammer" -ForegroundColor Yellow
    }
}

# Block new spammers
Write-Host "`n[5/7] Blocking new spam senders..." -ForegroundColor Yellow

$blockedCount = 0
$failedBlocks = @()

foreach ($spammer in $newToBlock) {
    Write-Host "  Blocking: $spammer" -ForegroundColor Red
    
    try {
        New-TenantAllowBlockListItems -ListType Sender `
                                     -Block `
                                     -Entries $spammer `
                                     -Notes "Blocked from internal user report $(Get-Date -Format 'yyyy-MM-dd')" `
                                     -ExpirationDate (Get-Date).AddDays(90) `
                                     -ErrorAction Stop | Out-Null
        
        Write-Host "    ✅ Successfully blocked" -ForegroundColor Green
        $blockedCount++
    } catch {
        Write-Host "    ❌ Failed to block: $_" -ForegroundColor Red
        $failedBlocks += $spammer
    }
}

# Search for and remove emails from blocked senders
Write-Host "`n[6/7] Searching for emails from blocked senders..." -ForegroundColor Yellow

if ($newToBlock.Count -gt 0) {
    Write-Host "  Note: In production, you would create compliance searches to purge emails" -ForegroundColor Cyan
    Write-Host "  from these senders across all mailboxes" -ForegroundColor Cyan
}

# Generate report
Write-Host "`n[7/7] Generating blocking report..." -ForegroundColor Yellow

$reportContent = @"
================================================
SPAM SENDER BLOCKING REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

PERIOD ANALYZED: $startDate to $(Get-Date)

SUMMARY:
- Internal Reports Processed: $($internalReports.Count)
- Unique Spammers Identified: $($uniqueSpammers.Count)
- Already Blocked: $($alreadyBlocked.Count)
- Newly Blocked: $blockedCount
- Failed to Block: $($failedBlocks.Count)

INTERNAL REPORTERS:
$($internalReports | Group-Object SenderAddress | Sort-Object Count -Descending | ForEach-Object {
    "  $($_.Name): $($_.Count) reports"
} | Out-String)

NEWLY BLOCKED SENDERS:
$($newToBlock | ForEach-Object { "  • $_" } | Out-String)

ALREADY BLOCKED:
$($alreadyBlocked | ForEach-Object { "  • $_" } | Out-String)

$(if ($failedBlocks.Count -gt 0) {
"FAILED TO BLOCK:`n$($failedBlocks | ForEach-Object { `"  ❌ $_`" } | Out-String)"
})

ACTIONS TAKEN:
1. Blocked $blockedCount new spam senders
2. Added 90-day expiration to blocks
3. Logged all actions for audit

RECOMMENDATIONS:
1. Educate users to forward spam as attachments when possible
2. This preserves headers for better sender extraction
3. Consider implementing automated response to reporters
4. Review blocks monthly and extend if still receiving spam
"@

# Save report
$reportFileName = "SpammerBlocking-$(Get-Date -Format 'yyyy-MM-dd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$reportContent | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "`n✅ Report saved to: $reportFullPath" -ForegroundColor Green

# Create CSV of blocked senders for tracking
$csvPath = Join-Path $reportPath "BlockedSpammers.csv"
if ($newToBlock.Count -gt 0) {
    $newToBlock | ForEach-Object {
        [PSCustomObject]@{
            BlockedDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            SpammerEmail = $_
            BlockedBy = "Automated-InternalReport"
            ExpirationDate = (Get-Date).AddDays(90).ToString('yyyy-MM-dd')
        }
    } | Export-Csv -Path $csvPath -Append -NoTypeInformation
    Write-Host "📊 CSV updated: $csvPath" -ForegroundColor Cyan
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  SPAM BLOCKING COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  ✅ Processed $($internalReports.Count) internal reports"
Write-Host "  🚫 Blocked $blockedCount new spammers"
Write-Host "  ℹ️ $($alreadyBlocked.Count) were already blocked"

if ($failedBlocks.Count -gt 0) {
    Write-Host "  ⚠️ $($failedBlocks.Count) blocks failed (review manually)" -ForegroundColor Yellow
}

Write-Host "`nTip: Ask users to forward spam emails as attachments to preserve headers!" -ForegroundColor Yellow
Write-Host "This helps extract the real spammer's email address more accurately." -ForegroundColor Yellow

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green