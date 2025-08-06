@echo off
echo === Checking Andre's Storage Access ===
echo.

echo Checking if andre.darby@cogitativo.com is in visionbidevvm group...
call az ad group member list --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --query "[?userPrincipalName=='andre.darby@cogitativo.com'].{Name:displayName, UPN:userPrincipalName}" -o table

echo.
echo Checking direct role assignments for andre.darby@cogitativo.com on storage...
call az role assignment list --assignee "andre.darby@cogitativo.com" --all | findstr "pbivend9084"

echo.
echo If you're not in the group, let's add you...
call az ad group member add --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --member-id andre.darby@cogitativo.com

echo.
echo === Access check complete ===
pause