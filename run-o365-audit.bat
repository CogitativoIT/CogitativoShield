@echo off
echo === Office 365 Security Audit Launcher ===
echo.
echo This will open PowerShell and connect to Exchange Online
echo You'll need to authenticate when prompted
echo.
pause

powershell -NoExit -ExecutionPolicy Bypass -Command "Write-Host 'Connecting to Exchange Online...' -ForegroundColor Yellow; Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com; Write-Host 'Connected! Running security audit...' -ForegroundColor Green; & 'C:\Users\andre.darby\Ops\o365-security-audit-manual.ps1'"