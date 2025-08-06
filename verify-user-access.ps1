# Verify and Troubleshoot User Access

Write-Host "=== Troubleshooting VM Access ===" -ForegroundColor Cyan
Write-Host ""

# Check if the test user is actually in the group
Write-Host "1. Checking group membership..." -ForegroundColor Yellow
Write-Host "   Please run: az ad group member list --group visionbidevvm --output table" -ForegroundColor White
Write-Host ""

# Check role assignments
Write-Host "2. Current role assignments for the group:" -ForegroundColor Yellow
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
az role assignment list --assignee $groupId --all --output json | ConvertFrom-Json | ForEach-Object {
    Write-Host "   Role: $($_.roleDefinitionName)" -ForegroundColor Green
    Write-Host "   Scope: $($_.scope)" -ForegroundColor Gray
    Write-Host ""
}

# Additional permissions that might be needed
Write-Host "3. Adding additional required permissions..." -ForegroundColor Yellow

# Add Bastion Reader role specifically
$bastionScope = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion"
Write-Host "   Adding direct Bastion Reader access..." -ForegroundColor Cyan
az role assignment create --assignee $groupId --role "Reader" --scope $bastionScope 2>$null

# Add network permissions for the VM's subnet
$subnetScope = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/snet-pbi-vendor"
Write-Host "   Adding subnet read permissions..." -ForegroundColor Cyan
az role assignment create --assignee $groupId --role "Reader" --scope $subnetScope 2>$null

Write-Host ""
Write-Host "=== Important Notes ===" -ForegroundColor Yellow
Write-Host "1. Permission propagation can take up to 30 minutes" -ForegroundColor White
Write-Host "2. User must log out and back in to Azure Portal" -ForegroundColor White
Write-Host "3. Clear browser cache if issues persist" -ForegroundColor White
Write-Host ""
Write-Host "4. If still having issues, try:" -ForegroundColor Yellow
Write-Host "   • Have the user navigate directly to the VM:" -ForegroundColor White
Write-Host "     https://portal.azure.com/#@24317511-81a4-42fb-bea5-f4b0735acba5/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" -ForegroundColor Gray
Write-Host ""
Write-Host "   • Or search for 'vm-pbi-vendor' in the portal search bar" -ForegroundColor White