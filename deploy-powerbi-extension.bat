@echo off
echo Installing Power BI Desktop on VM via Custom Script Extension...
echo.

call az vm extension set --resource-group rg-pbi-vendor-isolated --vm-name vm-pbi-vendor --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/vm-simple-windows/installWebServer.ps1\"],\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \\\"$tempPath='C:\\temp'; New-Item -ItemType Directory -Force -Path $tempPath; Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe' -OutFile '$tempPath\\PBIDesktop.exe'; Start-Process -FilePath '$tempPath\\PBIDesktop.exe' -ArgumentList '/quiet', '/norestart', 'ACCEPT_EULA=1' -Wait\\\"\"}"

echo.
echo Power BI Desktop installation initiated!
echo The VM will install Power BI Desktop in the background.
echo.
pause