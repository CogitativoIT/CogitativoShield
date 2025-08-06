@echo off
cls
echo =========================================================
echo           OFFICE 365 SECURITY AUDIT LAUNCHER
echo =========================================================
echo.
echo This will:
echo 1. Open PowerShell
echo 2. Connect to Exchange Online (you'll need to login)
echo 3. Run a comprehensive security audit
echo 4. Show recommendations
echo.
echo Press any key to start...
pause >nul

echo.
echo Launching PowerShell with audit script...
echo You will need to authenticate in the browser window that opens.
echo.

start powershell.exe -NoExit -ExecutionPolicy Bypass -Command "& {Write-Host ''; Write-Host '=== CONNECTING TO OFFICE 365 ===' -ForegroundColor Cyan; Write-Host 'Please authenticate in the browser window...' -ForegroundColor Yellow; Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com; cls; Write-Host ''; Write-Host '=== CONNECTED! RUNNING SECURITY AUDIT ===' -ForegroundColor Green; Write-Host ''; & 'C:\Users\andre.darby\Ops\o365-security-audit-manual.ps1'}"

echo.
echo PowerShell window opened with audit script.
echo Follow the authentication prompts in your browser.
echo.
pause