@echo off
echo === Windows 11 Migration Launcher ===
echo.
echo This will replace your Windows Server 2022 VM with Windows 11
echo keeping all network configuration intact.
echo.
echo IMPORTANT: This will DELETE the current VM!
echo Make sure you have backed up any important data first.
echo.
echo Press Ctrl+C to cancel, or
pause

echo.
echo Starting migration...
powershell -ExecutionPolicy Bypass -File migrate-to-windows11.ps1

echo.
echo Migration script completed!
echo.
pause