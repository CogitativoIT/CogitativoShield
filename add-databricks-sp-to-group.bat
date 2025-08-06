@echo off
echo === Adding sp-databricks to visionbidevvm Group ===
echo.

echo Service Principal Details:
echo Name: sp-databricks
echo App ID: 9a3351d0-f816-4e6f-95d4-f90ac882a479
echo.

echo Adding sp-databricks to visionbidevvm group...
call az ad group member add --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --member-id "9a3351d0-f816-4e6f-95d4-f90ac882a479"

echo.
echo Verifying group membership...
call az ad group member list --group "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --query "[?appId=='9a3351d0-f816-4e6f-95d4-f90ac882a479' || userPrincipalName=='jason.jones@cogitativo.com'].{Name:displayName, Type:objectType, Id:objectId}" -o table

echo.
echo === Configuration Complete ===
echo.
echo visionbidevvm group now contains:
echo - sp-databricks (service principal for Databricks)
echo - jason.jones@cogitativo.com (user)
echo - Any other existing members
echo.
echo Both have Storage Blob Data Contributor access to pbivend9084
echo.
pause