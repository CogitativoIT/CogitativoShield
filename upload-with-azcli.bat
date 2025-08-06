@echo off
echo === Uploading Sample Data to Azure Storage ===
echo.

set STORAGE_ACCOUNT=pbivend9084
set CONTAINER=data
set SOURCE_DIR=sample_data

echo Storage Account: %STORAGE_ACCOUNT%
echo Container: %CONTAINER%
echo Source Directory: %SOURCE_DIR%
echo --------------------------------------------------

REM Upload individual parquet files
echo.
echo Uploading parquet files...
for %%f in (%SOURCE_DIR%\*.parquet) do (
    echo Uploading %%~nxf...
    call az storage fs file upload --source "%%f" --path "%%~nxf" --file-system %CONTAINER% --account-name %STORAGE_ACCOUNT% --auth-mode login
)

REM Upload partitioned data
echo.
echo Uploading partitioned data...
call az storage fs directory upload --source "%SOURCE_DIR%\sales_partitioned" --destination-path "sales_partitioned" --file-system %CONTAINER% --account-name %STORAGE_ACCOUNT% --recursive --auth-mode login

echo.
echo === Upload Complete ===
echo.
echo Files uploaded to: https://%STORAGE_ACCOUNT%.dfs.core.windows.net/%CONTAINER%/
echo.
echo You can now:
echo 1. Test in Databricks using the code from jason-final-databricks-setup.md
echo 2. Connect from Power BI:
echo    - URL: https://%STORAGE_ACCOUNT%.dfs.core.windows.net/%CONTAINER%
echo    - Use Azure AD authentication
echo.
pause