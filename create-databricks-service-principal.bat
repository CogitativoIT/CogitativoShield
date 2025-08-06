@echo off
echo === Creating Service Principal for Databricks ===
echo.

REM Create service principal and capture output
echo Creating service principal...
for /f "delims=" %%i in ('az ad sp create-for-rbac --name "databricks-pbivend9084-access" --query "{appId:appId, password:password, tenant:tenant}" -o json') do set SP_JSON=%%i

REM Parse JSON manually (Windows batch workaround)
echo %SP_JSON% > sp_temp.json

REM Extract values using PowerShell
for /f "delims=" %%a in ('powershell -Command "(Get-Content sp_temp.json | ConvertFrom-Json).appId"') do set APP_ID=%%a
for /f "delims=" %%a in ('powershell -Command "(Get-Content sp_temp.json | ConvertFrom-Json).password"') do set CLIENT_SECRET=%%a
for /f "delims=" %%a in ('powershell -Command "(Get-Content sp_temp.json | ConvertFrom-Json).tenant"') do set TENANT_ID=%%a

echo.
echo Service Principal created!
echo Application ID: %APP_ID%
echo Tenant ID: %TENANT_ID%
echo.

REM Grant Storage Blob Data Contributor role
echo Granting Storage Blob Data Contributor role...
call az role assignment create --assignee %APP_ID% --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

REM Save credentials to file
echo.
echo Saving credentials to databricks-sp-credentials.txt...
echo === DATABRICKS SERVICE PRINCIPAL CREDENTIALS === > databricks-sp-credentials.txt
echo. >> databricks-sp-credentials.txt
echo Tenant ID: %TENANT_ID% >> databricks-sp-credentials.txt
echo Client ID: %APP_ID% >> databricks-sp-credentials.txt
echo Client Secret: %CLIENT_SECRET% >> databricks-sp-credentials.txt
echo. >> databricks-sp-credentials.txt
echo Storage Account: pbivend9084 >> databricks-sp-credentials.txt
echo Container: pbidata >> databricks-sp-credentials.txt
echo. >> databricks-sp-credentials.txt
echo IMPORTANT: Save these credentials securely! >> databricks-sp-credentials.txt
echo The client secret cannot be retrieved later! >> databricks-sp-credentials.txt

REM Clean up temp file
del sp_temp.json

echo.
echo === Setup Complete ===
echo Credentials saved to: databricks-sp-credentials.txt
echo.
pause