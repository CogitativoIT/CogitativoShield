@echo off
echo Granting Storage Blob Data Contributor to sp-databricks...
echo.

set ASSIGNEE=9a3351d0-f816-4e6f-95d4-f90ac882a479
set ROLE=ba92f5b4-2d11-453d-a403-e96b0029c9fe
set SCOPE=/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084

echo Using role definition ID instead of name...
call az role assignment create --assignee %ASSIGNEE% --role %ROLE% --scope "%SCOPE%"

echo.
echo Verifying assignment...
call az role assignment list --assignee %ASSIGNEE% --scope "%SCOPE%" --output json

echo.
echo Done! Wait 2-5 minutes for propagation.
pause