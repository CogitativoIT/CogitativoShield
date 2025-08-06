@echo off
echo === Adding VPN IPs to cogikeyvault Firewall ===
echo.

REM Add common VPN IP ranges - adjust these based on your VPN configuration
echo Adding VPN IP ranges...

REM Add your current IP (already added)
echo Your current IP: 157.131.165.243 (already added)

REM Common corporate VPN ranges - replace with your actual VPN IPs
REM Example: If your VPN uses 10.0.0.0/8 for internal, you'd need the public egress IPs

echo.
echo Please provide your VPN public egress IP addresses.
echo Common patterns:
echo - Single IP: 203.0.113.45
echo - IP range: 203.0.113.0/24
echo - Multiple IPs: Add each separately
echo.

set /p VPN_IP1=Enter VPN IP or range (or press Enter to skip): 
if not "%VPN_IP1%"=="" (
    call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address "%VPN_IP1%"
    echo Added: %VPN_IP1%
)

set /p VPN_IP2=Enter another VPN IP or range (or press Enter to skip): 
if not "%VPN_IP2%"=="" (
    call az keyvault network-rule add --name cogikeyvault --resource-group vision --ip-address "%VPN_IP2%"
    echo Added: %VPN_IP2%
)

echo.
echo Current IP rules:
call az keyvault show --name cogikeyvault --query "properties.networkAcls.ipRules[].value" -o tsv

echo.
echo === Complete ===
pause