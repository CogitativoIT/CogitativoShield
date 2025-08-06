@echo off
echo === Adding All VPN IPs to cogikeyvault ===
echo.

echo Found VPN Gateway Public IPs:
echo - 23.101.133.4 (pip-vpn-azure-aws)
echo - 13.90.143.138 (vpn-gateway-pip)
echo.

echo Adding VPN IPs to Key Vault firewall...

call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address 23.101.133.4/32
echo Added: 23.101.133.4

call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address 13.90.143.138/32
echo Added: 13.90.143.138

echo.
echo Also adding VPN client address pool range for internal access...
call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address 172.16.0.0/24
echo Added: 172.16.0.0/24 (VPN client pool)

echo.
echo Current IP rules in cogikeyvault:
call az keyvault show --name cogikeyvault --query "properties.networkAcls.ipRules[].value" -o tsv

echo.
echo === Complete ===
echo VPN users can now access the Key Vault when connected!
echo.
pause