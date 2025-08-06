# Create Private Endpoint for Storage
$storageId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"

az network private-endpoint create `
    --name pe-pbivend9084 `
    --resource-group vision `
    --vnet-name vision-vnet `
    --subnet gitlab-private-subnet `
    --private-connection-resource-id $storageId `
    --group-id dfs `
    --connection-name pe-conn-pbivend9084

Write-Host "Private endpoint created successfully!" -ForegroundColor Green