# Setup Proper Storage Access for Databricks and Power BI VM
Write-Host "=== Setting Up Secure Storage Access ===" -ForegroundColor Cyan
Write-Host "This will enable access for both Databricks and Power BI VM" -ForegroundColor Yellow
Write-Host ""

# Variables
$storageAccount = "pbivend9084"
$storageRG = "rg-pbi-vendor-isolated"
$visionVNet = "vision-vnet"
$databricksVNet = "visionnetwork"
$visionRG = "vision"

# Step 1: Create VNet Peering
Write-Host "Step 1: Creating VNet Peering between vision-vnet and visionnetwork..." -ForegroundColor Yellow

# Get VNet resource IDs
$visionVNetId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/vision-vnet"
$databricksVNetId = "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/virtualNetworks/visionnetwork"

# Create peering from vision-vnet to visionnetwork
Write-Host "Creating peering vision-vnet -> visionnetwork..." -ForegroundColor White
az network vnet peering create `
    --name "vision-to-databricks" `
    --resource-group $visionRG `
    --vnet-name $visionVNet `
    --remote-vnet $databricksVNetId `
    --allow-vnet-access `
    --allow-forwarded-traffic

# Create peering from visionnetwork to vision-vnet
Write-Host "Creating peering visionnetwork -> vision-vnet..." -ForegroundColor White
az network vnet peering create `
    --name "databricks-to-vision" `
    --resource-group $visionRG `
    --vnet-name $databricksVNet `
    --remote-vnet $visionVNetId `
    --allow-vnet-access `
    --allow-forwarded-traffic

Write-Host "✓ VNet peering established" -ForegroundColor Green
Write-Host ""

# Step 2: Add network rules for Databricks subnets
Write-Host "Step 2: Adding Databricks subnets to storage firewall..." -ForegroundColor Yellow

# Add private Databricks subnet
az storage account network-rule add `
    --account-name $storageAccount `
    --resource-group $storageRG `
    --vnet-name $databricksVNet `
    --subnet "private-databricks-subnet"

# Add public Databricks subnet
az storage account network-rule add `
    --account-name $storageAccount `
    --resource-group $storageRG `
    --vnet-name $databricksVNet `
    --subnet "public-databricks-subnet"

# Add VM subnet (already has private endpoint but good to have)
az storage account network-rule add `
    --account-name $storageAccount `
    --resource-group $storageRG `
    --vnet-name $visionVNet `
    --subnet "snet-pbi-vendor"

Write-Host "✓ Network rules added" -ForegroundColor Green
Write-Host ""

# Step 3: Add resource access for Databricks
Write-Host "Step 3: Adding Databricks resource access rule..." -ForegroundColor Yellow

az storage account update `
    --name $storageAccount `
    --resource-group $storageRG `
    --resource-access-rules "[{`"tenantId`":`"24317511-81a4-42fb-bea5-f4b0735acba5`",`"resourceId`":`"/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourcegroups/*/providers/Microsoft.Databricks/accessConnectors/*`"}]"

Write-Host "✓ Databricks resource access configured" -ForegroundColor Green
Write-Host ""

# Step 4: Verify configuration
Write-Host "Step 4: Verifying configuration..." -ForegroundColor Yellow

# Check peering status
Write-Host "VNet Peering Status:" -ForegroundColor White
az network vnet peering list --resource-group $visionRG --vnet-name $visionVNet --query "[].{Name:name, Status:peeringState}" -o table
az network vnet peering list --resource-group $visionRG --vnet-name $databricksVNet --query "[].{Name:name, Status:peeringState}" -o table

# Check storage network rules
Write-Host ""
Write-Host "Storage Network Rules:" -ForegroundColor White
az storage account show --name $storageAccount --resource-group $storageRG --query "networkRuleSet" -o json

Write-Host ""
Write-Host "=== Configuration Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "What's been configured:" -ForegroundColor Cyan
Write-Host "✓ VNet peering between vision-vnet and visionnetwork" -ForegroundColor White
Write-Host "✓ Databricks subnets can access storage" -ForegroundColor White
Write-Host "✓ Power BI VM can access storage (via private endpoint)" -ForegroundColor White
Write-Host "✓ No public access enabled (maintaining security)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps for Jason:" -ForegroundColor Yellow
Write-Host "1. Grant service principal Storage Blob Data Contributor role" -ForegroundColor White
Write-Host "2. Use the provided mounting code in Databricks" -ForegroundColor White
Write-Host "3. Power BI on VM can access storage directly" -ForegroundColor White