@echo off
echo === Adding Databricks Network Access to Storage ===
echo.

echo 1. Adding Databricks private subnet to storage firewall:
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet private-databricks-subnet

echo.
echo 2. Adding Databricks public subnet to storage firewall:
call az storage account network-rule add --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name visionnetwork --subnet public-databricks-subnet

echo.
echo 3. Adding Databricks resource access rule:
echo Creating temporary JSON file for resource access rules...
echo [{"tenantId":"24317511-81a4-42fb-bea5-f4b0735acba5","resourceId":"/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourcegroups/*/providers/Microsoft.Databricks/accessConnectors/*"}] > resource-rules.json

call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --resource-access-rules @resource-rules.json

del resource-rules.json

echo.
echo 4. Verifying network configuration:
call az storage account show --name pbivend9084 --resource-group rg-pbi-vendor-isolated --query networkRuleSet -o json

echo.
echo === Network Access Configured ===
echo Databricks can now access the storage account!
echo.
pause