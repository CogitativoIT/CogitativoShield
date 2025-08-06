# Fix Databricks Write Access for Jason Jones
Write-Host "=== Fixing Databricks Write Access ===" -ForegroundColor Cyan
Write-Host ""

# Variables
$groupName = "visionbidevvm"
$groupId = "b6dc070d-f050-41c0-af1a-c9bdf043ecef"
$storageAccount = "pbivend9084"
$resourceGroup = "rg-pbi-vendor-isolated"
$subscription = "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

Write-Host "Checking current permissions..." -ForegroundColor Yellow

# Get storage account resource ID
$storageId = "/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount"

# Check existing role assignments
Write-Host "`nCurrent role assignments for visionbidevvm group:" -ForegroundColor Yellow
az role assignment list --assignee $groupId --query "[?scope=='$storageId'].roleDefinitionName" -o table

# Grant Storage Blob Data Contributor role
Write-Host "`nGranting Storage Blob Data Contributor role..." -ForegroundColor Green
az role assignment create `
    --role "Storage Blob Data Contributor" `
    --assignee $groupId `
    --scope $storageId

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSuccess! The visionbidevvm group now has write access." -ForegroundColor Green
    Write-Host "`nThis includes:" -ForegroundColor White
    Write-Host "- Jason Jones (jason.jones@cogitativo.com)"
    Write-Host "- Service Principal sp-databricks" 
    Write-Host "- All other group members"
    Write-Host "`nJason can now:" -ForegroundColor White
    Write-Host "- Read existing parquet files"
    Write-Host "- Write new parquet files" 
    Write-Host "- Create directories"
    Write-Host "- Overwrite existing files"
    Write-Host "`nNote: Permissions may take 2-3 minutes to propagate." -ForegroundColor Yellow
} else {
    Write-Host "`nError granting permissions. Please check the error message above." -ForegroundColor Red
}