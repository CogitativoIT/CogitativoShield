@echo off
echo === Verifying sp-databricks Permissions ===
echo.

echo Checking all role assignments for sp-databricks (9a3351d0-f816-4e6f-95d4-f90ac882a479)...
echo.

echo 1. Checking storage account level permissions:
call az role assignment list --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --output table

echo.
echo 2. Checking resource group level permissions:
call az role assignment list --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated" --output table

echo.
echo 3. Checking if sp-databricks is in visionbidevvm group:
call az ad group member check --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --member-id "9a3351d0-f816-4e6f-95d4-f90ac882a479"

echo.
echo 4. Checking visionbidevvm group permissions on storage:
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --output table

echo.
echo === Summary ===
echo If no direct assignment shows above, we need to grant it.
echo.
pause