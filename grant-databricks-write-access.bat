@echo off
echo === Granting Write Access for Databricks Users ===
echo.

REM Storage account details
set STORAGE_ACCOUNT=pbivend9084
set RESOURCE_GROUP=rg-pbi-vendor-isolated
set GROUP_NAME=visionbidevvm
set GROUP_ID=b6dc070d-f050-41c0-af1a-c9bdf043ecef

echo 1. Current Setup:
echo    - Group: %GROUP_NAME%
echo    - Storage Account: %STORAGE_ACCOUNT%
echo    - Jason Jones is member of this group
echo.

echo 2. Granting Storage Blob Data Contributor role to the group...
call az role assignment create ^
    --role "Storage Blob Data Contributor" ^
    --assignee %GROUP_ID% ^
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%STORAGE_ACCOUNT%"

echo.
echo 3. Verifying assignment...
call az role assignment list ^
    --assignee %GROUP_ID% ^
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/%RESOURCE_GROUP%/providers/Microsoft.Storage/storageAccounts/%STORAGE_ACCOUNT%" ^
    --query "[].{Role:roleDefinitionName}" -o table

echo.
echo === Complete ===
echo.
echo The visionbidevvm group now has write access to the storage account.
echo This includes:
echo - Jason Jones (jason.jones@cogitativo.com)
echo - Service Principal sp-databricks
echo - Any other members of the group
echo.
echo Jason should now be able to:
echo - Read existing parquet files
echo - Write new parquet files
echo - Overwrite existing files
echo - Create new directories
echo.
echo Note: It may take 2-3 minutes for permissions to propagate.
echo.
pause