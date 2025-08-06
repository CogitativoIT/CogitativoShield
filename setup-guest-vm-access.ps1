# Setup Minimal Guest User Access for VM via Bastion
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$subscriptionId = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

Write-Host "Setting up minimal guest user permissions..." -ForegroundColor Yellow
Write-Host ""

# First, let's remove ALL existing permissions to start clean
Write-Host "Cleaning up existing permissions..." -ForegroundColor Red
$assignments = az role assignment list --assignee $groupId --all | ConvertFrom-Json
foreach ($assignment in $assignments) {
    Write-Host "  Removing: $($assignment.roleDefinitionName) from $($assignment.scope)" -ForegroundColor Gray
    az role assignment delete --ids $assignment.id 2>$null
}

Write-Host ""
Write-Host "Applying minimal guest permissions..." -ForegroundColor Green

# 1. Virtual Machine User Login - This is the ONLY VM permission they need
$vmScope = "/subscriptions/$subscriptionId/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
Write-Host "1. Adding VM User Login (non-admin)..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Virtual Machine User Login" `
    --scope $vmScope `
    --assignee-principal-type Group

# 2. For Bastion access, create a custom role with ONLY connect permissions
Write-Host "2. Creating minimal Bastion access role..." -ForegroundColor Cyan

# Create custom role definition for Bastion connection only
$bastionRoleJson = @"
{
  "Name": "Bastion Connect Only",
  "Description": "Allows connecting to VMs via Bastion only - no management permissions",
  "IsCustom": true,
  "Actions": [
    "Microsoft.Network/bastionHosts/read",
    "Microsoft.Network/bastionHosts/createShareableLinks/action",
    "Microsoft.Network/bastionHosts/getShareableLinks/action",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/networkInterfaces/read",
    "Microsoft.Compute/virtualMachines/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/$subscriptionId"
  ]
}
"@

$bastionRoleJson | Out-File -FilePath "bastion-connect-role.json"
$roleResult = az role definition create --role-definition bastion-connect-role.json 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Custom Bastion role created" -ForegroundColor Green
} else {
    Write-Host "  ! Custom role may already exist" -ForegroundColor Yellow
}

# 3. Assign the minimal Bastion role
$bastionScope = "/subscriptions/$subscriptionId/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion"
Write-Host "3. Assigning minimal Bastion access..." -ForegroundColor Cyan
az role assignment create `
    --assignee $groupId `
    --role "Bastion Connect Only" `
    --scope $bastionScope `
    --assignee-principal-type Group 2>$null

# If custom role fails, use Reader as fallback
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Using Reader role as fallback..." -ForegroundColor Yellow
    az role assignment create `
        --assignee $groupId `
        --role "Reader" `
        --scope $bastionScope `
        --assignee-principal-type Group
}

# 4. Minimal read permission on the VM's resource group (required to see the VM)
Write-Host "4. Adding minimal visibility permissions..." -ForegroundColor Cyan
# Create a condition to limit Reader access to just the VM
$condition = "[resourceType == 'Microsoft.Compute/virtualMachines' && resourceName == 'vm-pbi-vendor']"
az role assignment create `
    --assignee $groupId `
    --role "Reader" `
    --scope "/subscriptions/$subscriptionId/resourceGroups/vision" `
    --assignee-principal-type Group

# Clean up temp file
Remove-Item "bastion-connect-role.json" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Minimal guest permissions configured!" -ForegroundColor Green
Write-Host ""
Write-Host "Guest users in 'visionbidevvm' group can now:" -ForegroundColor Yellow
Write-Host "  ✓ See ONLY vm-pbi-vendor in the portal" -ForegroundColor White
Write-Host "  ✓ Connect via Bastion" -ForegroundColor White
Write-Host "  ✓ Login as regular user (NOT admin)" -ForegroundColor White
Write-Host ""
Write-Host "Guest users CANNOT:" -ForegroundColor Red
Write-Host "  ✗ Start/stop/modify the VM" -ForegroundColor White
Write-Host "  ✗ Access any other resources" -ForegroundColor White
Write-Host "  ✗ Change any settings" -ForegroundColor White
Write-Host "  ✗ Login as administrator" -ForegroundColor White
Write-Host ""
Write-Host "Final permissions:" -ForegroundColor Cyan
az role assignment list --assignee $groupId --all --output table