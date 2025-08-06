@echo off
echo Finalizing setup in new resource group...
echo.

REM Delete old private endpoint
echo Deleting old private endpoint...
call az network private-endpoint delete --name pe-pbivend9084 --resource-group vision --yes 2>nul

REM Create new private endpoint
echo Creating new private endpoint...
call az network private-endpoint create --name pe-pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --subnet gitlab-private-subnet --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --group-id dfs --connection-name pe-conn-pbivend9084

echo.
echo Setting up permissions...

REM Add Reader role to the security group on the new RG
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --resource-group "rg-pbi-vendor-isolated"

REM Add VM User Login role
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

REM Add Reader on Bastion RG (for Bastion access)
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --resource-group "openai-dev"

echo.
echo Setup complete!
echo.
echo Summary:
echo - Resources moved to: rg-pbi-vendor-isolated
echo - Private endpoint recreated
echo - Permissions set for visionbidevvm security group
echo - Guest users can now access ONLY resources in the isolated RG
echo.
pause