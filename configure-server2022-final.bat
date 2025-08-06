@echo off
echo === Configuring Windows Server 2022 Final Setup ===
echo.

echo 1. Granting VM User Login to visionbidevvm group...
call az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

echo.
echo 2. Installing Power BI Desktop via Custom Script Extension...
call az vm extension set --resource-group rg-pbi-vendor-isolated --vm-name vm-pbi-vendor --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \\\"$tempPath='C:\\temp'; New-Item -ItemType Directory -Force -Path $tempPath; Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe' -OutFile '$tempPath\\PBIDesktop.exe'; Start-Process -FilePath '$tempPath\\PBIDesktop.exe' -ArgumentList '/quiet', '/norestart', 'ACCEPT_EULA=1' -Wait\\\"\"}"

echo.
echo === Configuration Complete! ===
echo.
echo Windows Server 2022 Benefits:
echo - Multiple concurrent RDP sessions supported
echo - No additional licensing required
echo - Power BI Desktop installation in progress
echo.
echo Admin credentials:
echo Username: pbiadmin
echo Password: SecureP@ssw0rd2024!
echo.
echo For vendor access, create local users on the VM
echo.
pause