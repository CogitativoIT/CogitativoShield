@echo off
cls
echo ===========================================================
echo        DIRECT O365 SECURITY AUDIT AND FIX
echo ===========================================================
echo.
echo This will:
echo 1. Open PowerShell
echo 2. Connect to Exchange Online (you authenticate)
echo 3. Run audit and fixes
echo 4. Show results in the same window
echo.
pause

powershell.exe -NoExit -ExecutionPolicy Bypass -Command "Write-Host ''; Write-Host 'Step 1: Connecting to Exchange Online...' -ForegroundColor Yellow; Write-Host 'Please authenticate in the browser window that opens.' -ForegroundColor Cyan; Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com; cls; Write-Host ''; Write-Host 'Step 2: Running audit and applying fixes...' -ForegroundColor Yellow; & 'C:\Users\andre.darby\Ops\direct-audit-fix.ps1'; Write-Host ''; Write-Host 'Session remains open. You can run additional commands.' -ForegroundColor Gray; Write-Host 'To disconnect: Disconnect-ExchangeOnline -Confirm:$false' -ForegroundColor Gray"