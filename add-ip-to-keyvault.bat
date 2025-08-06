@echo off
echo === Adding IP to cogikeyvault Firewall ===
echo.
echo Your current IP: 157.131.165.243
echo.

echo Adding IP to Key Vault firewall rules...
call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address 157.131.165.243

echo.
echo Verifying firewall rules...
call az keyvault show --name cogikeyvault --query "properties.networkAcls.ipRules[].value" -o tsv

echo.
echo === Complete ===
echo Your IP has been added to cogikeyvault firewall
echo You should now be able to access the Key Vault
echo.
pause