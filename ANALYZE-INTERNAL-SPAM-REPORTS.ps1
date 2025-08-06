# ANALYZE INTERNAL SPAM REPORTS IN SECURITY MAILBOX
# Identifies patterns in emails forwarded by internal users

Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  INTERNAL SPAM REPORT ANALYSIS" -ForegroundColor Yellow
Write-Host "  $(Get-Date)" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Yellow

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

# Analyze messages from internal users
Write-Host "`n[1/5] Analyzing emails from internal @cogitativo.com users..." -ForegroundColor Yellow

$startDate = (Get-Date).AddDays(-30)
$endDate = Get-Date

# Get messages from internal users
$internalMessages = Get-MessageTrace -RecipientAddress security@cogitativo.com `
                                   -StartDate $startDate `
                                   -EndDate $endDate | 
                   Where-Object {$_.SenderAddress -like "*@cogitativo.com"}

Write-Host "Found $($internalMessages.Count) emails from internal users in last 30 days" -ForegroundColor Cyan

# Analyze subject patterns
Write-Host "`n[2/5] Analyzing subject line patterns..." -ForegroundColor Yellow

$subjectPatterns = @{
    "FW:" = 0
    "Fwd:" = 0
    "SPAM" = 0
    "Suspicious" = 0
    "Phishing" = 0
    "Scam" = 0
    "Virus" = 0
    "Malware" = 0
    "Junk" = 0
    "Fraud" = 0
    "Is this legitimate" = 0
    "Please check" = 0
    "FYI" = 0
    "Heads up" = 0
}

foreach ($msg in $internalMessages) {
    foreach ($pattern in $subjectPatterns.Keys) {
        if ($msg.Subject -match $pattern) {
            $subjectPatterns[$pattern]++
        }
    }
}

Write-Host "`nTop subject patterns from internal users:" -ForegroundColor Cyan
$subjectPatterns.GetEnumerator() | Sort-Object Value -Descending | Where-Object {$_.Value -gt 0} | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value) occurrences" -ForegroundColor White
}

# Identify top internal reporters
Write-Host "`n[3/5] Identifying top internal reporters..." -ForegroundColor Yellow

$reporters = $internalMessages | Group-Object SenderAddress | Sort-Object Count -Descending | Select-Object -First 10

Write-Host "`nTop 10 internal users reporting to security:" -ForegroundColor Cyan
$reporters | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) reports" -ForegroundColor White
}

# Analyze forwarded email patterns
Write-Host "`n[4/5] Checking for forwarded email indicators..." -ForegroundColor Yellow

$forwardedCount = ($internalMessages | Where-Object {$_.Subject -match "^(FW:|Fwd:|RE: FW:|RE: Fwd:)"}).Count
$percentForwarded = if ($internalMessages.Count -gt 0) { [Math]::Round(($forwardedCount / $internalMessages.Count) * 100, 2) } else { 0 }

Write-Host "  $forwardedCount of $($internalMessages.Count) emails ($percentForwarded%) appear to be forwarded" -ForegroundColor Cyan

# Check for common spam/phishing keywords in subjects
Write-Host "`n[5/5] Analyzing spam/phishing keywords..." -ForegroundColor Yellow

$spamKeywords = @(
    "lottery", "winner", "congratulations", "claim", "prize",
    "urgent", "verify", "suspend", "account", "click here",
    "limited time", "act now", "expires", "invoice", "payment",
    "refund", "tax", "IRS", "government", "arrest",
    "virus", "infected", "security alert", "Microsoft", "Apple",
    "Amazon", "Netflix", "PayPal", "bank", "credit card",
    "social security", "inheritance", "beneficiary", "million",
    "bitcoin", "cryptocurrency", "investment", "offer"
)

$keywordHits = @{}
foreach ($keyword in $spamKeywords) {
    $count = ($internalMessages | Where-Object {$_.Subject -match $keyword}).Count
    if ($count -gt 0) {
        $keywordHits[$keyword] = $count
    }
}

if ($keywordHits.Count -gt 0) {
    Write-Host "`nCommon spam/phishing keywords found:" -ForegroundColor Cyan
    $keywordHits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host "  '$($_.Key)': $($_.Value) occurrences" -ForegroundColor White
    }
} else {
    Write-Host "  No common spam keywords found in subject lines" -ForegroundColor Gray
}

# Generate recommendations
Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host "  ANALYSIS SUMMARY" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

Write-Host "`nKey Findings:" -ForegroundColor Cyan
Write-Host "  • $($internalMessages.Count) emails from internal users in 30 days" -ForegroundColor White
Write-Host "  • $forwardedCount emails were forwarded ($percentForwarded%)" -ForegroundColor White
Write-Host "  • $($reporters.Count) unique internal reporters" -ForegroundColor White

Write-Host "`nRecommended Mail Flow Rules:" -ForegroundColor Green
Write-Host "  1. Create rule for 'FW:/Fwd:' from @cogitativo.com → Category: Internal-Forward"
Write-Host "  2. Create rule for spam keywords from @cogitativo.com → Category: Internal-Spam-Report"
Write-Host "  3. Create rule for 'suspicious/phishing' from @cogitativo.com → Priority: High"
Write-Host "  4. Auto-extract original sender from forwarded emails for analysis"

Write-Host "`nRecommended Actions:" -ForegroundColor Green
Write-Host "  1. Process forwarded emails to extract original sender"
Write-Host "  2. Auto-analyze forwarded content for phishing indicators"
Write-Host "  3. Block original senders if confidence score > 70%"
Write-Host "  4. Send confirmation to internal reporter"
Write-Host "  5. Add original sender domain to watchlist"

# Disconnect
Write-Host "`nDisconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Analysis complete!" -ForegroundColor Green