@echo off
echo === Creating 'data' container in pbivend9084 ===
echo.

echo Creating container using management plane...
call az storage container create --name data --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated

echo.
echo Verifying container creation...
call az storage container show --name data --account-name pbivend9084 --resource-group rg-pbi-vendor-isolated --query "name" -o tsv

echo.
echo Setting container permissions...
call az storage container set-permission --name data --account-name pbivend9084 --public-access off --auth-mode login 2>nul

echo.
echo === Container 'data' created successfully ===
echo This is where parquet files will be stored
echo.
pause