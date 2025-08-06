@echo off
echo === Enabling Databricks Access to Storage (Temporary) ===
echo.

echo 1. Enabling Azure Services bypass...
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --bypass AzureServices

echo.
echo 2. Adding resource access rule for Databricks...
echo [{"tenantId":"24317511-81a4-42fb-bea5-f4b0735acba5","resourceId":"/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourcegroups/*/providers/Microsoft.Databricks/accessConnectors/*"}] > databricks-rule.json
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --resource-access-rules @databricks-rule.json
del databricks-rule.json

echo.
echo 3. Setting default action to Allow from Azure services...
call az storage account update --name pbivend9084 --resource-group rg-pbi-vendor-isolated --default-action Allow

echo.
echo 4. Verifying configuration...
call az storage account show --name pbivend9084 --resource-group rg-pbi-vendor-isolated --query "{DefaultAction:networkRuleSet.defaultAction, Bypass:networkRuleSet.bypass, ResourceRules:networkRuleSet.resourceAccessRules}" -o json

echo.
echo === Databricks Access Enabled ===
echo NOTE: This temporarily allows public access. Consider private endpoints for production.
echo.
pause