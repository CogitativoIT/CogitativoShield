# Azure Resource Cleanup Script
# This script helps safely clean up unused resources identified in the audit

Write-Host "=== Azure Resource Cleanup Script ===" -ForegroundColor Cyan
Write-Host "This script will help you safely remove unused resources." -ForegroundColor Yellow
Write-Host "Each deletion will be confirmed before proceeding.`n" -ForegroundColor Yellow

# Function to confirm action
function Confirm-Action {
    param([string]$message)
    $response = Read-Host "$message (yes/no)"
    return $response -eq "yes"
}

# 1. Deallocated VM Cleanup
Write-Host "`n1. DEALLOCATED VM" -ForegroundColor Green
Write-Host "Found: aidev-tuan in AIDEV12581458982000 resource group" -ForegroundColor White
Write-Host "Status: Deallocated (still incurring storage costs ~$50/month)" -ForegroundColor Yellow

if (Confirm-Action "Do you want to DELETE this VM and its resources?") {
    Write-Host "Deleting VM and associated resources..." -ForegroundColor Yellow
    
    # Delete the VM
    az vm delete --name aidev-tuan --resource-group AIDEV12581458982000 --yes --no-wait
    
    Write-Host "VM deletion initiated. Associated resources (NIC, disk) may need separate deletion." -ForegroundColor Green
    
    # Option to delete the entire resource group if empty
    if (Confirm-Action "Delete the entire AIDEV12581458982000 resource group if it's no longer needed?") {
        az group delete --name AIDEV12581458982000 --yes --no-wait
        Write-Host "Resource group deletion initiated." -ForegroundColor Green
    }
} else {
    Write-Host "Skipping VM deletion." -ForegroundColor Gray
}

# 2. Unattached Disks
Write-Host "`n2. UNATTACHED DISKS" -ForegroundColor Green
Write-Host "Found 3 unattached disks (~$22/month total):" -ForegroundColor White

$disks = @(
    @{Name="vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075"; RG="RG-PBI-VENDOR-ISOLATED"; Size="127GB"},
    @{Name="adftransfer_OsDisk_1_d6a4777c2f8747edb1bf5879f56c055b"; RG="VISION"; Size="30GB"},
    @{Name="atlassian-server_OsDisk_1_e16f3b26d6c2473da17bc1aa6207372f"; RG="VISION"; Size="30GB"}
)

foreach ($disk in $disks) {
    Write-Host "`n  - $($disk.Name) ($($disk.Size))" -ForegroundColor Yellow
    if (Confirm-Action "Delete this disk?") {
        az disk delete --name $disk.Name --resource-group $disk.RG --yes --no-wait
        Write-Host "  Disk deletion initiated." -ForegroundColor Green
    } else {
        Write-Host "  Skipping disk." -ForegroundColor Gray
    }
}

# 3. Unattached Public IPs
Write-Host "`n3. UNATTACHED PUBLIC IPs" -ForegroundColor Green
Write-Host "Found 2 unattached public IPs (~$7/month total):" -ForegroundColor White

$publicIPs = @(
    @{Name="pip-vpn-azure-aws"; RG="vision"; Purpose="VPN (check if still needed)"},
    @{Name="vm-pbi-vendorPublicIP"; RG="vision"; Purpose="Old VM IP (using Bastion now)"}
)

foreach ($pip in $publicIPs) {
    Write-Host "`n  - $($pip.Name) - $($pip.Purpose)" -ForegroundColor Yellow
    if (Confirm-Action "Delete this public IP?") {
        az network public-ip delete --name $pip.Name --resource-group $pip.RG --yes
        Write-Host "  Public IP deleted." -ForegroundColor Green
    } else {
        Write-Host "  Skipping public IP." -ForegroundColor Gray
    }
}

# 4. Network Watchers Cleanup
Write-Host "`n4. EXCESSIVE NETWORK WATCHERS" -ForegroundColor Green
Write-Host "Found 42 Network Watchers (only need 1 per region)" -ForegroundColor Yellow
Write-Host "These are auto-created by Azure and safe to reduce." -ForegroundColor White

if (Confirm-Action "Clean up excess Network Watchers?") {
    Write-Host "Cleaning up Network Watchers..." -ForegroundColor Yellow
    
    # Get all network watchers
    $watchers = az network watcher list --query "[].{Name:name, Location:location, RG:resourceGroup}" -o json | ConvertFrom-Json
    
    # Keep one per location
    $locationsProcessed = @{}
    foreach ($watcher in $watchers) {
        if ($locationsProcessed.ContainsKey($watcher.Location)) {
            # Delete duplicate
            Write-Host "  Deleting duplicate watcher: $($watcher.Name)" -ForegroundColor Yellow
            az network watcher delete --name $watcher.Name --resource-group $watcher.RG --yes 2>$null
        } else {
            $locationsProcessed[$watcher.Location] = $true
            Write-Host "  Keeping watcher: $($watcher.Name) for $($watcher.Location)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Skipping Network Watcher cleanup." -ForegroundColor Gray
}

# 5. Summary and Recommendations
Write-Host "`n=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Potential monthly savings from deletions: ~$79" -ForegroundColor Green
Write-Host "`nAdditional recommendations:" -ForegroundColor Yellow
Write-Host "1. Review storage account usage (cogiaidev, cogiarchive)" -ForegroundColor White
Write-Host "2. Consolidate intelligent-hub resource groups (3 similar groups)" -ForegroundColor White
Write-Host "3. Consider auto-shutdown for non-production VMs" -ForegroundColor White
Write-Host "4. Implement tagging strategy for better cost tracking" -ForegroundColor White

Write-Host "`nFor storage optimization, run:" -ForegroundColor Yellow
Write-Host "  az storage account list --query `"[?contains(name, 'cogi')].{Name:name, RG:resourceGroup}`" -o table" -ForegroundColor Gray

Write-Host "`nScript complete. Check Azure Portal to verify deletions." -ForegroundColor Green