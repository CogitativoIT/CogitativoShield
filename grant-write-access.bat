@echo off
echo === Granting Write Access to visionbidevvm Group ===
echo.

REM Grant Storage Blob Data Contributor role
call az role assignment create --role "Storage Blob Data Contributor" --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo === Verifying Permissions ===
call az role assignment list --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --query "[].roleDefinitionName" -o tsv

echo.
echo Done! The visionbidevvm group now has write access.
pause