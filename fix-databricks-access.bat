@echo off
echo === Fixing Databricks Storage Access ===
echo.

echo Checking current role assignments for sp-databricks...
call az role assignment list --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --all | findstr "pbivend9084"

echo.
echo Granting direct Storage Blob Data Contributor role to sp-databricks...
call az role assignment create --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Also checking if visionbidevvm group has the role...
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all | findstr "pbivend9084"

echo.
echo Verifying group membership...
call az ad group member list --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --query "[?appId=='9a3351d0-f816-4e6f-95d4-f90ac882a479'].{displayName:displayName, id:id}" -o table

echo.
echo === Fix Applied ===
echo sp-databricks now has direct Storage Blob Data Contributor access
echo Try running the test again in Databricks
echo.
pause