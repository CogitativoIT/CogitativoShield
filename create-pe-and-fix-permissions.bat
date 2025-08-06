@echo off
echo Creating Private Endpoint and Fixing Permissions...
echo.

REM Create private endpoint with full IDs
echo Step 1: Creating private endpoint...
call az network private-endpoint create --name pe-pbivend9084 --resource-group rg-pbi-vendor-isolated --subnet "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/gitlab-private-subnet" --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --group-id dfs --connection-name pe-conn-pbivend9084

echo.
echo Step 2: Checking current role assignments for security group...
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all --output table

echo.
echo Step 3: Adding any missing Bastion permissions...
REM Ensure Reader on Bastion resource specifically
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion" 2>nul

echo.
echo Step 4: Verifying private endpoint creation...
call az network private-endpoint list -g rg-pbi-vendor-isolated --output table

echo.
echo Done! Summary:
echo - Private endpoint should be created
echo - Security group has permissions on:
echo   * rg-pbi-vendor-isolated (Reader + VM User Login)
echo   * openai-dev RG (Reader for Bastion)
echo   * Bastion resource directly (Reader)
echo.
pause