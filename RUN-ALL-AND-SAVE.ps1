# Complete O365 Security Audit, Fix, and Report Generation
# This runs everything and saves output to files

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$auditFile = "C:\Users\andre.darby\Ops\AUDIT-OUTPUT-$timestamp.txt"
$fixFile = "C:\Users\andre.darby\Ops\FIX-OUTPUT-$timestamp.txt"

Write-Host "=== O365 SECURITY AUDIT AND FIX ===" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

# Start transcript
Start-Transcript -Path "C:\Users\andre.darby\Ops\COMPLETE-LOG-$timestamp.txt"

Write-Host "[1/5] Connecting to Exchange Online..." -ForegroundColor Yellow
try {
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false
    Write-Host "✅ Connected successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Connection failed. Please run manually." -ForegroundColor Red
    Stop-Transcript
    exit
}

Write-Host ""
Write-Host "[2/5] Running comprehensive audit..." -ForegroundColor Yellow
& "C:\Users\andre.darby\Ops\comprehensive-defender-audit.ps1" | Tee-Object -FilePath $auditFile
Write-Host "✅ Audit saved to: $auditFile" -ForegroundColor Green

Write-Host ""
Write-Host "[3/5] Applying security fixes..." -ForegroundColor Yellow
& "C:\Users\andre.darby\Ops\fix-dmarc-quarantine.ps1" | Tee-Object -FilePath $fixFile
Write-Host "✅ Fixes saved to: $fixFile" -ForegroundColor Green

Write-Host ""
Write-Host "[4/5] Generating reports..." -ForegroundColor Yellow
& "C:\Users\andre.darby\Ops\generate-final-report.ps1"
Write-Host "✅ Reports generated" -ForegroundColor Green

Write-Host ""
Write-Host "[5/5] Creating summary..." -ForegroundColor Yellow

# Quick summary
$summary = @"
O365 SECURITY AUDIT AND FIX SUMMARY
====================================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

FILES CREATED:
- Audit Output: $auditFile
- Fix Output: $fixFile
- HTML Report: O365-SECURITY-REPORT.html
- Text Summary: O365-SECURITY-SUMMARY.txt
- Complete Log: COMPLETE-LOG-$timestamp.txt

KEY CHANGES APPLIED:
✅ SCL threshold lowered from 9 to 4
✅ DMARC quarantine now goes to Junk folder
✅ Regular spam goes to Junk instead of Quarantine
✅ End-user notifications enabled

NEXT STEPS:
1. Review HTML report in browser
2. Monitor quarantine for 24-48 hours
3. Check user feedback on Junk folder
4. Add any missed legitimate senders

Changes take effect within 30 minutes.
"@

$summary | Out-File -FilePath "C:\Users\andre.darby\Ops\EXECUTION-SUMMARY-$timestamp.txt"
Write-Host $summary -ForegroundColor White

Write-Host ""
Write-Host "=== ALL OPERATIONS COMPLETE ===" -ForegroundColor Green

# Disconnect
Write-Host ""
Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false

Stop-Transcript

Write-Host ""
Write-Host "To view the HTML report, run:" -ForegroundColor Cyan
Write-Host "  start C:\Users\andre.darby\Ops\O365-SECURITY-REPORT.html" -ForegroundColor White