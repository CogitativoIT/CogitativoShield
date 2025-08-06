@echo off
echo === Deleting Unnecessary Network Watchers ===
echo.

REM Keep only eastus, eastus2, and westus watchers
echo Deleting Network Watchers in regions where you have no resources...
echo.

call az network watcher delete --name NetworkWatcher_northeurope --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_westeurope --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_eastasia --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_southeastasia --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_northcentralus --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_centralus --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_southcentralus --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_westcentralus --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_canadacentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_canadaeast --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_brazilsouth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_francecentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_germanywestcentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_uksouth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_ukwest --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_japaneast --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_japanwest --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_australiaeast --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_australiasoutheast --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_australiacentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_centralindia --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_southindia --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_westindia --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_koreacentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_koreasouth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_norwayeast --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_switzerlandnorth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_uaenorth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_southafricanorth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_swedencentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_qatarcentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_polandcentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_israelcentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_italynorth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_spaincentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_mexicocentral --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_newzealandnorth --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_westus3 --resource-group NetworkWatcherRG
call az network watcher delete --name NetworkWatcher_westus2 --resource-group NetworkWatcherRG

echo.
echo Keeping only these Network Watchers:
echo - NetworkWatcher_eastus (where most resources are)
echo - NetworkWatcher_eastus2 (app-rg location)
echo - NetworkWatcher_westus (cloud shell storage)
echo.
echo Cleanup complete!
pause