@echo off
echo === Granting Databricks Storage Access via Group ===
echo.

echo Step 1: Upgrading visionbidevvm group storage permissions...
echo Current role: Storage Blob Data Reader
echo New role: Storage Blob Data Contributor (for write access)
echo.

REM First remove the Reader role
call az role assignment delete --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Storage Blob Data Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" 2>nul

REM Add Contributor role for read/write access
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

echo.
echo Step 2: Adding Jason Jones to visionbidevvm group...
call az ad group member add --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --member-id jason.jones@cogitativo.com

echo.
echo === Configuration Complete ===
echo.
echo visionbidevvm group now has:
echo - Storage Blob Data Contributor on pbivend9084
echo - VM access rights
echo - Bastion access
echo.
echo Jason Jones (jason.jones@cogitativo.com) added to group
echo.
echo Next: Jason needs to use Azure AD auth in Databricks (see guide)
pause