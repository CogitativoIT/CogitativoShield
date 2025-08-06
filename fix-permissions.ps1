# Grant write permissions to visionbidevvm group
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$subscriptionId = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"
$resourceGroup = "rg-pbi-vendor-isolated"
$storageAccount = "pbivend9084"

# Build the scope
$scope = "/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Storage/storageAccounts/${storageAccount}"

Write-Host "Granting Storage Blob Data Contributor role to visionbidevvm group..." -ForegroundColor Green

# Create role assignment
$roleDefinitionId = "/subscriptions/${subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"  # Storage Blob Data Contributor

# Use Azure CLI with explicit parameters
$result = az role assignment create `
    --assignee $groupId `
    --role "ba92f5b4-2d11-453d-a403-e96b0029c9fe" `
    --scope $scope `
    2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success! Permissions granted." -ForegroundColor Green
    Write-Host "`nVerifying assignments..." -ForegroundColor Yellow
    
    # List assignments
    az role assignment list --assignee $groupId --scope $scope --output table
} else {
    Write-Host "Attempting alternative method..." -ForegroundColor Yellow
    
    # Try with role name
    az role assignment create `
        --assignee $groupId `
        --role "Storage Blob Data Contributor" `
        --resource-group $resourceGroup `
        --scope $scope
}

Write-Host "`nNote: Jason should wait 2-3 minutes before testing write operations." -ForegroundColor Cyan