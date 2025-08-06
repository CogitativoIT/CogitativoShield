@echo off
echo Creating Dedicated Bastion for Vendor Environment...
echo.

REM First check if AzureBastionSubnet exists
echo Checking for AzureBastionSubnet in vision-vnet...
call az network vnet subnet show -g vision --vnet-name vision-vnet -n AzureBastionSubnet 2>nul
if %errorlevel% neq 0 (
    echo AzureBastionSubnet not found. Creating it...
    call az network vnet subnet create -g vision --vnet-name vision-vnet -n AzureBastionSubnet --address-prefixes 10.0.12.0/26
    echo Subnet created.
) else (
    echo AzureBastionSubnet already exists.
)

echo.
echo Creating Bastion host in dedicated resource group...
call az network bastion create --name bastion-pbi-vendor --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --public-ip-sku Standard --location eastus

echo.
echo Bastion creation initiated. This will take 5-10 minutes...
echo.
echo Once complete:
echo - Vendors can use VM Connect button directly
echo - No cross-RG permission issues
echo - Cleaner architecture
echo.
pause