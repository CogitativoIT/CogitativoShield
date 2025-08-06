# EXTRACT AND BLOCK SPAMMERS FROM FORWARDED EMAILS
# Processes emails forwarded by internal users to extract and block spam senders

Write-Host "================================================" -ForegroundColor Red
Write-Host "  SPAMMER EXTRACTION AND BLOCKING" -ForegroundColor Red
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Red

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\BlockedSpammers"
$logPath = "C:\SecurityOps\Logs"

# Create directories
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
    Write-Host "Created directory: $reportPath" -ForegroundColor Green
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

# Get reports from internal users
Write-Host "`n[1/5] Searching for forwarded spam reports..." -ForegroundColor Yellow
$startDate = (Get-Date).AddDays(-7)

$internalReports = Get-MessageTrace -RecipientAddress $securityMailbox `
                                  -StartDate $startDate `
                                  -EndDate (Get-Date) | 
                  Where-Object {
                      $_.SenderAddress -like "*@cogitativo.com" -and
                      $_.Subject -match "(FW:|Fwd:|spam|phish|suspicious|junk|scam)"
                  }

Write-Host "Found $($internalReports.Count) potential spam reports from internal users" -ForegroundColor Cyan

# Extract potential spammer emails
Write-Host "`n[2/5] Extracting spammer email addresses..." -ForegroundColor Yellow

$spammersToBlock = @()
$reporters = @{}

foreach ($report in $internalReports) {
    Write-Host "`n  From: $($report.SenderAddress)" -ForegroundColor Gray
    
    # Track reporter
    if (!$reporters.ContainsKey($report.SenderAddress)) {
        $reporters[$report.SenderAddress] = 1
    } else {
        $reporters[$report.SenderAddress]++
    }
    
    # For forwarded emails, try to extract email addresses from subject
    if ($report.Subject -match '^(FW:|Fwd:|FWD:)') {
        Write-Host "  📧 Forwarded email detected" -ForegroundColor Cyan
        
        # Extract email pattern from subject
        # Common patterns: email addresses in subject lines
        $emailPattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
        $matches = [regex]::Matches($report.Subject, $emailPattern)
        
        foreach ($match in $matches) {
            $email = $match.Value
            # Don't block internal emails
            if ($email -notlike "*@cogitativo.com") {
                Write-Host "    🎯 Found potential spammer: $email" -ForegroundColor Yellow
                $spammersToBlock += $email
            }
        }
    }
}

# Remove duplicates
$uniqueSpammers = $spammersToBlock | Select-Object -Unique

Write-Host "`n[3/5] Identified $($uniqueSpammers.Count) unique spammer emails" -ForegroundColor Cyan
if ($uniqueSpammers.Count -gt 0) {
    $uniqueSpammers | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Red
    }
}

# Check existing blocks
Write-Host "`n[4/5] Checking and blocking spammers..." -ForegroundColor Yellow

$blockedCount = 0
$alreadyBlocked = 0
$failedBlocks = @()

foreach ($spammer in $uniqueSpammers) {
    Write-Host "`n  Processing: $spammer" -ForegroundColor Gray
    
    # Check if already blocked
    $existingBlock = Get-TenantAllowBlockListItems -ListType Sender -ErrorAction SilentlyContinue | 
                    Where-Object {$_.Value -eq $spammer -and $_.Action -eq "Block"}
    
    if ($existingBlock) {
        Write-Host "    ℹ️ Already blocked" -ForegroundColor Gray
        $alreadyBlocked++
    } else {
        # Block the spammer
        try {
            New-TenantAllowBlockListItems -ListType Sender `
                                         -Block `
                                         -Entries $spammer `
                                         -Notes "Blocked from internal report $(Get-Date -Format 'yyyy-MM-dd')" `
                                         -ExpirationDate (Get-Date).AddDays(90) `
                                         -ErrorAction Stop | Out-Null
            
            Write-Host "    ✅ Successfully blocked" -ForegroundColor Green
            $blockedCount++
        } catch {
            Write-Host "    ❌ Failed to block: $_" -ForegroundColor Red
            $failedBlocks += $spammer
        }
    }
}

# Generate report
Write-Host "`n[5/5] Generating report..." -ForegroundColor Yellow

$reportContent = @"
================================================
SPAMMER BLOCKING REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

PERIOD ANALYZED: $startDate to $(Get-Date)

SUMMARY:
- Internal Reports Processed: $($internalReports.Count)
- Unique Spammers Identified: $($uniqueSpammers.Count)
- Newly Blocked: $blockedCount
- Already Blocked: $alreadyBlocked
- Failed to Block: $($failedBlocks.Count)

TOP REPORTERS:
$($reporters.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
    "  $($_.Key): $($_.Value) reports"
} | Out-String)

BLOCKED SPAMMERS:
$(if ($uniqueSpammers.Count -gt 0) {
    $uniqueSpammers | ForEach-Object { "  • $_" } | Out-String
} else {
    "  None found"
})

RECOMMENDATIONS:
1. Ask users to forward spam emails as ATTACHMENTS
   This preserves email headers for better extraction
2. Use subject: "FW: Spam" or "FW: Phishing"
3. Don't modify the forwarded email content
4. Include brief description if needed

TIP FOR USERS:
In Outlook: 
- Select the spam email
- Click "More actions" (...)
- Choose "Forward as attachment"
- Send to security@cogitativo.com
"@

# Save report
$reportFileName = "SpammerBlocking-$(Get-Date -Format 'yyyy-MM-dd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$reportContent | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "`n✅ Report saved to: $reportFullPath" -ForegroundColor Green

# Save blocked list to CSV
if ($blockedCount -gt 0) {
    $csvPath = Join-Path $reportPath "BlockedSpammers.csv"
    $uniqueSpammers | Where-Object {$_ -notin $failedBlocks} | ForEach-Object {
        [PSCustomObject]@{
            BlockedDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            SpammerEmail = $_
            BlockedBy = "InternalReport"
            ExpirationDate = (Get-Date).AddDays(90).ToString('yyyy-MM-dd')
        }
    } | Export-Csv -Path $csvPath -Append -NoTypeInformation
    Write-Host "📊 CSV updated: $csvPath" -ForegroundColor Cyan
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  BLOCKING COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  ✅ Processed: $($internalReports.Count) reports"
Write-Host "  🚫 Blocked: $blockedCount new spammers"
Write-Host "  ℹ️ Already blocked: $alreadyBlocked"

if ($failedBlocks.Count -gt 0) {
    Write-Host "  ⚠️ Failed: $($failedBlocks.Count)" -ForegroundColor Yellow
}

Write-Host "`nIMPORTANT:" -ForegroundColor Yellow
Write-Host "Ask users to forward spam as ATTACHMENTS to security@cogitativo.com" -ForegroundColor Yellow
Write-Host "This preserves headers and makes extraction more accurate!" -ForegroundColor Yellow

# Disconnect
Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green