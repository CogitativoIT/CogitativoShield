@echo off
echo Checking existing Bastion configurations...
echo.

echo Bastion hosts in subscription:
call az network bastion list --output table 2>nul

echo.
echo Checking which Bastion is using AzureBastionSubnet...
call az network vnet subnet show -g vision --vnet-name vision-vnet -n AzureBastionSubnet --query ipConfigurations[*].id -o tsv

echo.
pause