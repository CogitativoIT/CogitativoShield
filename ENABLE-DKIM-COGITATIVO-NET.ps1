# Enable DKIM for cogitativo.net domain
# Run this script in an authenticated Exchange Online session

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ENABLING DKIM FOR COGITATIVO.NET" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check current DKIM status
Write-Host "`nCurrent DKIM Status:" -ForegroundColor Yellow
Get-DkimSigningConfig -Identity cogitativo.net | Format-List Domain, Enabled, Status, Selector1CNAME, Selector2CNAME

# Get the CNAME records needed for DNS
$dkim = Get-DkimSigningConfig -Identity cogitativo.net

Write-Host "`n=== DNS RECORDS NEEDED ===" -ForegroundColor Green
Write-Host "Add these CNAME records to your DNS provider for cogitativo.net:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Record 1:" -ForegroundColor Cyan
Write-Host "  Name: selector1._domainkey" -ForegroundColor White
Write-Host "  Type: CNAME" -ForegroundColor White
Write-Host "  Value: $($dkim.Selector1CNAME)" -ForegroundColor Green
Write-Host ""
Write-Host "Record 2:" -ForegroundColor Cyan
Write-Host "  Name: selector2._domainkey" -ForegroundColor White
Write-Host "  Type: CNAME" -ForegroundColor White
Write-Host "  Value: $($dkim.Selector2CNAME)" -ForegroundColor Green

Write-Host "`n=== INSTRUCTIONS ===" -ForegroundColor Yellow
Write-Host "1. Add the above CNAME records to your DNS provider"
Write-Host "2. Wait 15-30 minutes for DNS propagation"
Write-Host "3. Run the VERIFY-AND-ENABLE-DKIM.ps1 script to complete setup"
Write-Host ""
Write-Host "DNS Providers:" -ForegroundColor Cyan
Write-Host "  - GoDaddy: https://dcc.godaddy.com/manage/cogitativo.net/dns"
Write-Host "  - Azure DNS: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Network%2FdnsZones"
Write-Host "  - Cloudflare: https://dash.cloudflare.com"

# Save CNAME values to file for reference
$output = @"
DKIM Setup for cogitativo.net
Generated: $(Get-Date)

CNAME Record 1:
  Name: selector1._domainkey
  Value: $($dkim.Selector1CNAME)

CNAME Record 2:
  Name: selector2._domainkey  
  Value: $($dkim.Selector2CNAME)

Status: Waiting for DNS records to be added
"@

$output | Out-File "C:\Users\andre.darby\Ops\DKIM-DNS-Records-cogitativo-net.txt"
Write-Host "`nDNS record details saved to: DKIM-DNS-Records-cogitativo-net.txt" -ForegroundColor Green