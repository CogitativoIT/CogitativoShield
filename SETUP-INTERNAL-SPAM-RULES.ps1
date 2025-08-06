# SETUP MAIL FLOW RULES FOR INTERNAL SPAM REPORTS
# Handles emails forwarded by internal users reporting spam/phishing

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURING INTERNAL SPAM REPORT RULES" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# Rule 1: Internal Forwarded Emails (FW: or Fwd:)
Write-Host "`n[1/6] Creating Internal Forward Handler..." -ForegroundColor Yellow
$rule1 = Get-TransportRule -Identity "Security-Internal-Forward" -ErrorAction SilentlyContinue
if (!$rule1) {
    New-TransportRule -Name "Security-Internal-Forward" `
        -Comments "Process emails forwarded by internal users to security@cogitativo.com" `
        -SentTo "security@cogitativo.com" `
        -FromMemberOf "All Users" `
        -SubjectMatchesPatterns "^(FW:|Fwd:|FWD:|RE: FW:|RE: Fwd:)" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Internal-Forward" `
        -SetHeaderName "X-Original-Reporter" `
        -SetHeaderValue "Internal-User" `
        -SetImportance "High" `
        -Priority 10 `
        -Mode Enforce
    Write-Host "  ✅ Created Internal Forward handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Internal Forward handler already exists" -ForegroundColor Gray
}

# Rule 2: Internal users reporting spam explicitly
Write-Host "[2/6] Creating Internal Spam Report Handler..." -ForegroundColor Yellow
$rule2 = Get-TransportRule -Identity "Security-Internal-SpamReport" -ErrorAction SilentlyContinue
if (!$rule2) {
    New-TransportRule -Name "Security-Internal-SpamReport" `
        -Comments "Handle spam reports from internal users" `
        -SentTo "security@cogitativo.com" `
        -From "*@cogitativo.com" `
        -SubjectOrBodyContainsWords "spam", "junk", "unwanted", "unsubscribe", "suspicious email", "is this legitimate", "please check", "FYI" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Internal-Spam-Report" `
        -SetImportance "High" `
        -Priority 11 `
        -Mode Enforce
    Write-Host "  ✅ Created Internal Spam Report handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Internal Spam Report handler already exists" -ForegroundColor Gray
}

# Rule 3: Internal phishing reports
Write-Host "[3/6] Creating Internal Phishing Report Handler..." -ForegroundColor Yellow
$rule3 = Get-TransportRule -Identity "Security-Internal-PhishingReport" -ErrorAction SilentlyContinue
if (!$rule3) {
    New-TransportRule -Name "Security-Internal-PhishingReport" `
        -Comments "Handle phishing reports from internal users with high priority" `
        -SentTo "security@cogitativo.com" `
        -From "*@cogitativo.com" `
        -SubjectOrBodyContainsWords "phishing", "phish", "scam", "fraud", "fake email", "malicious", "virus", "malware", "ransomware" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Internal-Phishing-Alert" `
        -SetImportance "High" `
        -SetSCL 9 `
        -Priority 9 `
        -Mode Enforce
    Write-Host "  ✅ Created Internal Phishing Report handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Internal Phishing Report handler already exists" -ForegroundColor Gray
}

# Rule 4: Common spam subject patterns from internal forwards
Write-Host "[4/6] Creating Spam Pattern Detector..." -ForegroundColor Yellow
$rule4 = Get-TransportRule -Identity "Security-SpamPattern-Detector" -ErrorAction SilentlyContinue
if (!$rule4) {
    New-TransportRule -Name "Security-SpamPattern-Detector" `
        -Comments "Detect common spam patterns in forwarded emails" `
        -SentTo "security@cogitativo.com" `
        -From "*@cogitativo.com" `
        -SubjectContainsWords "winner", "congratulations", "claim your", "urgent action", "verify account", `
                            "suspended", "click here", "limited time", "act now", "expires today", `
                            "invoice attached", "payment required", "tax refund", "inheritance", `
                            "lottery", "bitcoin", "cryptocurrency" `
        -SetHeaderName "X-Security-Category" `
        -SetHeaderValue "Spam-Pattern-Detected" `
        -SetSCL 8 `
        -Priority 12 `
        -Mode Enforce
    Write-Host "  ✅ Created Spam Pattern Detector rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Spam Pattern Detector already exists" -ForegroundColor Gray
}

# Rule 5: Executive/VIP reporters get priority
Write-Host "[5/6] Creating VIP Reporter Priority Handler..." -ForegroundColor Yellow
$rule5 = Get-TransportRule -Identity "Security-VIP-Reporter" -ErrorAction SilentlyContinue
if (!$rule5) {
    # First check if we can identify executives
    $executives = @("david.buhler@cogitativo.com", "andre.darby@cogitativo.com")
    
    New-TransportRule -Name "Security-VIP-Reporter" `
        -Comments "Priority handling for reports from executives" `
        -SentTo "security@cogitativo.com" `
        -From $executives `
        -SetHeaderName "X-Security-Priority" `
        -SetHeaderValue "VIP-Report" `
        -SetImportance "High" `
        -Priority 5 `
        -Mode Enforce
    Write-Host "  ✅ Created VIP Reporter Priority handler rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ VIP Reporter Priority handler already exists" -ForegroundColor Gray
}

# Rule 6: Auto-response for internal reporters
Write-Host "[6/6] Creating Auto-Response Rule..." -ForegroundColor Yellow
$rule6 = Get-TransportRule -Identity "Security-Internal-AutoResponse" -ErrorAction SilentlyContinue
if (!$rule6) {
    New-TransportRule -Name "Security-Internal-AutoResponse" `
        -Comments "Mark internal reports for auto-response" `
        -SentTo "security@cogitativo.com" `
        -From "*@cogitativo.com" `
        -ExceptIfFrom "security@cogitativo.com", "noreply@cogitativo.com" `
        -SetHeaderName "X-AutoResponse-Required" `
        -SetHeaderValue "True" `
        -Priority 20 `
        -Mode Enforce
    Write-Host "  ✅ Created Auto-Response marker rule" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ Auto-Response marker already exists" -ForegroundColor Gray
}

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  INTERNAL SPAM RULES SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$allInternalRules = Get-TransportRule | Where-Object {$_.Name -like "Security-Internal-*" -or $_.Name -eq "Security-VIP-Reporter" -or $_.Name -eq "Security-SpamPattern-Detector"}
Write-Host "`nConfigured internal spam handling rules ($($allInternalRules.Count)):" -ForegroundColor Green
$allInternalRules | ForEach-Object {
    Write-Host "  ✅ $($_.Name) - Priority: $($_.Priority)" -ForegroundColor White
    Write-Host "     Status: $($_.State)" -ForegroundColor Gray
}

Write-Host "`n✅ Internal spam handling rules configured successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "These rules will:" -ForegroundColor Cyan
Write-Host "  1. Identify and categorize forwarded emails (FW:/Fwd:)"
Write-Host "  2. Detect spam/phishing keywords in internal reports"
Write-Host "  3. Prioritize reports from VIP users"
Write-Host "  4. Mark emails for auto-response to reporters"
Write-Host "  5. Set appropriate importance and SCL levels"

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy internal spam processing script"
Write-Host "  2. Create auto-response templates"
Write-Host "  3. Setup extraction of original senders from forwards"

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Complete!" -ForegroundColor Green