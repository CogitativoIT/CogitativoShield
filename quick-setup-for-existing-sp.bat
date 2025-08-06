@echo off
echo === Quick Setup for Existing Databricks Service Principal ===
echo.
echo This will grant your existing Databricks service principal access to pbivend9084
echo.
set /p SP_ID=Enter your Service Principal Application ID: 

echo.
echo Granting Storage Blob Data Contributor role...
call az role assignment create --assignee "%SP_ID%" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo === Setup Complete ===
echo.
echo Your service principal now has access to:
echo - Storage Account: pbivend9084
echo - Permission: Storage Blob Data Contributor (Read/Write)
echo.
echo Next steps:
echo 1. Use the code in databricks-instructions-for-jason.md
echo 2. Make sure to use:
echo    - Endpoint: abfss://container@pbivend9084.dfs.core.windows.net/
echo    - NOT: wasbs://container@pbivend9084.blob.core.windows.net/
echo.
pause