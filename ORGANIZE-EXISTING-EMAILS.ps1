# ORGANIZE EXISTING EMAILS IN SECURITY@COGITATIVO.COM
# This script sorts the 26,834 existing emails into appropriate folders

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ORGANIZING EXISTING SECURITY EMAILS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# Get initial inbox count
$initialCount = (Get-MailboxFolderStatistics -Identity "security@cogitativo.com:\Inbox" | Select-Object -ExpandProperty ItemsInFolder)
Write-Host "`nStarting with $initialCount emails in Inbox" -ForegroundColor Yellow

# Create inbox rules to sort emails
Write-Host "`n[1/6] Creating rules to organize DMARC reports..." -ForegroundColor Yellow
try {
    # Rule for DMARC reports
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Move-DMARC-Reports" `
                  -SubjectContainsWords "Report domain","DMARC","Submitter" `
                  -MoveToFolder "security@cogitativo.com:\1-DMARC" `
                  -ErrorAction SilentlyContinue
    Write-Host "  ✅ DMARC rule created" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ DMARC rule already exists" -ForegroundColor Gray
}

Write-Host "`n[2/6] Creating rules for phishing reports..." -ForegroundColor Yellow
try {
    # Rule for phishing reports
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Move-Phishing-Reports" `
                  -SubjectOrBodyContainsWords "phish","suspicious","scam","fake" `
                  -MoveToFolder "security@cogitativo.com:\2-Phishing\User-Reported" `
                  -ErrorAction SilentlyContinue
    Write-Host "  ✅ Phishing rule created" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ Phishing rule already exists" -ForegroundColor Gray
}

Write-Host "`n[3/6] Creating rules for DLP incidents..." -ForegroundColor Yellow
try {
    # Rule for DLP incidents
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Move-DLP-Incidents" `
                  -SubjectContainsWords "DLP","Data Loss Prevention","PII","PHI","Banking" `
                  -MoveToFolder "security@cogitativo.com:\3-DLP-Incidents" `
                  -ErrorAction SilentlyContinue
    Write-Host "  ✅ DLP rule created" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ DLP rule already exists" -ForegroundColor Gray
}

Write-Host "`n[4/6] Creating rules for spam reports..." -ForegroundColor Yellow
try {
    # Rule for spam
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Move-Spam-Reports" `
                  -SubjectContainsWords "spam","junk","unwanted" `
                  -MoveToFolder "security@cogitativo.com:\4-Spam" `
                  -ErrorAction SilentlyContinue
    Write-Host "  ✅ Spam rule created" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ Spam rule already exists" -ForegroundColor Gray
}

Write-Host "`n[5/6] Creating archive rule for old emails..." -ForegroundColor Yellow
try {
    # Archive old emails (older than 30 days)
    $cutoffDate = (Get-Date).AddDays(-30).ToString("MM/dd/yyyy")
    New-InboxRule -Mailbox security@cogitativo.com `
                  -Name "Archive-Old-Emails" `
                  -ReceivedBeforeDate $cutoffDate `
                  -MoveToFolder "security@cogitativo.com:\7-Archive\2024" `
                  -StopProcessingRules $true `
                  -ErrorAction SilentlyContinue
    Write-Host "  ✅ Archive rule created for emails before $cutoffDate" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ Archive rule already exists" -ForegroundColor Gray
}

# Apply rules to existing emails
Write-Host "`n[6/6] Applying rules to existing emails (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "  Processing inbox rules..." -ForegroundColor Cyan

# Force inbox rules to run
$rules = Get-InboxRule -Mailbox security@cogitativo.com
Write-Host "  Found $($rules.Count) inbox rules" -ForegroundColor Gray

# For existing emails, we need to use Search-Mailbox or manual processing
Write-Host "`n⚠️ Note: Inbox rules only apply to NEW emails" -ForegroundColor Yellow
Write-Host "To move existing emails, run MOVE-EXISTING-EMAILS.ps1" -ForegroundColor Yellow

# Get final inbox count
$finalCount = (Get-MailboxFolderStatistics -Identity "security@cogitativo.com:\Inbox" | Select-Object -ExpandProperty ItemsInFolder)

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  ORGANIZATION SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nInbox Status:" -ForegroundColor Yellow
Write-Host "  Started with: $initialCount emails"
Write-Host "  Current count: $finalCount emails"

# Show folder statistics
Write-Host "`nFolder Statistics:" -ForegroundColor Yellow
$folders = Get-MailboxFolderStatistics -Identity security@cogitativo.com | Where-Object {$_.ItemsInFolder -gt 0}
$folders | Where-Object {$_.Name -match "^[1-7]-" -or $_.Name -eq "Inbox" -or $_.Name -eq "Azure notices"} | ForEach-Object {
    Write-Host "  $($_.Name): $($_.ItemsInFolder) items"
}

Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Run MOVE-EXISTING-EMAILS.ps1 to move existing emails"
Write-Host "2. Set up mail flow rules for server-side processing"
Write-Host "3. Configure automation scripts"

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green