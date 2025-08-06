@echo off
echo Starting resource move...
echo.

REM Set Azure subscription
call az account set --subscription fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed

REM Move all resources
echo Moving resources to rg-pbi-vendor-isolated...
call az resource move --destination-group rg-pbi-vendor-isolated --ids "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/networkInterfaces/vm-pbi-vendorVMNic" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/disks/vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Move command executed. This operation may take 5-10 minutes.
echo.

REM Wait a bit
timeout /t 30 /nobreak > nul

REM Check new resource group
echo Checking new resource group...
call az resource list -g rg-pbi-vendor-isolated --output table

echo.
echo Done!
exit /b 0