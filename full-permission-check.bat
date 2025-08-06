@echo off
echo === Full Permission Check for sp-databricks ===
echo.

echo 1. Checking visionbidevvm group permissions:
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --output json

echo.
echo 2. Checking if sp-databricks is in the group:
call az ad group member list --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --query "[?id=='9898eeb9-ca55-454a-a700-277787530074'].{displayName:displayName, appId:appId}" -o json

echo.
echo 3. Checking direct permissions for sp-databricks:
call az role assignment list --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --output json

echo.
echo 4. Granting DIRECT permission to sp-databricks (bypassing group):
call az role assignment create --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --output json

echo.
echo === Done ===
pause