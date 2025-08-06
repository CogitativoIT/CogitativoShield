@echo off
echo Power BI Vendor Sandbox Deployment
echo ==================================
echo.

REM Check Azure CLI login
az account show >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Not logged in to Azure. Please run 'az login' first.
    pause
    exit /b 1
)

REM Get current subscription
for /f "tokens=*" %%i in ('az account show --query name -o tsv') do set SUB_NAME=%%i
for /f "tokens=*" %%i in ('az account show --query user.name -o tsv') do set USER_NAME=%%i
echo Subscription: %SUB_NAME%
echo User: %USER_NAME%
echo.

REM Show resource groups
echo Available Resource Groups:
az group list --output table
echo.

REM Gather inputs
echo Please provide the following information:
echo.
set /p INFRA_RG="1. Infrastructure resource group name: "
set /p VNET_NAME="2. Virtual network name: "
set /p MGMT_SUBNET="3. Management subnet name (for VM): "
set /p STORAGE_SUBNET="4. Storage PE subnet name: "
set /p STORAGE_ACCOUNT="5. Storage account name (lowercase, 3-24 chars): "
set /p DATABRICKS_SP="6. Databricks service principal ID: "
set /p VENDOR_EMAIL="7. Vendor email address: "

echo.
echo Optional (press Enter for defaults):
set /p DATA_RG="8. Data resource group [%INFRA_RG%]: "
if "%DATA_RG%"=="" set DATA_RG=%INFRA_RG%

set /p VM_SIZE="9. VM size [Standard_D4s_v3]: "
if "%VM_SIZE%"=="" set VM_SIZE=Standard_D4s_v3

set /p ADMIN_USER="10. VM admin username [azureadmin]: "
if "%ADMIN_USER%"=="" set ADMIN_USER=azureadmin

REM Get location
for /f "tokens=*" %%i in ('az group show -n %INFRA_RG% --query location -o tsv') do set LOCATION=%%i

REM Confirm
echo.
echo Ready to deploy with these settings:
echo   Location: %LOCATION%
echo   Infra RG: %INFRA_RG%
echo   Data RG: %DATA_RG%
echo   VNet/Subnets: %VNET_NAME% / %MGMT_SUBNET%, %STORAGE_SUBNET%
echo   Storage: %STORAGE_ACCOUNT%
echo   VM: vm-pbi-vendor (%VM_SIZE%)
echo.
set /p CONFIRM="Continue? (y/n): "
if /i not "%CONFIRM%"=="y" exit /b 0

echo.
echo Starting deployment...

REM Generate password (using PowerShell)
for /f "tokens=*" %%i in ('powershell -Command "Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(16, 4)"') do set VM_PASSWORD=%%i

REM Deploy storage
echo Creating storage account...
az storage account create ^
    --name %STORAGE_ACCOUNT% ^
    --resource-group %DATA_RG% ^
    --location %LOCATION% ^
    --sku Standard_LRS ^
    --kind StorageV2 ^
    --hierarchical-namespace true ^
    --default-action Deny ^
    --min-tls-version TLS1_2

REM Create container
az storage account update -n %STORAGE_ACCOUNT% -g %DATA_RG% --default-action Allow
timeout /t 5 /nobreak >nul
az storage container create --account-name %STORAGE_ACCOUNT% --name parquet --auth-mode login
az storage account update -n %STORAGE_ACCOUNT% -g %DATA_RG% --default-action Deny

echo Creating private endpoint...
for /f "tokens=*" %%i in ('az storage account show -g %DATA_RG% -n %STORAGE_ACCOUNT% --query id -o tsv') do set STORAGE_ID=%%i
az network private-endpoint create ^
    --name pe-%STORAGE_ACCOUNT% ^
    --resource-group %INFRA_RG% ^
    --vnet-name %VNET_NAME% ^
    --subnet %STORAGE_SUBNET% ^
    --private-connection-resource-id %STORAGE_ID% ^
    --group-id dfs ^
    --connection-name pe-conn-%STORAGE_ACCOUNT%

echo Setting permissions...
for /f "tokens=*" %%i in ('az account show --query id -o tsv') do set SUB_ID=%%i
set SCOPE=/subscriptions/%SUB_ID%/resourceGroups/%DATA_RG%/providers/Microsoft.Storage/storageAccounts/%STORAGE_ACCOUNT%/blobServices/default/containers/parquet
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id %DATABRICKS_SP% --scope %SCOPE%

REM Try to add vendor
az ad user show --id %VENDOR_EMAIL% >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('az ad user show --id %VENDOR_EMAIL% --query id -o tsv') do set VENDOR_ID=%%i
    az role assignment create --role "Storage Blob Data Reader" --assignee-object-id %VENDOR_ID% --scope %SCOPE%
)

echo Creating VM...
az vm create ^
    --resource-group %INFRA_RG% ^
    --name vm-pbi-vendor ^
    --image Win11-22H2-Pro ^
    --size %VM_SIZE% ^
    --vnet-name %VNET_NAME% ^
    --subnet %MGMT_SUBNET% ^
    --public-ip-address "" ^
    --admin-username %ADMIN_USER% ^
    --admin-password "%VM_PASSWORD%" ^
    --assign-identity

REM Save credentials
echo VM: vm-pbi-vendor > vm-credentials.txt
echo Username: %ADMIN_USER% >> vm-credentials.txt
echo Password: %VM_PASSWORD% >> vm-credentials.txt

echo Configuring VM...
az vm update -g %INFRA_RG% -n vm-pbi-vendor --set properties.osProfile.windowsConfiguration.patchSettings.patchMode=AutomaticByPlatform
az vm auto-shutdown -g %INFRA_RG% -n vm-pbi-vendor --time 1900

REM Install Power BI
az vm run-command invoke -g %INFRA_RG% -n vm-pbi-vendor --command-id RunPowerShellScript --scripts "winget install --id Microsoft.PowerBI -e --silent --accept-package-agreements --accept-source-agreements"

echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Storage endpoint: https://%STORAGE_ACCOUNT%.dfs.core.windows.net/parquet
echo VM credentials saved to: vm-credentials.txt
echo.
echo Access the VM via Azure Bastion in the portal.
echo.
pause