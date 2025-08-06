# SETUP INBOX RULES FOR SECURITY MAILBOX
# Creates rules to automatically sort incoming emails

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SETTING UP INBOX RULES" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "Connected!" -ForegroundColor Green

# Check existing rules
Write-Host "`nChecking existing inbox rules..." -ForegroundColor Yellow
$existingRules = Get-InboxRule -Mailbox security@cogitativo.com
Write-Host "Found $($existingRules.Count) existing rules" -ForegroundColor Cyan

# Create DMARC rule
Write-Host "`n[1/5] Creating DMARC rule..." -ForegroundColor Yellow
$dmarcRule = Get-InboxRule -Mailbox security@cogitativo.com -Identity "DMARC-Sorter" -ErrorAction SilentlyContinue
if (!$dmarcRule) {
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "DMARC-Sorter" `
                  -SubjectContainsWords "Report domain","DMARC" `
                  -MoveToFolder "security@cogitativo.com:\1-DMARC" `
                  -StopProcessingRules $false
    Write-Host "  Created DMARC sorting rule" -ForegroundColor Green
} else {
    Write-Host "  DMARC rule already exists" -ForegroundColor Gray
}

# Create Phishing rule
Write-Host "[2/5] Creating Phishing rule..." -ForegroundColor Yellow
$phishRule = Get-InboxRule -Mailbox security@cogitativo.com -Identity "Phishing-Sorter" -ErrorAction SilentlyContinue
if (!$phishRule) {
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Phishing-Sorter" `
                  -SubjectOrBodyContainsWords "phish","suspicious email" `
                  -MoveToFolder "security@cogitativo.com:\2-Phishing" `
                  -StopProcessingRules $false
    Write-Host "  Created Phishing sorting rule" -ForegroundColor Green
} else {
    Write-Host "  Phishing rule already exists" -ForegroundColor Gray
}

# Create DLP rule
Write-Host "[3/5] Creating DLP rule..." -ForegroundColor Yellow
$dlpRule = Get-InboxRule -Mailbox security@cogitativo.com -Identity "DLP-Sorter" -ErrorAction SilentlyContinue
if (!$dlpRule) {
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "DLP-Sorter" `
                  -SubjectContainsWords "DLP","Data Loss Prevention" `
                  -MoveToFolder "security@cogitativo.com:\3-DLP-Incidents" `
                  -StopProcessingRules $false
    Write-Host "  Created DLP sorting rule" -ForegroundColor Green
} else {
    Write-Host "  DLP rule already exists" -ForegroundColor Gray
}

# Create Spam rule
Write-Host "[4/5] Creating Spam rule..." -ForegroundColor Yellow
$spamRule = Get-InboxRule -Mailbox security@cogitativo.com -Identity "Spam-Sorter" -ErrorAction SilentlyContinue
if (!$spamRule) {
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Spam-Sorter" `
                  -SubjectContainsWords "spam","junk mail" `
                  -MoveToFolder "security@cogitativo.com:\4-Spam" `
                  -StopProcessingRules $false
    Write-Host "  Created Spam sorting rule" -ForegroundColor Green
} else {
    Write-Host "  Spam rule already exists" -ForegroundColor Gray
}

# Create Archive rule
Write-Host "[5/5] Creating Archive rule..." -ForegroundColor Yellow
$archiveRule = Get-InboxRule -Mailbox security@cogitativo.com -Identity "Auto-Archive-30Days" -ErrorAction SilentlyContinue
if (!$archiveRule) {
    $date30DaysAgo = (Get-Date).AddDays(-30)
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Auto-Archive-30Days" `
                  -ReceivedBeforeDate $date30DaysAgo `
                  -MoveToFolder "security@cogitativo.com:\7-Archive\2024" `
                  -StopProcessingRules $true
    Write-Host "  Created Archive rule for emails older than 30 days" -ForegroundColor Green
} else {
    Write-Host "  Archive rule already exists" -ForegroundColor Gray
}

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  INBOX RULES SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$allRules = Get-InboxRule -Mailbox security@cogitativo.com
Write-Host "`nActive inbox rules ($($allRules.Count) total):" -ForegroundColor Green
$allRules | ForEach-Object {
    Write-Host "  - $($_.Name): $($_.Description.Substring(0, [Math]::Min(50, $_.Description.Length)))..."
}

Write-Host "`nThese rules will automatically sort NEW incoming emails" -ForegroundColor Yellow
Write-Host "For existing emails, manual processing is needed" -ForegroundColor Yellow

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Complete!" -ForegroundColor Green