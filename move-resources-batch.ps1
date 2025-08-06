# Move Resources to Isolated RG
Write-Host "Moving resources to rg-pbi-vendor-isolated..." -ForegroundColor Yellow

# Define resources
$resources = @(
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor",
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/networkInterfaces/vm-pbi-vendorVMNic",
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/disks/vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075",
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"
)

# Move resources
Write-Host "This will take a few minutes..." -ForegroundColor Yellow
$result = az resource move `
    --destination-group rg-pbi-vendor-isolated `
    --ids $resources[0] $resources[1] $resources[2] $resources[3] `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Resources moved successfully!" -ForegroundColor Green
} else {
    Write-Host "Error moving resources: $result" -ForegroundColor Red
    exit 1
}

# Verify move
Write-Host ""
Write-Host "Verifying resources in new resource group..." -ForegroundColor Yellow
az resource list -g rg-pbi-vendor-isolated --output table

Write-Host ""
Write-Host "✅ Move completed!" -ForegroundColor Green