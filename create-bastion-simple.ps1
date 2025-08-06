# Create Bastion in dedicated RG
Write-Host "Creating dedicated Bastion for vendor environment..." -ForegroundColor Yellow

# The AzureBastionSubnet already exists at 10.0.3.0/26
# We need to create a public IP and Bastion in the new RG

Write-Host "Step 1: Creating Public IP for Bastion..." -ForegroundColor Cyan
az network public-ip create `
    --resource-group rg-pbi-vendor-isolated `
    --name pip-bastion-pbi-vendor `
    --sku Standard `
    --location eastus

Write-Host ""
Write-Host "Step 2: Creating Bastion host..." -ForegroundColor Cyan
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow

# Create Bastion using REST API to avoid extension issues
$bastionName = "bastion-pbi-vendor"
$pipId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Network/publicIPAddresses/pip-bastion-pbi-vendor"
$subnetId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet/subnets/AzureBastionSubnet"

$bastionBody = @{
    location = "eastus"
    properties = @{
        ipConfigurations = @(
            @{
                name = "IpConf"
                properties = @{
                    subnet = @{ id = $subnetId }
                    publicIPAddress = @{ id = $pipId }
                }
            }
        )
    }
} | ConvertTo-Json -Depth 10

$uri = "https://management.azure.com/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Network/bastionHosts/$bastionName`?api-version=2023-04-01"

Write-Host "Creating Bastion via REST API..." -ForegroundColor Yellow
az rest --method PUT --uri $uri --body $bastionBody

Write-Host ""
Write-Host "Bastion creation initiated!" -ForegroundColor Green
Write-Host ""
Write-Host "Benefits of this approach:" -ForegroundColor Cyan
Write-Host "- Everything in one resource group" -ForegroundColor White
Write-Host "- Portal auto-discovery will work" -ForegroundColor White
Write-Host "- No cross-RG permission issues" -ForegroundColor White
Write-Host "- Vendors can use Connect button directly" -ForegroundColor White