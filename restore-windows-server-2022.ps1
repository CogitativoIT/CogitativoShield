# Restore Windows Server 2022 for multiple RDP sessions
Write-Host "=== Restoring Windows Server 2022 ===" -ForegroundColor Cyan
Write-Host "This will support multiple concurrent RDP sessions" -ForegroundColor Yellow
Write-Host ""

# Variables
$rgName = "rg-pbi-vendor-isolated"
$vmName = "vm-pbi-vendor"
$location = "eastus"
$nicName = "vm-pbi-vendorVMNic"
$diskName = "vm-pbi-vendor-osdisk"

# Step 1: Stop and delete current Windows 11 VM
Write-Host "Step 1: Stopping current Windows 11 VM..." -ForegroundColor Yellow
az vm stop --resource-group $rgName --name $vmName --no-wait
az vm wait --resource-group $rgName --name $vmName --updated
az vm deallocate --resource-group $rgName --name $vmName
Write-Host "✓ VM stopped" -ForegroundColor Green

Write-Host "Step 2: Deleting Windows 11 VM..." -ForegroundColor Yellow
az vm delete --resource-group $rgName --name $vmName --yes
Write-Host "✓ VM deleted" -ForegroundColor Green

# Step 3: Delete Windows 11 OS disk
Write-Host "Step 3: Removing Windows 11 disk..." -ForegroundColor Yellow
az disk delete --resource-group $rgName --name $diskName --yes --no-wait
Write-Host "✓ Disk deletion initiated" -ForegroundColor Green

# Step 4: Create Windows Server 2022 VM
Write-Host "Step 4: Creating Windows Server 2022 VM..." -ForegroundColor Yellow
Write-Host "This supports multiple RDP sessions by default" -ForegroundColor White

az vm create `
    --resource-group $rgName `
    --name $vmName `
    --location $location `
    --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-g2:latest `
    --size Standard_D4s_v3 `
    --admin-username pbiadmin `
    --admin-password "SecureP@ssw0rd2024!" `
    --nics $nicName `
    --os-disk-name $diskName `
    --os-disk-size-gb 128 `
    --license-type Windows_Server

Write-Host "✓ Windows Server 2022 VM created" -ForegroundColor Green

# Step 5: Install Power BI Desktop
Write-Host "Step 5: Configuring Power BI Desktop installation..." -ForegroundColor Yellow
az vm extension set `
    --resource-group $rgName `
    --vm-name $vmName `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --settings '{\"fileUris\":[],\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \\\"$tempPath=''C:\\temp''; New-Item -ItemType Directory -Force -Path $tempPath; Invoke-WebRequest -Uri ''https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe'' -OutFile ''$tempPath\\PBIDesktop.exe''; Start-Process -FilePath ''$tempPath\\PBIDesktop.exe'' -ArgumentList ''/quiet'', ''/norestart'', ''ACCEPT_EULA=1'' -Wait\\\"\"}' `
    --no-wait

Write-Host "✓ Power BI installation configured" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "=== Windows Server 2022 Restored! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Benefits:" -ForegroundColor Cyan
Write-Host "✓ Multiple concurrent RDP sessions supported" -ForegroundColor White
Write-Host "✓ No additional RDP licensing required" -ForegroundColor White
Write-Host "✓ Same network configuration maintained" -ForegroundColor White
Write-Host "✓ Power BI Desktop will be installed" -ForegroundColor White
Write-Host ""
Write-Host "Admin credentials:" -ForegroundColor Yellow
Write-Host "Username: pbiadmin" -ForegroundColor White
Write-Host "Password: SecureP@ssw0rd2024!" -ForegroundColor White
Write-Host ""
Write-Host "Note: Create local user accounts for vendors since" -ForegroundColor Yellow
Write-Host "Windows Server 2022 doesn't support Azure AD join" -ForegroundColor Yellow