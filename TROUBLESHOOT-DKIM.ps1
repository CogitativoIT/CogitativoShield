# TROUBLESHOOT DKIM VALIDATION FOR COGITATIVO.NET
# Comprehensive DKIM troubleshooting script

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DKIM TROUBLESHOOTING FOR COGITATIVO.NET" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Import and Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# 1. Get detailed DKIM configuration
Write-Host "`n[1/5] Getting detailed DKIM configuration..." -ForegroundColor Yellow
$dkim = Get-DkimSigningConfig -Identity cogitativo.net
$dkim | Format-List *

# 2. Check the CNAME values
Write-Host "`n[2/5] Expected CNAME records:" -ForegroundColor Yellow
Write-Host "`nSelector 1:" -ForegroundColor Cyan
Write-Host "  Name: selector1._domainkey.cogitativo.net"
Write-Host "  Should point to: $($dkim.Selector1CNAME)" -ForegroundColor Green
Write-Host "`nSelector 2:" -ForegroundColor Cyan  
Write-Host "  Name: selector2._domainkey.cogitativo.net"
Write-Host "  Should point to: $($dkim.Selector2CNAME)" -ForegroundColor Green

# 3. Check current status and last check time
Write-Host "`n[3/5] Current DKIM Status:" -ForegroundColor Yellow
Write-Host "  Domain: $($dkim.Domain)"
Write-Host "  Enabled: $($dkim.Enabled)"
Write-Host "  Status: $($dkim.Status)" -ForegroundColor $(if($dkim.Status -eq 'Valid'){'Green'}else{'Red'})
Write-Host "  Last Checked: $($dkim.LastChecked)"

# 4. Try to verify DNS resolution using nslookup
Write-Host "`n[4/5] Testing DNS resolution..." -ForegroundColor Yellow

$selector1 = "selector1._domainkey.cogitativo.net"
$selector2 = "selector2._domainkey.cogitativo.net"

