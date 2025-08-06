# Check storage account usage
$storageAccounts = @(
    @{Name="aaidev16811"; ResourceGroup="openai-dev"},
    @{Name="cogiaidev"; ResourceGroup="vision"},
    @{Name="cogiarchive"; ResourceGroup="vision"},
    @{Name="cogidatalake"; ResourceGroup="vision"},
    @{Name="cogipidatalake"; ResourceGroup="pi"},
    @{Name="cogitativoaistorage"; ResourceGroup="openai-dev"},
    @{Name="dbstorage6ncp5e77fc3uo"; ResourceGroup="databricks-pi"},
    @{Name="dbstorageubkmscb356bca"; ResourceGroup="databricks-vision"},
    @{Name="intelligenthupstorage"; ResourceGroup="rg-intelligent-hub"},
    @{Name="pbivend9084"; ResourceGroup="rg-pbi-vendor-isolated"},
    @{Name="visionml8033658882"; ResourceGroup="vision"},
    @{Name="cs410032000a6ab7916"; ResourceGroup="cloud-shell-storage-westus"}
)

Write-Host "Checking storage account usage..." -ForegroundColor Cyan
$results = @()

foreach ($storage in $storageAccounts) {
    Write-Host "Checking $($storage.Name)..." -NoNewline
    
    # Get storage account key
    $keys = az storage account keys list -n $storage.Name -g $storage.ResourceGroup --query "[0].value" -o tsv 2>$null
    
    if ($keys) {
        # Get container count
        $containers = az storage container list --account-name $storage.Name --account-key $keys --query "length(@)" -o tsv 2>$null
        
        # Get approximate usage (this is a simplified check)
        $usage = az storage metrics show --services b --metrics-type service --account-name $storage.Name --account-key $keys 2>$null
        
        $result = [PSCustomObject]@{
            Name = $storage.Name
            ResourceGroup = $storage.ResourceGroup
            Containers = if ($containers) { $containers } else { "0" }
            Status = if ($containers -gt 0) { "In Use" } else { "Possibly Unused" }
        }
        $results += $result
        Write-Host " Done" -ForegroundColor Green
    } else {
        Write-Host " Access Denied" -ForegroundColor Yellow
        $result = [PSCustomObject]@{
            Name = $storage.Name
            ResourceGroup = $storage.ResourceGroup
            Containers = "Unknown"
            Status = "Check Manually"
        }
        $results += $result
    }
}

$results | Format-Table -AutoSize