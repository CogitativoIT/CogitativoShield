# CREATE FOLDER STRUCTURE FOR SECURITY@COGITATIVO.COM
# This script creates an organized folder structure for security operations

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CREATING SECURITY MAILBOX FOLDER STRUCTURE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected! Creating folders..." -ForegroundColor Green

# Function to create folder safely
function New-SecurityFolder {
    param(
        [string]$FolderPath,
        [string]$Description
    )
    
    try {
        # Check if folder exists
        $exists = Get-MailboxFolder -Identity $FolderPath -ErrorAction SilentlyContinue
        if ($exists) {
            Write-Host "  ℹ️ Folder already exists: $FolderPath" -ForegroundColor Gray
        } else {
            New-MailboxFolder -Parent $FolderPath.Substring(0, $FolderPath.LastIndexOf('\')) `
                            -Name $FolderPath.Split('\')[-1] `
                            -ErrorAction Stop
            Write-Host "  ✅ Created: $FolderPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠️ Could not create $FolderPath : $_" -ForegroundColor Yellow
    }
}

# Create main category folders
Write-Host "`n[1/5] Creating main category folders..." -ForegroundColor Yellow

# DMARC folders
New-SecurityFolder "security@cogitativo.com:\1-DMARC" "DMARC reports and authentication"
New-SecurityFolder "security@cogitativo.com:\1-DMARC\Daily-Reports" "Incoming DMARC reports"
New-SecurityFolder "security@cogitativo.com:\1-DMARC\Processed" "Successfully processed reports"
New-SecurityFolder "security@cogitativo.com:\1-DMARC\Failed" "Reports showing auth failures"
New-SecurityFolder "security@cogitativo.com:\1-DMARC\Analysis" "DMARC analysis and trends"

# Phishing folders
Write-Host "`n[2/5] Creating phishing folders..." -ForegroundColor Yellow
New-SecurityFolder "security@cogitativo.com:\2-Phishing" "Phishing reports and incidents"
New-SecurityFolder "security@cogitativo.com:\2-Phishing\User-Reported" "Reports from users"
New-SecurityFolder "security@cogitativo.com:\2-Phishing\Confirmed" "Verified phishing attempts"
New-SecurityFolder "security@cogitativo.com:\2-Phishing\False-Positive" "Legitimate emails reported"
New-SecurityFolder "security@cogitativo.com:\2-Phishing\Under-Investigation" "Pending analysis"
New-SecurityFolder "security@cogitativo.com:\2-Phishing\Blocked" "Senders that were blocked"

# DLP and Compliance folders
Write-Host "`n[3/5] Creating DLP and compliance folders..." -ForegroundColor Yellow
New-SecurityFolder "security@cogitativo.com:\3-DLP-Incidents" "Data Loss Prevention incidents"
New-SecurityFolder "security@cogitativo.com:\3-DLP-Incidents\PII-PHI" "Personal/Health information"
New-SecurityFolder "security@cogitativo.com:\3-DLP-Incidents\Banking" "Financial data incidents"
New-SecurityFolder "security@cogitativo.com:\3-DLP-Incidents\Resolved" "Resolved incidents"

# Spam and abuse folders
Write-Host "`n[4/5] Creating spam and abuse folders..." -ForegroundColor Yellow
New-SecurityFolder "security@cogitativo.com:\4-Spam" "Spam reports"
New-SecurityFolder "security@cogitativo.com:\4-Spam\Reported" "User-reported spam"
New-SecurityFolder "security@cogitativo.com:\4-Spam\Blocked" "Blocked spam senders"

New-SecurityFolder "security@cogitativo.com:\5-Abuse" "Abuse reports"
New-SecurityFolder "security@cogitativo.com:\5-Abuse\External" "Reports from external sources"
New-SecurityFolder "security@cogitativo.com:\5-Abuse\Internal" "Internal abuse reports"

# Archive and reporting folders
Write-Host "`n[5/5] Creating archive and reporting folders..." -ForegroundColor Yellow
New-SecurityFolder "security@cogitativo.com:\6-Reports" "Security reports and analytics"
New-SecurityFolder "security@cogitativo.com:\6-Reports\Daily" "Daily security digests"
New-SecurityFolder "security@cogitativo.com:\6-Reports\Weekly" "Weekly summaries"
New-SecurityFolder "security@cogitativo.com:\6-Reports\Monthly" "Monthly analysis"

New-SecurityFolder "security@cogitativo.com:\7-Archive" "Archived security emails"
New-SecurityFolder "security@cogitativo.com:\7-Archive\2023" "2023 archives"
New-SecurityFolder "security@cogitativo.com:\7-Archive\2024" "2024 archives"
New-SecurityFolder "security@cogitativo.com:\7-Archive\2025" "2025 archives"

# Azure notices (keep existing)
Write-Host "`nKeeping existing Azure notices folder..." -ForegroundColor Cyan

# Get folder statistics
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  FOLDER STRUCTURE SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$folders = Get-MailboxFolderStatistics -Identity security@cogitativo.com | 
           Where-Object {$_.Name -match "^[1-7]-" -or $_.Name -eq "Azure notices"} |
           Sort-Object FolderPath

Write-Host "`nCreated folder structure:" -ForegroundColor Green
$folders | ForEach-Object {
    $indent = "  " * ($_.FolderPath.Split('/').Count - 1)
    $itemCount = $_.ItemsInFolder
    $folderName = $_.Name
    Write-Host "$indent$folderName - $itemCount items"
}

Write-Host "`n✅ Folder structure created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run ORGANIZE-EXISTING-EMAILS.ps1 to sort existing emails"
Write-Host "2. Set up mail flow rules for automatic sorting"
Write-Host "3. Configure automation scripts"

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green