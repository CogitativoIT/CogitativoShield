@echo off
echo === Upgrading visionbidevvm Group Permissions ===
echo.

echo Current: Storage Blob Data Reader (read-only)
echo Upgrading to: Storage Blob Data Contributor (read/write)
echo.

REM Remove the Reader role
call az role assignment delete --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --role "Storage Blob Data Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
REM Add the Contributor role
call az role assignment create --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo === Upgrade Complete ===
echo visionbidevvm group now has read/write access
echo sp-databricks (as a member) will inherit this access
echo.
echo Wait 2-3 minutes for propagation then test again!
echo.
pause