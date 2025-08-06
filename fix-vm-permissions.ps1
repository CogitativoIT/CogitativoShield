# Fix VM Access Permissions for Security Group
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$subscriptionId = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

Write-Host "Fixing permissions for visionbidevvm security group..." -ForegroundColor Yellow

# First, let's use built-in roles that are known to work
# 1. Reader role at resource group level
Write-Host "Assigning Reader role at resource group level..." -ForegroundColor Cyan
$rgScope = "/subscriptions/$subscriptionId/resourceGroups/vision"
az role assignment create --assignee $groupId --role "Reader" --scope $rgScope

# 2. Virtual Machine User Login at VM level
Write-Host "Assigning Virtual Machine User Login role..." -ForegroundColor Cyan
$vmScope = "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
az role assignment create --assignee $groupId --role "Virtual Machine User Login" --scope $vmScope

# 3. Reader role for the Bastion in openai-dev
Write-Host "Assigning Reader role for Bastion..." -ForegroundColor Cyan
$bastionRgScope = "/subscriptions/$subscriptionId/resourceGroups/openai-dev"
az role assignment create --assignee $groupId --role "Reader" --scope $bastionRgScope

# List all assignments to verify
Write-Host ""
Write-Host "Verifying role assignments..." -ForegroundColor Yellow
az role assignment list --assignee $groupId --output table

Write-Host ""
Write-Host "✅ Permissions fixed!" -ForegroundColor Green
Write-Host ""
Write-Host "The security group now has:" -ForegroundColor Yellow
Write-Host "  • Reader access to vision resource group" -ForegroundColor White
Write-Host "  • VM User Login access to vm-pbi-vendor" -ForegroundColor White
Write-Host "  • Reader access to openai-dev (for Bastion)" -ForegroundColor White
Write-Host ""
Write-Host "Users should now be able to:" -ForegroundColor Yellow
Write-Host "  1. See the VM in the portal" -ForegroundColor White
Write-Host "  2. Click Connect > Bastion" -ForegroundColor White
Write-Host "  3. Login with VM credentials" -ForegroundColor White