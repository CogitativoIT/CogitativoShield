# Add Bastion-specific permissions
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"

Write-Host "Adding Bastion connection permissions..." -ForegroundColor Yellow

# For Bastion connection, users need specific permissions
# Let's add the user as a Contributor on just the Bastion resource
$bastionId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion"

Write-Host "Adding Bastion Contributor role..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Contributor" `
    --scope $bastionId `
    --assignee-principal-type Group

# Also ensure they have the data action for VM login
Write-Host "Ensuring VM login data actions..." -ForegroundColor Cyan
$vmId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

# Try both User Login and Administrator Login to see which works
az role assignment create `
    --assignee $groupId `
    --role "Virtual Machine Administrator Login" `
    --scope $vmId `
    --assignee-principal-type Group

Write-Host ""
Write-Host "✅ Additional permissions added!" -ForegroundColor Green
Write-Host ""
Write-Host "Please ask your test user to:" -ForegroundColor Yellow
Write-Host "1. Log out of Azure Portal completely" -ForegroundColor White
Write-Host "2. Clear browser cache (Ctrl+Shift+Delete)" -ForegroundColor White
Write-Host "3. Log back in" -ForegroundColor White
Write-Host "4. Navigate to Virtual Machines and search for 'vm-pbi-vendor'" -ForegroundColor White
Write-Host "5. Click Connect > Bastion" -ForegroundColor White