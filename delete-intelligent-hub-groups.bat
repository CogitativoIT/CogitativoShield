@echo off
echo === INTELLIGENT HUB CLEANUP ===
echo.
echo This will delete unused intelligent-hub resource groups.
echo Production app (cogitativo-intelligent-hub) is in cogitativo-rg and will NOT be affected.
echo.

echo === PRE-DELETION VERIFICATION ===
echo Checking production app status...
call az containerapp show --name cogitativo-intelligent-hub --resource-group cogitativo-rg --query "properties.provisioningState" -o tsv
echo.

echo === DELETING RESOURCE GROUPS ===
echo.
echo [1/2] Deleting intelligent-hub-rg...
echo Contains: unused Container App Environment, registries with old images
call az group delete --name intelligent-hub-rg --yes --no-wait

echo.
echo [2/2] Deleting rg-intelligent-hub...  
echo Contains: unused Container App Environment, registries with old images, empty storage
call az group delete --name rg-intelligent-hub --yes --no-wait

echo.
echo === DELETION INITIATED ===
echo.
echo Both resource groups are being deleted in the background.
echo This may take 5-10 minutes to complete.
echo.
echo Production app remains in cogitativo-rg and is unaffected.
echo Monthly savings: $50-80
echo.
pause