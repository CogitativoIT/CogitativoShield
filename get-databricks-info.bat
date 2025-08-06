@echo off
echo === Gathering Databricks Workspace Information ===
echo.

echo Fetching cogitativo-vision Databricks details...
call az resource show --ids "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Databricks/workspaces/cogitativo-vision" -o json > databricks-info.json

echo.
echo Getting VNet information...
call az network vnet list --query "[?name=='vision-vnet']" -o json > vnet-info.json

echo.
echo Checking private endpoint connections...
call az network private-endpoint list --resource-group vision --output table

echo.
echo Information saved to:
echo - databricks-info.json
echo - vnet-info.json
echo.
pause