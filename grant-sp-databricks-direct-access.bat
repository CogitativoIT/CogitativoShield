@echo off
echo === Granting Direct Access to sp-databricks ===
echo.

echo Service Principal: sp-databricks
echo App ID: 9a3351d0-f816-4e6f-95d4-f90ac882a479
echo Storage Account: pbivend9084
echo.

echo Step 1: Removing any existing role assignments to avoid conflicts...
call az role assignment delete --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" 2>nul

echo.
echo Step 2: Granting Storage Blob Data Contributor role directly...
call az role assignment create --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Step 3: Also granting at container level for extra assurance...
call az role assignment create --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084/blobServices/default/containers/data" 2>nul

echo.
echo Step 4: Verifying role assignments...
echo Direct assignments for sp-databricks:
call az role assignment list --assignee "9a3351d0-f816-4e6f-95d4-f90ac882a479" --all --query "[?contains(scope, 'pbivend9084')].{role:roleDefinitionName, scope:scope}" -o table

echo.
echo === Access Granted ===
echo.
echo IMPORTANT: Role assignments can take up to 5 minutes to propagate!
echo Wait a few minutes before testing again in Databricks.
echo.
pause