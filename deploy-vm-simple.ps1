# Simple VM deployment
$vmPassword = "PbiVend0r2025!@#$"
$adminUser = "azureadmin"

Write-Host "Creating VM with temporary password..." -ForegroundColor Yellow
Write-Host "Username: $adminUser" -ForegroundColor Cyan
Write-Host "Password: $vmPassword" -ForegroundColor Cyan
Write-Host ""

# Create VM with minimal parameters
az vm create `
    --resource-group vision `
    --name vm-pbi-vendor `
    --image Win11-22H2-Pro `
    --size Standard_D4s_v3 `
    --vnet-name vision-vnet `
    --subnet default `
    --admin-username $adminUser `
    --admin-password $vmPassword

Write-Host ""
Write-Host "VM created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Access VM via Bastion" -ForegroundColor White
Write-Host "2. Change the temporary password" -ForegroundColor White
Write-Host "3. Install Power BI Desktop manually" -ForegroundColor White
Write-Host ""
Write-Host "Storage endpoint: https://pbivend9084.dfs.core.windows.net/parquet" -ForegroundColor Cyan