@echo off
echo Creating Windows 11 VM...
echo.

call az vm create ^
  --resource-group rg-pbi-vendor-isolated ^
  --name vm-pbi-vendor ^
  --location eastus ^
  --image MicrosoftWindowsDesktop:Windows-11:win11-23h2-pro:latest ^
  --size Standard_D4s_v3 ^
  --admin-username pbiadmin ^
  --admin-password "TempP@ssw0rd2024!" ^
  --nics vm-pbi-vendor-nic ^
  --os-disk-name vm-pbi-vendor-osdisk ^
  --os-disk-size-gb 128 ^
  --license-type Windows_Client

echo.
echo VM creation complete!
pause