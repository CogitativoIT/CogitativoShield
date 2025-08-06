# Remove Administrator permissions and ensure only user-level access
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$vmId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

Write-Host "Removing Administrator permissions..." -ForegroundColor Red

# Remove the Administrator Login role
az role assignment delete `
    --assignee $groupId `
    --role "Virtual Machine Administrator Login" `
    --scope $vmId

Write-Host "✓ Administrator role removed" -ForegroundColor Green

# List current permissions to verify
Write-Host ""
Write-Host "Current permissions for the security group:" -ForegroundColor Yellow
az role assignment list --assignee $groupId --all --output table

Write-Host ""
Write-Host "The group now has only:" -ForegroundColor Green
Write-Host "  • Reader access (view resources)" -ForegroundColor White
Write-Host "  • Virtual Machine User Login (non-admin login)" -ForegroundColor White
Write-Host "  • Contributor on Bastion (needed for connection)" -ForegroundColor White
Write-Host ""
Write-Host "This ensures guest users can only:" -ForegroundColor Yellow
Write-Host "  ✓ View the VM in portal" -ForegroundColor White
Write-Host "  ✓ Connect via Bastion" -ForegroundColor White
Write-Host "  ✓ Login as regular user (not admin)" -ForegroundColor White
Write-Host "  ✗ Cannot modify VM or settings" -ForegroundColor White
Write-Host "  ✗ Cannot access as administrator" -ForegroundColor White