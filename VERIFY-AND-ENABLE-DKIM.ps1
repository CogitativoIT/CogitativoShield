# Verify DNS and Enable DKIM for cogitativo.net
# Run this after adding DNS records

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFYING & ENABLING DKIM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if DNS records are properly configured
Write-Host "`nVerifying DNS records..." -ForegroundColor Yellow

try {
    # Try to enable DKIM
    Set-DkimSigningConfig -Identity cogitativo.net -Enabled $true -ErrorAction Stop
    
    Write-Host "`n✅ SUCCESS! DKIM has been enabled for cogitativo.net" -ForegroundColor Green
    
    # Verify the configuration
    Write-Host "`nFinal DKIM Configuration:" -ForegroundColor Yellow
    Get-DkimSigningConfig -Identity cogitativo.net | Format-List Domain, Enabled, Status, LastChecked
    
    Write-Host "`n=== DKIM ENABLED SUCCESSFULLY ===" -ForegroundColor Green
    Write-Host "Your emails from cogitativo.net will now be DKIM signed!" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ DKIM cannot be enabled yet" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common reasons:" -ForegroundColor Yellow
    Write-Host "  1. DNS records not added yet"
    Write-Host "  2. DNS propagation not complete (wait 15-30 minutes)"
    Write-Host "  3. CNAME records incorrect"
    Write-Host ""
    Write-Host "Please verify DNS records are added and try again later." -ForegroundColor Cyan
}