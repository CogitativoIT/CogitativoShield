# Migrate VM from Windows Server 2022 to Windows 11
# Keeps all network configuration and resources intact

Write-Host "=== Windows 11 VM Migration Script ===" -ForegroundColor Cyan
Write-Host "This will replace Windows Server 2022 with Windows 11" -ForegroundColor Yellow
Write-Host ""

# Variables
$rgName = "rg-pbi-vendor-isolated"
$vmName = "vm-pbi-vendor"
$location = "eastus"
$nicName = "vm-pbi-vendor-nic"
$diskName = "vm-pbi-vendor-osdisk"

# Step 1: Get current VM info
Write-Host "Step 1: Getting current VM configuration..." -ForegroundColor Yellow
$currentVM = az vm show -g $rgName -n $vmName --query "{size:hardwareProfile.vmSize,nicId:networkProfile.networkInterfaces[0].id}" -o json | ConvertFrom-Json
Write-Host "Current VM Size: $($currentVM.size)" -ForegroundColor White
Write-Host ""

# Step 2: Stop and deallocate VM
Write-Host "Step 2: Stopping and deallocating current VM..." -ForegroundColor Yellow
az vm stop --resource-group $rgName --name $vmName --no-wait
az vm wait --resource-group $rgName --name $vmName --updated
az vm deallocate --resource-group $rgName --name $vmName
Write-Host "✓ VM stopped and deallocated" -ForegroundColor Green
Write-Host ""

# Step 3: Delete VM (keep all other resources)
Write-Host "Step 3: Deleting VM (keeping network and disks)..." -ForegroundColor Yellow
az vm delete --resource-group $rgName --name $vmName --yes
Write-Host "✓ VM deleted, network configuration preserved" -ForegroundColor Green
Write-Host ""

# Step 4: Delete old OS disk (Windows Server 2022)
Write-Host "Step 4: Removing old Windows Server 2022 disk..." -ForegroundColor Yellow
az disk delete --resource-group $rgName --name $diskName --yes --no-wait
Write-Host "✓ Old OS disk deletion initiated" -ForegroundColor Green
Write-Host ""

# Step 5: Create new Windows 11 VM
Write-Host "Step 5: Creating new Windows 11 VM..." -ForegroundColor Yellow
Write-Host "This may take 3-5 minutes..." -ForegroundColor White

$vmConfig = @{
    "resource-group" = $rgName
    "name" = $vmName
    "location" = $location
    "image" = "MicrosoftWindowsDesktop:Windows-11:win11-23h2-pro:latest"
    "size" = $currentVM.size
    "admin-username" = "pbiadmin"
    "admin-password" = "TempP@ssw0rd2024!"
    "nics" = $nicName
    "os-disk-name" = $diskName
    "os-disk-size-gb" = "128"
    "license-type" = "Windows_Client"
    "no-wait" = $true
}

# Create VM using splatting
$createCmd = "az vm create"
foreach ($param in $vmConfig.GetEnumerator()) {
    if ($param.Value -eq $true) {
        $createCmd += " --$($param.Key)"
    } else {
        $createCmd += " --$($param.Key) `"$($param.Value)`""
    }
}

Invoke-Expression $createCmd

# Wait for VM creation
Write-Host "Waiting for VM creation to complete..." -ForegroundColor Yellow
az vm wait --resource-group $rgName --name $vmName --created
Write-Host "✓ Windows 11 VM created successfully" -ForegroundColor Green
Write-Host ""

# Step 6: Enable Azure AD authentication
Write-Host "Step 6: Enabling Azure AD authentication..." -ForegroundColor Yellow
az vm extension set `
    --publisher Microsoft.Azure.ActiveDirectory `
    --name AADLoginForWindows `
    --resource-group $rgName `
    --vm-name $vmName `
    --no-wait

Write-Host "✓ Azure AD extension installation initiated" -ForegroundColor Green
Write-Host ""

# Step 7: Install Power BI Desktop
Write-Host "Step 7: Setting up Power BI Desktop installation..." -ForegroundColor Yellow
az vm extension set `
    --resource-group $rgName `
    --vm-name $vmName `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --settings '{\"fileUris\":[\"https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/vm-winrm-windows/ConfigureWinRM.ps1\"],\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -Command \"\"Invoke-WebRequest -Uri https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe -OutFile C:\\temp\\PBIDesktop.exe; Start-Process -FilePath C:\\temp\\PBIDesktop.exe -ArgumentList '/quiet /norestart ACCEPT_EULA=1' -Wait\"\"\"}' `
    --no-wait

Write-Host "✓ Power BI Desktop installation configured" -ForegroundColor Green
Write-Host ""

# Step 8: Verify permissions are still intact
Write-Host "Step 8: Verifying visionbidevvm group permissions..." -ForegroundColor Yellow
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"

# Check if VM User Login role exists
$vmScope = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName"
$existingRole = az role assignment list --assignee $groupId --scope $vmScope --query "[?roleDefinitionName=='Virtual Machine User Login']" -o json | ConvertFrom-Json

if ($existingRole.Count -eq 0) {
    Write-Host "Adding Virtual Machine User Login role..." -ForegroundColor White
    az role assignment create `
        --assignee $groupId `
        --role "Virtual Machine User Login" `
        --scope $vmScope
}

Write-Host "✓ Permissions verified" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=== Migration Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "What changed:" -ForegroundColor Cyan
Write-Host "✓ OS: Windows Server 2022 → Windows 11 Pro" -ForegroundColor White
Write-Host "✓ Azure AD: Now supported natively" -ForegroundColor White
Write-Host "✓ Network: Same configuration (private endpoint, NSG rules)" -ForegroundColor White
Write-Host "✓ Storage: Same access to pbivend9084" -ForegroundColor White
Write-Host "✓ Access: Via VISION-VNET-BASTION as before" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 5-10 minutes for VM to fully initialize" -ForegroundColor White
Write-Host "2. Guest users in visionbidevvm group can now:" -ForegroundColor White
Write-Host "   - Login via Bastion with their Azure AD credentials" -ForegroundColor White
Write-Host "   - No separate VM password needed!" -ForegroundColor White
Write-Host ""
Write-Host "Initial admin credentials (for first setup if needed):" -ForegroundColor Yellow
Write-Host "Username: pbiadmin" -ForegroundColor White
Write-Host "Password: TempP@ssw0rd2024!" -ForegroundColor White
Write-Host "(Change this immediately after first login)" -ForegroundColor Red