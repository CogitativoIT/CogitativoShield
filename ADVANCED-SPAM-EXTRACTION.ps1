# ADVANCED SPAM EXTRACTION WITH BODY SEARCH
# Uses compliance search to find and extract spammer emails from message bodies

Write-Host "================================================" -ForegroundColor Red
Write-Host "  ADVANCED SPAMMER EXTRACTION WITH BODY SEARCH" -ForegroundColor Red
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Red

# Configuration
$securityMailbox = "security@cogitativo.com"
$reportPath = "C:\SecurityOps\BlockedSpammers"

# Create directory
if (!(Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}

# Connect to Exchange Online and Security & Compliance
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false -ErrorAction Stop
    Connect-IPPSSession -UserPrincipalName andre.darby@cogitativo.com -ErrorAction Stop
    Write-Host "✅ Connected to Exchange and Compliance Center" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

# Create a compliance search to find forwarded emails
Write-Host "`n[1/5] Creating compliance search for forwarded spam..." -ForegroundColor Yellow

$searchName = "SpamExtraction-$(Get-Date -Format 'yyyyMMdd-HHmm')"

# Search for forwarded emails from internal users
$searchQuery = "(to:security@cogitativo.com) AND (from:*@cogitativo.com) AND (subject:FW OR subject:Fwd OR subject:spam OR subject:phishing)"

try {
    # Remove any existing search with same name
    Remove-ComplianceSearch -Identity $searchName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create new search
    New-ComplianceSearch -Name $searchName `
                        -ExchangeLocation $securityMailbox `
                        -ContentMatchQuery $searchQuery `
                        -ErrorAction Stop | Out-Null
    
    Write-Host "✅ Compliance search created" -ForegroundColor Green
    
    # Start the search
    Start-ComplianceSearch -Identity $searchName -Force -ErrorAction SilentlyContinue
    
    # Wait for search to complete
    Write-Host "  Waiting for search to complete..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    $searchStatus = Get-ComplianceSearch -Identity $searchName
    Write-Host "  Search status: $($searchStatus.Status)" -ForegroundColor Gray
    Write-Host "  Items found: $($searchStatus.Items)" -ForegroundColor Cyan
    
} catch {
    Write-Host "⚠️ Compliance search not available, using message trace only" -ForegroundColor Yellow
}

# Use message trace as primary method
Write-Host "`n[2/5] Analyzing forwarded emails..." -ForegroundColor Yellow

$internalReports = Get-MessageTrace -RecipientAddress $securityMailbox `
                                  -StartDate (Get-Date).AddDays(-7) `
                                  -EndDate (Get-Date) | 
                  Where-Object {
                      $_.SenderAddress -like "*@cogitativo.com" -and
                      ($_.Subject -match '(FW:|Fwd:|spam|phish|suspicious|junk|scam)')
                  }

Write-Host "Found $($internalReports.Count) forwarded reports from internal users" -ForegroundColor Cyan

# Extract spammer emails
Write-Host "`n[3/5] Extracting spammer email addresses..." -ForegroundColor Yellow

$spammersToBlock = @()

foreach ($report in $internalReports) {
    Write-Host "`n  From: $($report.SenderAddress)" -ForegroundColor Gray
    
    # Extract email addresses from subject
    $emailPattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    $matches = [regex]::Matches($report.Subject, $emailPattern)
    
    foreach ($match in $matches) {
        $email = $match.Value
        if ($email -notlike "*@cogitativo.com" -and 
            $email -notlike "*@microsoft.com" -and
            $email -notlike "*@outlook.com") {
            Write-Host "    🎯 Found: $email" -ForegroundColor Yellow
            $spammersToBlock += $email
        }
    }
}

# Get unique spammers
$uniqueSpammers = $spammersToBlock | Select-Object -Unique

Write-Host "`n[4/5] Blocking $($uniqueSpammers.Count) spammers..." -ForegroundColor Yellow

$blockedCount = 0
foreach ($spammer in $uniqueSpammers) {
    Write-Host "  Blocking: $spammer" -ForegroundColor Red -NoNewline
    
    try {
        New-TenantAllowBlockListItems -ListType Sender `
                                     -Block `
                                     -Entries $spammer `
                                     -Notes "From internal report" `
                                     -ExpirationDate (Get-Date).AddDays(90) `
                                     -ErrorAction Stop | Out-Null
        
        Write-Host " - BLOCKED" -ForegroundColor Green
        $blockedCount++
    } catch {
        if ($_ -match "already exists") {
            Write-Host " - Already blocked" -ForegroundColor Gray
        } else {
            Write-Host " - Failed" -ForegroundColor Red
        }
    }
}

# Generate report
Write-Host "`n[5/5] Generating report..." -ForegroundColor Yellow

$reportContent = @"
SPAM EXTRACTION REPORT - $(Get-Date -Format 'yyyy-MM-dd HH:mm')
================================================

RESULTS:
• Internal reports analyzed: $($internalReports.Count)
• Unique spammers found: $($uniqueSpammers.Count)
• Successfully blocked: $blockedCount

IMPORTANT:
To extract spammers from email BODY (not just subject):
1. Users must forward spam as ATTACHMENTS
2. This preserves headers and body content
3. Allows automatic extraction of real sender

HOW TO FORWARD AS ATTACHMENT:
1. Select spam email in Outlook
2. Click (...) → Forward as Attachment
3. Send to: security@cogitativo.com
"@

$reportFileName = "SpamExtraction-$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
$reportFullPath = Join-Path $reportPath $reportFileName
$reportContent | Out-File -FilePath $reportFullPath -Encoding UTF8

Write-Host "`n📄 Report saved to: $reportFullPath" -ForegroundColor Green

# Clean up
if ($searchName) {
    Remove-ComplianceSearch -Identity $searchName -Confirm:$false -ErrorAction SilentlyContinue
}

# Display summary
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  EXTRACTION COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  • Reports analyzed: $($internalReports.Count)"
Write-Host "  • Spammers blocked: $blockedCount"

if ($uniqueSpammers.Count -eq 0) {
    Write-Host "`n⚠️ No spammer emails found!" -ForegroundColor Yellow
    Write-Host "Users need to forward spam as ATTACHMENTS" -ForegroundColor Yellow
    Write-Host "to preserve the original sender information!" -ForegroundColor Yellow
}

# Disconnect
Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green