# Test Azure CLI functionality
Write-Host "Testing Azure CLI..." -ForegroundColor Yellow

# Test 1: Basic command
Write-Host "Test 1: Account show" -ForegroundColor Cyan
$test1 = az account show --query name -o tsv
Write-Host "  Current subscription: $test1" -ForegroundColor Green

# Test 2: Resource listing
Write-Host ""
Write-Host "Test 2: List resource groups" -ForegroundColor Cyan
$test2 = az group list --query "[?contains(name, 'pbi')].name" -o tsv
Write-Host "  Found: $test2" -ForegroundColor Green

# Test 3: Path handling
Write-Host ""
Write-Host "Test 3: Path handling" -ForegroundColor Cyan
$resourceId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
$vmName = az vm show --ids "$resourceId" --query name -o tsv 2>$null
if ($vmName) {
    Write-Host "  VM found: $vmName" -ForegroundColor Green
} else {
    Write-Host "  Path issue detected - trying workaround..." -ForegroundColor Yellow
    # Workaround: Use resource group and name instead
    $vmName = az vm show -g vision -n vm-pbi-vendor --query name -o tsv
    Write-Host "  VM found using workaround: $vmName" -ForegroundColor Green
}

Write-Host ""
Write-Host "CLI tests completed." -ForegroundColor Green