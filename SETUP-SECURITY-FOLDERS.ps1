# SETUP SECURITY MAILBOX FOLDERS
# Creates organized folder structure for security@cogitativo.com

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SETTING UP SECURITY MAILBOX FOLDERS" -ForegroundColor Cyan  
Write-Host "================================================" -ForegroundColor Cyan

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# Create folder structure using simple commands
Write-Host "`n[1/7] Creating DMARC folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\1-DMARC" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 1-DMARC" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 1-DMARC already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\1-DMARC\Processed" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 1-DMARC\Processed" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 1-DMARC\Processed already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\1-DMARC\Failed" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 1-DMARC\Failed" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 1-DMARC\Failed already exists" -ForegroundColor Gray
}

Write-Host "`n[2/7] Creating Phishing folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\2-Phishing" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 2-Phishing" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 2-Phishing already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\2-Phishing\User-Reported" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 2-Phishing\User-Reported" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 2-Phishing\User-Reported already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\2-Phishing\Confirmed" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 2-Phishing\Confirmed" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 2-Phishing\Confirmed already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\2-Phishing\False-Positive" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 2-Phishing\False-Positive" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 2-Phishing\False-Positive already exists" -ForegroundColor Gray
}

Write-Host "`n[3/7] Creating DLP folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\3-DLP-Incidents" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 3-DLP-Incidents" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 3-DLP-Incidents already exists" -ForegroundColor Gray
}

Write-Host "`n[4/7] Creating Spam folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\4-Spam" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 4-Spam" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 4-Spam already exists" -ForegroundColor Gray
}

Write-Host "`n[5/7] Creating Abuse folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\5-Abuse" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 5-Abuse" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 5-Abuse already exists" -ForegroundColor Gray
}

Write-Host "`n[6/7] Creating Reports folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\6-Reports" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 6-Reports" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 6-Reports already exists" -ForegroundColor Gray
}

Write-Host "`n[7/7] Creating Archive folders..." -ForegroundColor Yellow
try {
    New-MailboxFolder -Path "security@cogitativo.com:\7-Archive" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 7-Archive" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 7-Archive already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\7-Archive\2024" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 7-Archive\2024" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 7-Archive\2024 already exists" -ForegroundColor Gray
}

try {
    New-MailboxFolder -Path "security@cogitativo.com:\7-Archive\2025" -ErrorAction SilentlyContinue
    Write-Host "  ✅ Created 7-Archive\2025" -ForegroundColor Green
} catch {
    Write-Host "  ℹ️ 7-Archive\2025 already exists" -ForegroundColor Gray
}

# Check folder statistics
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  FOLDER STRUCTURE SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$stats = Get-MailboxFolderStatistics -Identity security@cogitativo.com | Select-Object Name, ItemsInFolder, FolderSize

Write-Host "`nKey folders:" -ForegroundColor Green
$stats | Where-Object {$_.Name -match "^[1-7]-" -or $_.Name -eq "Inbox" -or $_.Name -eq "Azure notices"} | ForEach-Object {
    Write-Host "  $($_.Name): $($_.ItemsInFolder) items"
}

Write-Host "`n✅ Folder structure ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Current Inbox status:" -ForegroundColor Yellow
$inbox = $stats | Where-Object {$_.Name -eq "Inbox"}
Write-Host "  Inbox has $($inbox.ItemsInFolder) items that need to be organized" -ForegroundColor Yellow

Write-Host "`nNext step: Run ORGANIZE-EXISTING-EMAILS.ps1 to sort existing emails" -ForegroundColor Cyan

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green