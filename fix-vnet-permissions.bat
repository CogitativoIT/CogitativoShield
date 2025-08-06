@echo off
echo Fixing VNet permissions for Bastion access...
echo.

REM The user needs Reader on the VNet to use Bastion
echo Adding Reader permission on vision-vnet...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet"

REM Also add Reader on the specific subnet for good measure
echo Adding Reader permission on VM subnet...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/snet-pbi-vendor"

echo.
echo Checking all permissions for the security group...
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all --output table

echo.
echo Done! The security group now has:
echo - Reader on vision-vnet (required for Bastion)
echo - Reader on the VM subnet
echo - All other permissions remain unchanged
echo.
echo User should now be able to connect via Bastion.
pause