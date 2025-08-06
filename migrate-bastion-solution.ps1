# Migrate Bastion Solution
Write-Host "=== Bastion Migration Plan ===" -ForegroundColor Cyan
Write-Host ""

# Current situation
Write-Host "Current Bastion Configuration:" -ForegroundColor Yellow
Write-Host "- VISION-VNET-BASTION in VISION RG (using AzureBastionSubnet)" -ForegroundColor White
Write-Host "- Dtlaidev1-bastion in openai-dev RG" -ForegroundColor White
Write-Host ""

# Since AzureBastionSubnet is already in use, we have a few options:
Write-Host "Options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Use the existing VISION-VNET-BASTION" -ForegroundColor Cyan
Write-Host "- Already connected to vision-vnet" -ForegroundColor White
Write-Host "- Just need to grant permissions to visionbidevvm group" -ForegroundColor White
Write-Host "- Simplest solution" -ForegroundColor Green
Write-Host ""

Write-Host "Option 2: Delete VISION-VNET-BASTION and create new one" -ForegroundColor Cyan
Write-Host "- Would free up the AzureBastionSubnet" -ForegroundColor White
Write-Host "- Create new Bastion in rg-pbi-vendor-isolated" -ForegroundColor White
Write-Host "- More complex, requires downtime" -ForegroundColor Yellow
Write-Host ""

Write-Host "Recommended: Option 1 - Use existing VISION-VNET-BASTION" -ForegroundColor Green
Write-Host ""

# Implement Option 1
Write-Host "Implementing Option 1..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Granting permissions to visionbidevvm group..." -ForegroundColor Cyan
az role assignment create `
    --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" `
    --role "Reader" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/VISION" `
    2>$null

az role assignment create `
    --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" `
    --role "Reader" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/VISION/providers/Microsoft.Network/bastionHosts/VISION-VNET-BASTION" `
    2>$null

Write-Host "✓ Permissions granted" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Remove unnecessary permissions from old Bastion..." -ForegroundColor Cyan
# Remove openai-dev permissions since we won't use that Bastion
az role assignment delete `
    --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev" `
    2>$null

az role assignment delete `
    --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" `
    --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion" `
    2>$null

Write-Host "✓ Old permissions removed" -ForegroundColor Green
Write-Host ""

Write-Host "=== Solution Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Benefits:" -ForegroundColor Cyan
Write-Host "- Vendors can now use Connect button on VM" -ForegroundColor White
Write-Host "- Bastion is in same VNet's resource group" -ForegroundColor White
Write-Host "- Auto-discovery will work" -ForegroundColor White
Write-Host "- No need to create new Bastion (saves cost)" -ForegroundColor White
Write-Host ""
Write-Host "Vendor access:" -ForegroundColor Yellow
Write-Host "- Can see rg-pbi-vendor-isolated (their VM)" -ForegroundColor White
Write-Host "- Can see VISION RG (read-only, for Bastion)" -ForegroundColor White
Write-Host "- Can see vision-vnet (read-only, for connectivity)" -ForegroundColor White