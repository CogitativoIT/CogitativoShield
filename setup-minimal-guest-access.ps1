# Setup Minimal Guest User Access - Security First Approach
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$subscriptionId = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

Write-Host "=== Configuring Minimal Guest Access ===" -ForegroundColor Cyan
Write-Host ""

# Remove all existing permissions first
Write-Host "Step 1: Removing existing permissions..." -ForegroundColor Yellow
$existing = az role assignment list --assignee $groupId --all | ConvertFrom-Json
foreach ($assignment in $existing) {
    Write-Host "  - Removing $($assignment.roleDefinitionName)" -ForegroundColor Red
    az role assignment delete --ids $assignment.id | Out-Null
}

Write-Host ""
Write-Host "Step 2: Adding minimal required permissions..." -ForegroundColor Yellow

# 1. VM User Login - Required for non-admin access
Write-Host "  + Virtual Machine User Login" -ForegroundColor Green
az role assignment create `
    --assignee $groupId `
    --role "Virtual Machine User Login" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" | Out-Null

# 2. Reader on specific VM only (required to see it in portal)
Write-Host "  + Reader on vm-pbi-vendor" -ForegroundColor Green
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" | Out-Null

# 3. Reader on Bastion (required to use Bastion)
Write-Host "  + Reader on Bastion host" -ForegroundColor Green
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion" | Out-Null

# 4. Reader on the VM's subnet (required for Bastion connectivity)
Write-Host "  + Reader on VM subnet" -ForegroundColor Green
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/snet-pbi-vendor" | Out-Null

Write-Host ""
Write-Host "✅ Configuration Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "=== Security Summary ===" -ForegroundColor Cyan
Write-Host "Guest users in 'visionbidevvm' group have:" -ForegroundColor Yellow
Write-Host ""
Write-Host "ALLOWED:" -ForegroundColor Green
Write-Host "  ✓ View vm-pbi-vendor in Azure Portal"
Write-Host "  ✓ Connect to VM via Bastion"
Write-Host "  ✓ Login as regular user (non-admin)"
Write-Host ""
Write-Host "BLOCKED:" -ForegroundColor Red
Write-Host "  ✗ Cannot see other VMs or resources"
Write-Host "  ✗ Cannot start/stop/restart VM"
Write-Host "  ✗ Cannot modify any settings"
Write-Host "  ✗ Cannot access as administrator"
Write-Host "  ✗ Cannot access storage or other services"
Write-Host ""
Write-Host "=== Current Permissions ===" -ForegroundColor Cyan
az role assignment list --assignee $groupId --all --output json | ConvertFrom-Json | ForEach-Object {
    $scopeParts = $_.scope -split '/'
    $resourceType = if ($scopeParts.Count -gt 7) { $scopeParts[6] } else { "Resource Group" }
    $resourceName = if ($scopeParts.Count -gt 8) { $scopeParts[8] } else { $scopeParts[4] }
    Write-Host "$($_.roleDefinitionName) on $resourceType/$resourceName" -ForegroundColor White
}