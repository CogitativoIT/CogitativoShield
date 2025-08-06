@echo off
echo Fixing remaining configuration...
echo.

REM Wait for resource group to stabilize
echo Waiting for resource group operations to complete...
timeout /t 30 /nobreak > nul

REM Add Reader role with proper scope
echo Adding Reader role to resource group...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated"

REM Add Reader on openai-dev for Bastion
echo Adding Reader role for Bastion access...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev"

REM Try to create private endpoint again
echo.
echo Attempting to create private endpoint...
call az network private-endpoint create --name pe-pbivend9084-new --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --subnet gitlab-private-subnet --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --group-id dfs --connection-name pe-conn-pbivend9084

echo.
echo Done!
pause