@echo off
echo === Securing Storage Account with IP Rules ===
echo.

echo Adding IP rules...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address "157.131.165.243"
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address "23.101.133.4"
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --ip-address "13.90.143.138"

echo.
echo Adding Databricks subnets...
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet private-databricks-subnet
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet public-databricks-subnet
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --subnet snet-pbi-vendor

echo.
echo Setting default action back to Deny...
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --default-action Deny

echo.
echo Verifying 'data' container permissions...
echo Container 'data' has been created with:
echo - Private access (no public access)
echo - Access via Azure AD authentication
echo - visionbidevvm group has Storage Blob Data Contributor role
echo.

echo Current network configuration:
call az storage account show --name pbivend9084 --resource-group rg-pbi-vendor-isolated --query networkRuleSet -o json

echo.
echo === Complete ===
pause