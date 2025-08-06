# SETUP MAIL FLOW RULES FOR SECURITY@COGITATIVO.COM
# Server-side email processing rules

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURING MAIL FLOW RULES" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# Check existing rules
Write-Host "`nChecking existing mail flow rules for security mailbox..." -ForegroundColor Yellow
$existingRules = Get-TransportRule | Where-Object {$_.Description -like "*security@cogitativo.com*" -or $_.Name -like "*Security-*"}
Write-Host "Found $($existingRules.Count) existing security-related rules" -ForegroundColor Cyan

# Rule 1: DMARC Report Handler
Write-Host "`n[1/6] Creating DMARC Report Handler..." -ForegroundColor Yellow
$dmarcRule = Get-TransportRule -Identity "Security-DMARC-Handler" -ErrorAction SilentlyContinue
if (!$dmarcRule) {
    New-TransportRule -Name "Security-DMARC-Handler" `
        -Comments "Automatically process DMARC reports sent to security@cogitativo.com" `
        -SentTo "security@cogitativo.com" `
        -SubjectContainsWords "Report domain","DMARC","Report-ID" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "DMARC-Report" `
        -SetSCL -1 `
        -Priority 25 `
        -Mode Enforce
    Write-Host "  ✅ Created DMARC handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ DMARC handler already exists" -ForegroundColor Gray
}

# Rule 2: Phishing Report Handler
Write-Host "[2/6] Creating Phishing Report Handler..." -ForegroundColor Yellow
$phishRule = Get-TransportRule -Identity "Security-Phishing-Handler" -ErrorAction SilentlyContinue
if (!$phishRule) {
    New-TransportRule -Name "Security-Phishing-Handler" `
        -Comments "Handle phishing reports sent to security@cogitativo.com" `
        -SentTo "security@cogitativo.com" `
        -SubjectOrBodyContainsWords "phishing","suspicious email","scam","fake email" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Phishing-Report" `
        -SetImportance "High" `
        -Priority 26 `
        -Mode Enforce
    Write-Host "  ✅ Created Phishing handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Phishing handler already exists" -ForegroundColor Gray
}

# Rule 3: DLP Incident Handler
Write-Host "[3/6] Creating DLP Incident Handler..." -ForegroundColor Yellow
$dlpRule = Get-TransportRule -Identity "Security-DLP-Handler" -ErrorAction SilentlyContinue
if (!$dlpRule) {
    New-TransportRule -Name "Security-DLP-Handler" `
        -Comments "Categorize DLP incidents sent to security@cogitativo.com" `
        -SentTo "security@cogitativo.com" `
        -SubjectContainsWords "DLP","Data Loss Prevention","Sensitive Information" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "DLP-Incident" `
        -SetImportance "High" `
        -Priority 27 `
        -Mode Enforce
    Write-Host "  ✅ Created DLP handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ DLP handler already exists" -ForegroundColor Gray
}

# Rule 4: Spam Report Handler
Write-Host "[4/6] Creating Spam Report Handler..." -ForegroundColor Yellow
$spamRule = Get-TransportRule -Identity "Security-Spam-Handler" -ErrorAction SilentlyContinue
if (!$spamRule) {
    New-TransportRule -Name "Security-Spam-Handler" `
        -Comments "Handle spam reports sent to security@cogitativo.com" `
        -SentTo "security@cogitativo.com" `
        -SubjectContainsWords "spam","junk mail","unwanted email" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Spam-Report" `
        -Priority 28 `
        -Mode Enforce
    Write-Host "  ✅ Created Spam handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Spam handler already exists" -ForegroundColor Gray
}

# Rule 5: Abuse Report Handler
Write-Host "[5/6] Creating Abuse Report Handler..." -ForegroundColor Yellow
$abuseRule = Get-TransportRule -Identity "Security-Abuse-Handler" -ErrorAction SilentlyContinue
if (!$abuseRule) {
    New-TransportRule -Name "Security-Abuse-Handler" `
        -Comments "Handle abuse reports from external providers" `
        -SentTo "security@cogitativo.com" `
        -From "abuse@*","postmaster@*" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Abuse-Report" `
        -SetImportance "High" `
        -Priority 29 `
        -Mode Enforce
    Write-Host "  ✅ Created Abuse handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Abuse handler already exists" -ForegroundColor Gray
}

# Rule 6: Auto-Forward Security Alerts
Write-Host "[6/6] Creating Security Alert Forwarder..." -ForegroundColor Yellow
$alertRule = Get-TransportRule -Identity "Security-Alert-Forwarder" -ErrorAction SilentlyContinue
if (!$alertRule) {
    New-TransportRule -Name "Security-Alert-Forwarder" `
        -Comments "Forward high-priority security alerts to admins" `
        -SentTo "security@cogitativo.com" `
        -HeaderContainsMessageHeader "X-Security-Category" `
        -HeaderContainsWords "Phishing-Report","DLP-Incident","Abuse-Report" `
        -BlindCopyTo "andre.darby@cogitativo.com" `
        -Priority 30 `
        -Mode Enforce
    Write-Host "  ✅ Created Security alert forwarder" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Alert forwarder already exists" -ForegroundColor Gray
}

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  MAIL FLOW RULES SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$allSecurityRules = Get-TransportRule | Where-Object {$_.Name -like "Security-*"}
Write-Host "`nSecurity mail flow rules configured ($($allSecurityRules.Count)):" -ForegroundColor Green
$allSecurityRules | ForEach-Object {
    Write-Host "  ✅ $($_.Name) - Priority: $($_.Priority)"
    Write-Host "     Status: $($_.State)" -ForegroundColor Gray
}

# Show all rules targeting security mailbox
Write-Host "`nAll rules affecting security@cogitativo.com:" -ForegroundColor Yellow
$allRules = Get-TransportRule | Where-Object {
    $_.SentTo -contains "security@cogitativo.com" -or
    $_.BlindCopyTo -contains "security@cogitativo.com" -or
    $_.RedirectMessageTo -contains "security@cogitativo.com" -or
    $_.Description -like "*security@cogitativo.com*"
}

$allRules | ForEach-Object {
    Write-Host "  - $($_.Name) (Priority: $($_.Priority))"
}

Write-Host "`n✅ Mail flow rules configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "These rules will:" -ForegroundColor Cyan
Write-Host "  1. Add category headers to incoming security emails"
Write-Host "  2. Set importance levels for critical reports"
Write-Host "  3. Forward high-priority items to admins"
Write-Host "  4. Bypass spam filtering for legitimate reports"

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy DMARC processing script"
Write-Host "  2. Deploy phishing response automation"
Write-Host "  3. Create daily security report"

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Complete!" -ForegroundColor Green