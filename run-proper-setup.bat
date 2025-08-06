@echo off
echo === Running Proper Storage Setup ===
echo.
echo This will configure secure access for:
echo - Databricks (via VNet peering and firewall rules)
echo - Power BI VM (via existing private endpoint)
echo.
echo No public access will be enabled, maintaining security.
echo.
pause

powershell -ExecutionPolicy Bypass -File "C:\Users\andre.darby\Ops\setup-proper-storage-access.ps1"

echo.
echo Setup complete! Check the output above for any errors.
pause