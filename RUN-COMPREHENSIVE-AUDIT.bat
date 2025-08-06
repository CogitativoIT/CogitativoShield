@echo off
cls
color 0B
echo ==============================================================
echo           OFFICE 365 COMPREHENSIVE SECURITY AUDIT
echo ==============================================================
echo.
echo This will:
echo   1. Connect to Exchange Online (browser authentication)
echo   2. Analyze ALL security settings
echo   3. Check DMARC/SPF/DKIM configuration  
echo   4. Review mail flow rules
echo   5. Audit allowed/blocked lists
echo   6. Provide specific recommendations
echo.
echo Press any key to launch PowerShell and start the audit...
pause >nul

echo.
echo Launching PowerShell...
echo Please authenticate in the browser window when prompted.
echo.

powershell.exe -NoExit -ExecutionPolicy Bypass -Command "& {$Host.UI.RawUI.WindowTitle = 'O365 Security Audit'; Write-Host ''; Write-Host '=== OFFICE 365 COMPREHENSIVE SECURITY AUDIT ===' -ForegroundColor Cyan; Write-Host ''; Write-Host 'Connecting to Exchange Online...' -ForegroundColor Yellow; Write-Host 'Please authenticate in your browser.' -ForegroundColor Yellow; Write-Host ''; Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false; cls; Write-Host ''; Write-Host '=== CONNECTED - RUNNING COMPREHENSIVE AUDIT ===' -ForegroundColor Green; Write-Host 'This will take 1-2 minutes to complete...' -ForegroundColor Yellow; Write-Host ''; & 'C:\Users\andre.darby\Ops\comprehensive-defender-audit.ps1'; Write-Host ''; Write-Host '=== AUDIT COMPLETE ===' -ForegroundColor Green; Write-Host ''; Write-Host 'To fix DMARC issues, run: ' -ForegroundColor Yellow; Write-Host '  & C:\Users\andre.darby\Ops\fix-dmarc-quarantine.ps1' -ForegroundColor White; Write-Host ''; Write-Host 'To disconnect, run: Disconnect-ExchangeOnline -Confirm:$false' -ForegroundColor Gray}"

echo.
echo PowerShell audit window opened.
echo.
pause