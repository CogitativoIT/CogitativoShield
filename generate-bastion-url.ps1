# Generate Direct Bastion Connection URL
Write-Host "Generating Bastion Connection URLs..." -ForegroundColor Yellow
Write-Host ""

# Method 1: Direct to Bastion resource
$bastionResourceUrl = "https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion/overview"

# Method 2: VM Connect blade with Bastion pre-selected
$vmConnectUrl = "https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor/connect"

# Method 3: Search-based URL
$searchUrl = "https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FbastionHosts"

Write-Host "Option 1 - Direct to Bastion (then select VM):" -ForegroundColor Cyan
Write-Host $bastionResourceUrl -ForegroundColor White
Write-Host ""

Write-Host "Option 2 - VM Connect Page:" -ForegroundColor Cyan
Write-Host $vmConnectUrl -ForegroundColor White
Write-Host ""

Write-Host "Option 3 - Bastion List (user selects Dtlaidev1-bastion):" -ForegroundColor Cyan
Write-Host $searchUrl -ForegroundColor White
Write-Host ""

Write-Host "Instructions for vendor:" -ForegroundColor Yellow
Write-Host "1. Use Option 1 URL"
Write-Host "2. Once on Bastion page, click 'Connect' in left menu"
Write-Host "3. Select vm-pbi-vendor from dropdown"
Write-Host "4. Enter credentials"
Write-Host ""

# Save to file
@"
Bastion Connection URLs for Vendor
==================================

Direct Bastion URL (Recommended):
$bastionResourceUrl

Steps:
1. Click the URL above
2. On the Bastion page, click "Connect" in the left menu
3. Select "vm-pbi-vendor" from the Virtual Machine dropdown
4. Enter username: azureadmin
5. Enter password: [provide password]
6. Click Connect

Alternative - VM Page:
$vmConnectUrl
(Then manually navigate to Bastion)

Note: If prompted to deploy Bastion, DO NOT click deploy. Instead use the direct Bastion URL above.
"@ | Out-File "vendor-bastion-urls.txt"

Write-Host "URLs saved to: vendor-bastion-urls.txt" -ForegroundColor Green