Write-Host "`nChecking Selector 1 DNS:" -ForegroundColor Cyan
$dns1 = nslookup $selector1 2>&1
if ($dns1 -match "can't find") {
    Write-Host "  ❌ DNS record NOT FOUND for selector1" -ForegroundColor Red
    Write-Host "  This is the problem - the CNAME record is missing or incorrect" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ DNS record found for selector1" -ForegroundColor Green
    $dns1 | Select-String "canonical name" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host "`nChecking Selector 2 DNS:" -ForegroundColor Cyan
$dns2 = nslookup $selector2 2>&1
if ($dns2 -match "can't find") {
    Write-Host "  ❌ DNS record NOT FOUND for selector2" -ForegroundColor Red
    Write-Host "  This is the problem - the CNAME record is missing or incorrect" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ DNS record found for selector2" -ForegroundColor Green
    $dns2 | Select-String "canonical name" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

# 5. Try alternative DNS servers
Write-Host "`n[5/5] Checking with public DNS servers..." -ForegroundColor Yellow

# Check with Google DNS
Write-Host "`nUsing Google DNS (8.8.8.8):" -ForegroundColor Cyan
$googleDns1 = nslookup $selector1 8.8.8.8 2>&1
$googleDns2 = nslookup $selector2 8.8.8.8 2>&1

if ($googleDns1 -match "can't find") {
    Write-Host "  Selector1: NOT FOUND" -ForegroundColor Red
} else {
    Write-Host "  Selector1: FOUND" -ForegroundColor Green
}

if ($googleDns2 -match "can't find") {
    Write-Host "  Selector2: NOT FOUND" -ForegroundColor Red
} else {
    Write-Host "  Selector2: FOUND" -ForegroundColor Green
}

# Try to rotate the DKIM keys to get fresh ones
Write-Host "`n========== ATTEMPTING TO FIX ==========" -ForegroundColor Cyan

# Check if we should try rotating the keys
if ($dkim.Status -ne 'Valid') {
    Write-Host "`nThe DKIM status shows: $($dkim.Status)" -ForegroundColor Yellow
    
    if ($dkim.Status -eq 'CnameMissing') {
        Write-Host "`n⚠️ CNAME records are missing or incorrect!" -ForegroundColor Red
        Write-Host ""
        Write-Host "TROUBLESHOOTING STEPS:" -ForegroundColor Yellow
        Write-Host "1. Verify you added BOTH CNAME records (selector1 AND selector2)" -ForegroundColor White
        Write-Host "2. Ensure there are no typos in the record names" -ForegroundColor White
        Write-Host "3. Check if you added them to the correct domain (cogitativo.net)" -ForegroundColor White
        Write-Host "4. Some DNS providers require you to NOT include the domain name" -ForegroundColor White
        Write-Host "   - Try using just 'selector1._domainkey' instead of 'selector1._domainkey.cogitativo.net'" -ForegroundColor Cyan
        Write-Host "5. Verify the CNAME target values match EXACTLY (case-sensitive)" -ForegroundColor White
        
        Write-Host "`n📝 CORRECT DNS RECORDS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "Record 1:" -ForegroundColor Cyan
        Write-Host "  Type: CNAME"
        Write-Host "  Name: selector1._domainkey" -ForegroundColor Yellow
        Write-Host "  Value: $($dkim.Selector1CNAME)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Record 2:" -ForegroundColor Cyan
        Write-Host "  Type: CNAME"
        Write-Host "  Name: selector2._domainkey" -ForegroundColor Yellow
        Write-Host "  Value: $($dkim.Selector2CNAME)" -ForegroundColor Green
    }
    
    # Try to force enable if DNS might be correct but not detected
    Write-Host "`n[ATTEMPTING FIX] Trying to enable DKIM anyway..." -ForegroundColor Yellow
    try {
        Set-DkimSigningConfig -Identity cogitativo.net -Enabled $true -ErrorAction Stop
        Write-Host "✅ DKIM has been enabled!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Cannot enable DKIM: $_" -ForegroundColor Red
        
        # Try rotating the DKIM keys
        Write-Host "`n[ALTERNATIVE FIX] Rotating DKIM keys..." -ForegroundColor Yellow
        try {
            Rotate-DkimSigningConfig -Identity cogitativo.net -KeySize 2048
            Write-Host "✅ DKIM keys rotated. New CNAME values generated." -ForegroundColor Green
            
            # Get new values
            $newDkim = Get-DkimSigningConfig -Identity cogitativo.net
            Write-Host "`n🔄 NEW CNAME RECORDS (if different):" -ForegroundColor Yellow
            Write-Host "Selector1: $($newDkim.Selector1CNAME)" -ForegroundColor Cyan
            Write-Host "Selector2: $($newDkim.Selector2CNAME)" -ForegroundColor Cyan
        } catch {
            Write-Host "Cannot rotate keys: $_" -ForegroundColor Gray
        }
    }
}

# Final status check
Write-Host "`n========== FINAL STATUS ==========" -ForegroundColor Cyan
$finalDkim = Get-DkimSigningConfig -Identity cogitativo.net
Write-Host "Domain: $($finalDkim.Domain)"
Write-Host "Enabled: $($finalDkim.Enabled)" -ForegroundColor $(if($finalDkim.Enabled){'Green'}else{'Red'})
Write-Host "Status: $($finalDkim.Status)" -ForegroundColor $(if($finalDkim.Status -eq 'Valid'){'Green'}else{'Red'})

# Save troubleshooting report
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "C:\Users\andre.darby\Ops\DKIM-Troubleshooting-$timestamp.txt"

@"
DKIM TROUBLESHOOTING REPORT
Date: $(Get-Date)
Domain: cogitativo.net

=== CURRENT STATUS ===
Enabled: $($finalDkim.Enabled)
Status: $($finalDkim.Status)
Last Checked: $($finalDkim.LastChecked)

=== REQUIRED DNS RECORDS ===

Record 1:
  Type: CNAME
  Name: selector1._domainkey
  Value: $($finalDkim.Selector1CNAME)

Record 2:
  Type: CNAME  
  Name: selector2._domainkey
  Value: $($finalDkim.Selector2CNAME)

=== COMMON ISSUES ===

DNS Provider Variations:
- Some providers auto-append the domain
- Use selector1._domainkey NOT selector1._domainkey.cogitativo.net

TTL Issues:
- DNS changes can take up to 48 hours
- Try lowering TTL to 300 seconds

Case Sensitivity:
- CNAME targets are case-sensitive
- Copy exactly as shown

Wrong Domain:
- Ensure records are on cogitativo.net
- NOT on cogitativo.com

=== NEXT STEPS ===

1. Verify DNS records match exactly
2. Wait 15-30 minutes after any changes
3. Run this script again to check
4. If still failing, check with DNS provider support
"@ | Out-File $reportFile

Write-Host "`nTroubleshooting report saved to: $reportFile" -ForegroundColor Cyan

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green