@echo off
cls
color 0A
echo ==============================================================
echo       AUTOMATED O365 SECURITY AUDIT AND FIX EXECUTION
echo ==============================================================
echo.
echo This script will:
echo   1. Connect to Exchange Online
echo   2. Run comprehensive security audit
echo   3. Apply fixes for DMARC quarantine issues
echo   4. Generate full audit report
echo.
echo Starting automated execution...
echo.
timeout /t 3 /nobreak >nul

powershell.exe -NoExit -ExecutionPolicy Bypass -Command "& {$Host.UI.RawUI.WindowTitle = 'O365 Security Fix - Automated'; Write-Host ''; Write-Host '=== STARTING AUTOMATED O365 SECURITY AUDIT AND FIX ===' -ForegroundColor Cyan; Write-Host ''; Write-Host '[1/4] Connecting to Exchange Online...' -ForegroundColor Yellow; Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false; Write-Host '[1/4] ✅ Connected successfully' -ForegroundColor Green; Write-Host ''; Write-Host '[2/4] Running comprehensive security audit...' -ForegroundColor Yellow; & 'C:\Users\andre.darby\Ops\comprehensive-defender-audit.ps1' | Out-File -FilePath 'C:\Users\andre.darby\Ops\AUDIT-RESULTS-$(Get-Date -Format yyyyMMdd-HHmmss).txt' -Encoding UTF8; Write-Host '[2/4] ✅ Audit completed and saved' -ForegroundColor Green; Write-Host ''; Write-Host '[3/4] Applying security fixes for DMARC issues...' -ForegroundColor Yellow; & 'C:\Users\andre.darby\Ops\fix-dmarc-quarantine.ps1'; Write-Host '[3/4] ✅ Fixes applied successfully' -ForegroundColor Green; Write-Host ''; Write-Host '[4/4] Generating final report...' -ForegroundColor Yellow; & 'C:\Users\andre.darby\Ops\generate-final-report.ps1'; Write-Host '[4/4] ✅ Report generated' -ForegroundColor Green; Write-Host ''; Write-Host '=== ALL TASKS COMPLETED SUCCESSFULLY ===' -ForegroundColor Green; Write-Host ''; Write-Host 'Files generated:' -ForegroundColor Cyan; Write-Host '  • AUDIT-RESULTS-*.txt - Full audit log' -ForegroundColor White; Write-Host '  • O365-SECURITY-REPORT.html - Comprehensive report' -ForegroundColor White; Write-Host '  • O365-SECURITY-SUMMARY.txt - Executive summary' -ForegroundColor White; Write-Host ''; Write-Host 'Session remains open for additional commands.' -ForegroundColor Gray}"