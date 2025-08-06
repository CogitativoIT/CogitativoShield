# Fix CLI and Move Resources
$ErrorActionPreference = "Stop"

Write-Host "Fixing Azure CLI and moving resources..." -ForegroundColor Yellow

# Set proper subscription context
az account set --subscription fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed

# Use Azure CLI with full paths properly escaped
$moveCommand = @"
az resource move --destination-group rg-pbi-vendor-isolated --ids '/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor' '/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/networkInterfaces/vm-pbi-vendorVMNic' '/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/disks/vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075' '/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084'
"@

Write-Host "Moving resources (this may take 5-10 minutes)..." -ForegroundColor Cyan

# Execute via cmd to avoid Git Bash
$result = cmd /c $moveCommand 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Resources moved successfully!" -ForegroundColor Green
    
    # Verify
    Write-Host ""
    Write-Host "Resources in new resource group:" -ForegroundColor Yellow
    az resource list -g rg-pbi-vendor-isolated --output table
} else {
    Write-Host "Move failed: $result" -ForegroundColor Red
    
    # Alternative: Use Azure PowerShell module if available
    Write-Host ""
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Test if we can use native PowerShell cmdlets
    try {
        Get-AzContext | Out-Null
        Write-Host "Azure PowerShell module available, using it..." -ForegroundColor Green
        
        # Move using PowerShell cmdlets
        $resources = @(
            "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor",
            "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/networkInterfaces/vm-pbi-vendorVMNic",
            "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/disks/vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075",
            "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"
        )
        
        Move-AzResource -DestinationResourceGroupName "rg-pbi-vendor-isolated" -ResourceId $resources -Force
        
        Write-Host "Move completed!" -ForegroundColor Green
    } catch {
        Write-Host "Azure PowerShell module not available." -ForegroundColor Yellow
        Write-Host "Please use Azure Portal to move resources manually." -ForegroundColor Cyan
    }
}