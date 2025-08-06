@echo off
echo === Enable Databricks Access to pbivend9084 ===
echo.
echo This will configure pbivend9084 to work like cogidatalake
echo while maintaining better security.
echo.

echo Step 1: Adding Databricks resource access rule...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourcegroups/*/providers/Microsoft.Databricks/accessConnectors/*" --tenant-id "24317511-81a4-42fb-bea5-f4b0735acba5"

echo.
echo Step 2: Since Databricks is in a different VNet (visionnetwork),
echo we need one of these options:
echo.
echo OPTION A - Add Service Endpoint (Recommended for testing):
echo ----------------------------------------------------------
echo Run these commands to allow Databricks subnets:
echo.
echo az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet private-databricks-subnet
echo az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet public-databricks-subnet
echo.
echo OPTION B - Temporary Public Access (Quick test):
echo ------------------------------------------------
echo az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --public-network-access Enabled
echo.
echo OPTION C - VNet Peering (Best long-term):
echo -----------------------------------------
echo Requires network admin to peer vision-vnet with visionnetwork
echo.
pause