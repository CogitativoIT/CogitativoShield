@echo off
echo Adding VM User Login role...

REM First check if role already exists
call az role assignment list --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --all | findstr "Virtual Machine User Login" >nul
if %errorlevel%==0 (
    echo Role already exists!
) else (
    echo Adding role...
    call az role assignment create --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
)

echo.
echo Current permissions:
call az role assignment list --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --all --output table

pause