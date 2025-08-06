# Grant sp-databricks access to pbivend9084
Write-Host "Granting Storage Blob Data Contributor to sp-databricks on pbivend9084..." -ForegroundColor Yellow

$roleAssignment = New-AzRoleAssignment `
    -ApplicationId "9a3351d0-f816-4e6f-95d4-f90ac882a479" `
    -RoleDefinitionName "Storage Blob Data Contributor" `
    -Scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" `
    -ErrorAction SilentlyContinue

if ($roleAssignment) {
    Write-Host "✅ Role assignment created successfully!" -ForegroundColor Green
} else {
    Write-Host "Role assignment may already exist or failed. Checking..." -ForegroundColor Yellow
}

# Verify the assignment
Write-Host "`nVerifying role assignments for sp-databricks:" -ForegroundColor Yellow
Get-AzRoleAssignment -ServicePrincipalName "9a3351d0-f816-4e6f-95d4-f90ac882a479" | Where-Object {$_.Scope -like "*pbivend9084*"} | Format-Table RoleDefinitionName, Scope

Write-Host "`n✅ Complete! Wait 2-3 minutes for permissions to propagate." -ForegroundColor Green