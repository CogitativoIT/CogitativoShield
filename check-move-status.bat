@echo off
echo Checking resource move status...
echo.

echo Resources in OLD location (vision):
call az resource list -g vision --query "[?name=='vm-pbi-vendor' || name=='pbivend9084' || name=='vm-pbi-vendorVMNic' || contains(name, 'vm-pbi-vendor_OsDisk')]" --output table

echo.
echo Resources in NEW location (rg-pbi-vendor-isolated):
call az resource list -g rg-pbi-vendor-isolated --output table

echo.
echo If resources appear in NEW location, the move is complete!
echo If they still appear in OLD location, the move is still in progress.
pause