@echo off
echo === Setting up Databricks Access for pbivend9084 ===
echo.

echo Option 1: Grant Jason Jones direct access
echo ------------------------------------------
echo Adding Jason Jones as Storage Blob Data Contributor...
call az role assignment create --assignee "jason.jones@yourdomain.com" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Option 2: Create Service Principal for Databricks
echo -------------------------------------------------
echo Creating service principal...
for /f "tokens=*" %%a in ('az ad sp create-for-rbac --name "databricks-storage-access" --query appId -o tsv') do set APP_ID=%%a
echo Service Principal App ID: %APP_ID%

echo.
echo Granting Storage Blob Data Contributor role...
call az role assignment create --assignee %APP_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo === Setup Complete ===
echo.
echo Jason can now mount using Azure AD authentication
echo See databricks-storage-mount-guide.md for code examples
echo.
pause