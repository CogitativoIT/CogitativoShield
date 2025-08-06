@echo off
echo Granting VM User Login permissions to visionbidevvm group...
echo.

call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

echo.
echo Permissions granted!
pause