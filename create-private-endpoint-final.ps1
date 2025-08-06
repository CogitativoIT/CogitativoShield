# Create Private Endpoint with Cross-RG Support
Write-Host "Creating Private Endpoint for Storage..." -ForegroundColor Yellow

# Get the subnet ID from the vision RG
$subnetId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/gitlab-private-subnet"
$storageId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"

# Create the private endpoint
Write-Host "Attempting to create PE..." -ForegroundColor Cyan
$peResult = az network private-endpoint create `
    --name pe-pbivend9084 `
    --resource-group rg-pbi-vendor-isolated `
    --subnet $subnetId `
    --private-connection-resource-id $storageId `
    --group-id dfs `
    --connection-name pe-conn-pbivend9084 `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Private endpoint created successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to create PE: $peResult" -ForegroundColor Red
}

# Check current status
Write-Host ""
Write-Host "Checking private endpoint status..." -ForegroundColor Yellow
az network private-endpoint list -g rg-pbi-vendor-isolated --output table