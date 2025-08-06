@echo off
echo ====================================
echo Post-Move Verification Check
echo ====================================
echo.

echo 1. Checking VM Network Configuration...
call az vm show -g rg-pbi-vendor-isolated -n vm-pbi-vendor --query "{Name:name, PrivateIP:privateIPAddresses[0], Subnet:networkProfile.networkInterfaces[0].id}" -o json

echo.
echo 2. Checking Network Interface Details...
call az network nic show -g rg-pbi-vendor-isolated -n vm-pbi-vendorVMNic --query "{PrivateIP:ipConfigurations[0].privateIpAddress, Subnet:ipConfigurations[0].subnet.id, NSG:networkSecurityGroup.id}" -o json

echo.
echo 3. Checking Storage Account Status...
call az storage account show -g rg-pbi-vendor-isolated -n pbivend9084 --query "{Name:name, PrivateEndpoints:privateEndpointConnections[*].name, NetworkRules:networkRuleSet.defaultAction}" -o json

echo.
echo 4. Checking Private Endpoints...
call az network private-endpoint list -g vision --query "[?contains(name, 'pbivend')].{Name:name, State:provisioningState, Connection:privateLinkServiceConnections[0].privateLinkServiceId}" -o table

echo.
echo 5. Checking Bastion Connectivity...
call az network bastion show -g openai-dev -n Dtlaidev1-bastion --query "{Name:name, State:provisioningState}" -o json

echo.
echo 6. Checking VM Subnet Association...
call az network vnet subnet show -g vision --vnet-name vision-vnet -n snet-pbi-vendor --query "{Name:name, AddressPrefix:addressPrefix, ConnectedDevices:ipConfigurations[*].id}" -o json

echo.
echo ====================================
echo Verification Complete
echo ====================================
pause