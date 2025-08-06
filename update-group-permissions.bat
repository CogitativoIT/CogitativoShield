@echo off
echo === Updating visionbidevvm Group Permissions ===
echo.

echo Checking current permissions...
call az role assignment list --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --all | findstr "pbivend9084"

echo.
echo Granting Storage Blob Data Contributor to visionbidevvm group...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Verifying Jason Jones is in the group...
call az ad group member list --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --query "[?userPrincipalName=='jason.jones@cogitativo.com']" -o table

echo.
echo === Complete ===
echo.
echo visionbidevvm group now has Storage Blob Data Contributor access
echo Jason Jones can use his Azure AD credentials in Databricks
echo.
pause