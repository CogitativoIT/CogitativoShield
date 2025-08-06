# Working solution for moving resources
Write-Host "Moving resources to isolated resource group..." -ForegroundColor Yellow

# Method 1: Move each resource individually to avoid path issues
$resources = @{
    "VM" = "vm-pbi-vendor"
    "Storage" = "pbivend9084"
    "NIC" = "vm-pbi-vendorVMNic"
    "Disk" = "vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075"
}

# First, let's check what we have
Write-Host ""
Write-Host "Current resources in vision RG:" -ForegroundColor Cyan
az resource list -g vision --query "[?name=='vm-pbi-vendor' || name=='pbivend9084' || name=='vm-pbi-vendorVMNic' || contains(name, 'vm-pbi-vendor_OsDisk')].{Name:name, Type:type}" -o table

# Create a batch move using REST API directly
Write-Host ""
Write-Host "Preparing batch move..." -ForegroundColor Yellow

# Get the IDs properly
$vmId = (az vm show -g vision -n vm-pbi-vendor --query id -o tsv)
$nicId = (az network nic show -g vision -n vm-pbi-vendorVMNic --query id -o tsv)
$storageId = (az storage account show -g vision -n pbivend9084 --query id -o tsv)
$diskId = (az disk list -g vision --query "[?contains(name, 'vm-pbi-vendor_OsDisk')].id" -o tsv)

Write-Host "VM ID: $vmId" -ForegroundColor Gray
Write-Host "NIC ID: $nicId" -ForegroundColor Gray
Write-Host "Storage ID: $storageId" -ForegroundColor Gray
Write-Host "Disk ID: $diskId" -ForegroundColor Gray

# Use REST API for move
Write-Host ""
Write-Host "Moving resources via REST API..." -ForegroundColor Cyan

$body = @{
    resources = @($vmId, $nicId, $diskId, $storageId)
    targetResourceGroup = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated"
} | ConvertTo-Json

$result = az rest `
    --method POST `
    --uri "https://management.azure.com/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/moveResources?api-version=2021-04-01" `
    --body $body

if ($LASTEXITCODE -eq 0) {
    Write-Host "Move initiated successfully!" -ForegroundColor Green
    Write-Host "This operation is asynchronous and may take 5-10 minutes." -ForegroundColor Yellow
    
    # Check status periodically
    Write-Host ""
    Write-Host "Waiting for move to complete..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Check new resource group
    Write-Host ""
    Write-Host "Resources in rg-pbi-vendor-isolated:" -ForegroundColor Cyan
    az resource list -g rg-pbi-vendor-isolated -o table
} else {
    Write-Host "Move failed!" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
}