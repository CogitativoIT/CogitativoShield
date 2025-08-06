# Fix Guest Access - Minimal Permissions Only
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"

Write-Host "Configuring minimal guest access..." -ForegroundColor Yellow

# Essential permissions only:
# 1. VM User Login
az role assignment create --assignee $groupId --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

# 2. Reader on VM
az role assignment create --assignee $groupId --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

# 3. Reader on Bastion
az role assignment create --assignee $groupId --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion"

# 4. Reader on subnet
az role assignment create --assignee $groupId --role "Reader" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/snet-pbi-vendor"

Write-Host ""
Write-Host "Done! Guest users now have minimal access to:" -ForegroundColor Green
Write-Host "- View and connect to vm-pbi-vendor only" -ForegroundColor White
Write-Host "- Login as regular user (not admin)" -ForegroundColor White
Write-Host ""
Write-Host "Current permissions:" -ForegroundColor Yellow
az role assignment list --assignee $groupId --output table