@echo off
echo Adding Storage Blob Data Reader to visionbidevvm group...
echo.

REM Note: Storage account moved to rg-pbi-vendor-isolated
echo Granting Storage Blob Data Reader role...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Storage Blob Data Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo === Updated permissions for visionbidevvm group ===
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all --output table

echo.
echo === COMPLETE VENDOR ACCESS SETUP ===
echo.
echo The visionbidevvm group now has:
echo   1. VM access (User Login)
echo   2. Bastion access
echo   3. Storage read access
echo.
echo To add a new vendor:
echo   1. Create guest user in Azure AD
echo   2. Add them to visionbidevvm group
echo   3. They automatically get all access!
echo.
pause