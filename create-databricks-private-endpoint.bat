@echo off
echo === Creating Private Endpoint for Databricks Access ===
echo.

echo 1. Creating private endpoint in Databricks VNet...
call az network private-endpoint create ^
    --name pe-pbivend9084-databricks ^
    --resource-group rg-pbi-vendor-isolated ^
    --vnet-name visionnetwork ^
    --subnet private-databricks-subnet ^
    --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" ^
    --group-id blob ^
    --connection-name databricks-connection ^
    --location eastus2

echo.
echo 2. Creating DNS zone link for Databricks VNet...
call az network private-dns zone vnet-link create ^
    --resource-group vision ^
    --zone-name privatelink.blob.core.windows.net ^
    --name databricks-link ^
    --virtual-network "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/visionnetwork" ^
    --registration-enabled false

echo.
echo === Private Endpoint Created ===
echo Databricks can now access storage via private endpoint!
echo.
pause