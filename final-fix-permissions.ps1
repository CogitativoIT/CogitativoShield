# Final Fix - Ensure Permissions are Applied
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"

Write-Host "Applying permissions with explicit parameters..." -ForegroundColor Yellow

# 1. Reader on Resource Group (required to see resources)
Write-Host "1. Reader on vision RG..." -ForegroundColor Cyan
$result1 = az role assignment create `
    --assignee-object-id $groupId `
    --assignee-principal-type Group `
    --role "Reader" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision" `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Success" -ForegroundColor Green
} else {
    Write-Host "   ✗ Failed: $result1" -ForegroundColor Red
}

# 2. VM User Login
Write-Host "2. VM User Login..." -ForegroundColor Cyan
$result2 = az role assignment create `
    --assignee-object-id $groupId `
    --assignee-principal-type Group `
    --role "Virtual Machine User Login" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Success" -ForegroundColor Green
} else {
    Write-Host "   ✗ Failed: $result2" -ForegroundColor Red
}

# 3. Reader on Bastion RG
Write-Host "3. Reader on openai-dev RG..." -ForegroundColor Cyan
$result3 = az role assignment create `
    --assignee-object-id $groupId `
    --assignee-principal-type Group `
    --role "Reader" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev" `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Success" -ForegroundColor Green
} else {
    Write-Host "   ✗ Failed: $result3" -ForegroundColor Red
}

Write-Host ""
Write-Host "Checking applied permissions..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$assignments = az role assignment list --assignee $groupId --all --output json | ConvertFrom-Json
Write-Host "Found $($assignments.Count) assignments" -ForegroundColor Cyan

foreach ($assignment in $assignments) {
    $scope = $assignment.scope -split '/'
    $resource = if ($scope.Count -gt 8) { $scope[8] } else { $scope[4] }
    Write-Host "  • $($assignment.roleDefinitionName) on $resource" -ForegroundColor White
}

Write-Host ""
Write-Host "=== IMPORTANT ===" -ForegroundColor Yellow
Write-Host "Test user: tester1@cogitativo.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "User MUST:" -ForegroundColor Red
Write-Host "1. Log out of Azure Portal completely" -ForegroundColor White
Write-Host "2. Close ALL browser windows" -ForegroundColor White
Write-Host "3. Clear browser cache (Ctrl+Shift+Delete)" -ForegroundColor White
Write-Host "4. Open new browser window" -ForegroundColor White
Write-Host "5. Login to portal.azure.com" -ForegroundColor White
Write-Host "6. Search for 'vm-pbi-vendor'" -ForegroundColor White
Write-Host ""
Write-Host "Alternative: Use InPrivate/Incognito mode" -ForegroundColor Cyan