# Assign VM Bastion Access to Security Group
Write-Host "Assigning permissions to security group..." -ForegroundColor Yellow

# Get the group object ID
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"

# Assign custom role to the VM
Write-Host "Assigning custom role for VM access..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Power BI VM Bastion User" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" `
    --assignee-principal-type Group

# Also need to assign Reader role to the Bastion host
Write-Host "Assigning Reader role for Bastion host..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion" `
    --assignee-principal-type Group

# Assign Virtual Machine User Login role for actual VM login
Write-Host "Assigning VM User Login role..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Virtual Machine User Login" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" `
    --assignee-principal-type Group

Write-Host ""
Write-Host "✅ Permissions assigned successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Security Group Details:" -ForegroundColor Yellow
Write-Host "  Name: visionbidevvm" -ForegroundColor White
Write-Host "  ID: $groupId" -ForegroundColor White
Write-Host ""
Write-Host "Permissions granted:" -ForegroundColor Yellow
Write-Host "  • View and connect to vm-pbi-vendor via Bastion" -ForegroundColor White
Write-Host "  • Read-only access to Bastion host" -ForegroundColor White
Write-Host "  • Virtual Machine User Login rights" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create a user in Azure AD" -ForegroundColor White
Write-Host "  2. Add the user to the 'visionbidevvm' security group" -ForegroundColor White
Write-Host "  3. User can then access the VM via Azure Portal > Bastion" -ForegroundColor White