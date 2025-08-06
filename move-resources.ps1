# Move Resources to Isolated Resource Group
Write-Host "Preparing to move resources to isolated resource group..." -ForegroundColor Yellow

# Get all related resources
Write-Host "Identifying resources to move..." -ForegroundColor Cyan

# VM and its dependencies
$vmId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
$storageId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"

# Get VM's network interface
$vm = az vm show -g vision -n vm-pbi-vendor | ConvertFrom-Json
$nicId = $vm.networkProfile.networkInterfaces[0].id

# Get VM's disk
$diskId = $vm.storageProfile.osDisk.managedDisk.id

# List all resources to move
$resourcesToMove = @(
    $vmId,
    $nicId,
    $diskId,
    $storageId
)

Write-Host ""
Write-Host "Resources to move:" -ForegroundColor Yellow
foreach ($resource in $resourcesToMove) {
    $parts = $resource -split '/'
    $type = $parts[6]
    $name = $parts[8]
    Write-Host "  - $type/$name" -ForegroundColor White
}

# Note: Private endpoint needs to be recreated, not moved
Write-Host ""
Write-Host "Note: Private endpoint will need to be recreated after move" -ForegroundColor Yellow

Write-Host ""
Write-Host "Starting resource move..." -ForegroundColor Green

# Move resources
az resource move `
    --destination-group rg-pbi-vendor-isolated `
    --ids $vmId $nicId $diskId $storageId

Write-Host ""
Write-Host "Resources moved successfully!" -ForegroundColor Green

# Update private endpoint
Write-Host ""
Write-Host "Recreating private endpoint in new resource group..." -ForegroundColor Yellow

# Delete old private endpoint
az network private-endpoint delete `
    --name pe-pbivend9084 `
    --resource-group vision `
    --yes

# Create new private endpoint
az network private-endpoint create `
    --name pe-pbivend9084 `
    --resource-group rg-pbi-vendor-isolated `
    --vnet-name vision-vnet `
    --subnet gitlab-private-subnet `
    --private-connection-resource-id $storageId.Replace("vision", "rg-pbi-vendor-isolated") `
    --group-id dfs `
    --connection-name pe-conn-pbivend9084

Write-Host ""
Write-Host "✅ All resources moved to isolated resource group!" -ForegroundColor Green