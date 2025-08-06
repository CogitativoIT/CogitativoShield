# Fix 403 Error - Comprehensive Permission Setup
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$subscriptionId = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

Write-Host "Fixing 403 error for guest VM access..." -ForegroundColor Yellow
Write-Host ""

# The 403 error suggests the user can't even see the VM
# For portal access, users need Reader at the resource group level with conditions

Write-Host "Step 1: Adding Reader access to vision resource group..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision" `
    --assignee-principal-type Group

Write-Host "Step 2: Adding VM User Login to specific VM..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Virtual Machine User Login" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" `
    --assignee-principal-type Group

Write-Host "Step 3: Adding Reader access to Bastion resource group..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/openai-dev" `
    --assignee-principal-type Group

# Wait for propagation
Write-Host ""
Write-Host "Waiting 30 seconds for permission propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Step 4: Verifying permissions..." -ForegroundColor Cyan
$assignments = az role assignment list --assignee $groupId --all | ConvertFrom-Json

if ($assignments.Count -eq 0) {
    Write-Host "ERROR: No role assignments found!" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Try using az ad group show to get proper ID
    $groupInfo = az ad group show --group $groupId | ConvertFrom-Json
    Write-Host "Group Display Name: $($groupInfo.displayName)" -ForegroundColor White
    Write-Host "Group ID: $($groupInfo.id)" -ForegroundColor White
} else {
    Write-Host "Found $($assignments.Count) role assignments:" -ForegroundColor Green
    foreach ($assignment in $assignments) {
        Write-Host "  - $($assignment.roleDefinitionName) on $($assignment.scope)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=== Troubleshooting Steps ===" -ForegroundColor Yellow
Write-Host "1. Verify user is in the group:" -ForegroundColor White
Write-Host "   az ad group member list --group visionbidevvm --output table" -ForegroundColor Gray
Write-Host ""
Write-Host "2. User must:" -ForegroundColor White
Write-Host "   - Log out completely from Azure Portal" -ForegroundColor Gray
Write-Host "   - Clear browser cache and cookies" -ForegroundColor Gray
Write-Host "   - Log back in" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Try direct VM URL:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@$($subscriptionId)/resource/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor/overview" -ForegroundColor Gray
Write-Host ""
Write-Host "4. If still failing, check tenant:" -ForegroundColor White
Write-Host "   - Ensure user is logging into correct tenant" -ForegroundColor Gray
Write-Host "   - Guest users must accept invitation first" -ForegroundColor Gray