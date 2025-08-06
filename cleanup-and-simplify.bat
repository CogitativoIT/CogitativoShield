@echo off
echo === CLEANUP: Removing all the workaround permissions ===
echo.

REM Remove all the extra permissions we added as workarounds
echo Removing unnecessary permissions...

REM Remove openai-dev permissions (wrong Bastion)
call az role assignment delete --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev" 2>nul
call az role assignment delete --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion" 2>nul

REM Remove subnet-specific permission (not needed)
call az role assignment delete --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/snet-pbi-vendor" 2>nul

echo.
echo === SIMPLE SOLUTION: Use VISION-VNET-BASTION ===
echo.

REM Grant ONE permission - Reader on VISION RG (for Bastion access)
echo Adding single permission for Bastion access...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/VISION"

echo.
echo === DONE! Final permissions: ===
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all --output table

echo.
echo SUMMARY:
echo - Vendor group has Reader on: rg-pbi-vendor-isolated (their stuff)
echo - Vendor group has Reader on: VISION RG (for Bastion)
echo - Vendor group has Reader on: vision-vnet (required for Bastion)
echo - Vendor group has VM User Login on: vm-pbi-vendor
echo.
echo That's it! Clean and simple.
pause