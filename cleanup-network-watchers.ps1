# Network Watcher Cleanup Script
Write-Host "=== Network Watcher Cleanup ===" -ForegroundColor Cyan
Write-Host "You have 42 Network Watchers but only need 3 (one per region with resources)" -ForegroundColor Yellow
Write-Host ""

# Regions where you have actual resources
$requiredRegions = @("eastus", "eastus2", "westus")

Write-Host "Regions with your resources: $($requiredRegions -join ', ')" -ForegroundColor Green
Write-Host "Keeping Network Watchers in these regions only." -ForegroundColor Green
Write-Host ""

# Get all network watchers
$allWatchers = az network watcher list --query "[].{Name:name, Location:location}" -o json | ConvertFrom-Json

$deletedCount = 0
$keptCount = 0

foreach ($watcher in $allWatchers) {
    if ($requiredRegions -contains $watcher.Location) {
        Write-Host "[KEEP] $($watcher.Name) in $($watcher.Location)" -ForegroundColor Green
        $keptCount++
    } else {
        Write-Host "[DELETE] $($watcher.Name) in $($watcher.Location)" -ForegroundColor Red
        # Delete the watcher
        az network watcher delete --name $watcher.Name --resource-group NetworkWatcherRG 2>$null
        $deletedCount++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Network Watchers kept: $keptCount" -ForegroundColor Green
Write-Host "Network Watchers deleted: $deletedCount" -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: Network Watchers don't incur charges, but cleaning them reduces clutter." -ForegroundColor Gray
Write-Host "Azure will auto-recreate them if you deploy resources to new regions." -ForegroundColor Gray