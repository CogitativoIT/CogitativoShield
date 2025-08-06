@echo off
echo === Adding Databricks Network Rules ===
echo.

echo Adding private Databricks subnet...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet "private-databricks-subnet"

echo.
echo Adding public Databricks subnet...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet "public-databricks-subnet"

echo.
echo Adding VM subnet for redundancy...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --subnet "snet-pbi-vendor"

echo.
echo Adding Databricks resource access rule...
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --default-action Deny --bypass "AzureServices"

echo.
echo Network rules added!
pause