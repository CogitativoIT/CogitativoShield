@echo off
echo === Adding IPs to pbivend9084 Storage Account Firewall ===
echo.

echo Adding your current IP (157.131.165.243)...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address 157.131.165.243

echo.
echo Adding VPN Gateway IPs...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address 23.101.133.4
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address 13.90.143.138

echo.
echo Updating network rules to allow Azure services...
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --bypass "AzureServices,Logging,Metrics" --default-action Deny

echo.
echo Current network rules:
call az storage account show --name pbivend9084 --resource-group rg-pbi-vendor-isolated --query "networkRuleSet" -o json

echo.
echo Now creating 'data' container...
call az storage container create --name data --account-name pbivend9084 --auth-mode login

echo.
echo === Complete ===
pause