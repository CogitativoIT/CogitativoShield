@echo off
echo === Creating VNet Peering ===
echo.

echo Creating peering from vision-vnet to visionnetwork...
call az network vnet peering create --name "vision-to-databricks" --resource-group vision --vnet-name vision-vnet --remote-vnet "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/visionnetwork" --allow-vnet-access --allow-forwarded-traffic

echo.
echo Creating reverse peering from visionnetwork to vision-vnet...
call az network vnet peering create --name "databricks-to-vision" --resource-group vision --vnet-name visionnetwork --remote-vnet "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet" --allow-vnet-access --allow-forwarded-traffic

echo.
echo Peering complete!
pause