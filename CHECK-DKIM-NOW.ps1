# SIMPLIFIED DKIM CHECK FOR COGITATIVO.NET

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CHECKING DKIM STATUS FOR COGITATIVO.NET" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Yellow
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

Write-Host "`n✅ Connected!" -ForegroundColor Green

# Get DKIM config
Write-Host "`n[1/4] Current DKIM Configuration:" -ForegroundColor Yellow
$dkim = Get-DkimSigningConfig -Identity cogitativo.net

Write-Host "`nDomain: $($dkim.Domain)" -ForegroundColor Cyan
Write-Host "Enabled: $($dkim.Enabled)" -ForegroundColor $(if($dkim.Enabled){'Green'}else{'Red'})
Write-Host "Status: $($dkim.Status)" -ForegroundColor $(if($dkim.Status -eq 'Valid'){'Green'}else{'Red'})
Write-Host "Last Checked: $($dkim.LastChecked)"

# Show required DNS records
Write-Host "`n[2/4] Required DNS Records:" -ForegroundColor Yellow
Write-Host "`nSelector 1:" -ForegroundColor Cyan
Write-Host "  Name: selector1._domainkey"
Write-Host "  Type: CNAME"
Write-Host "  Points to: $($dkim.Selector1CNAME)" -ForegroundColor Green

Write-Host "`nSelector 2:" -ForegroundColor Cyan
Write-Host "  Name: selector2._domainkey"
Write-Host "  Type: CNAME"
Write-Host "  Points to: $($dkim.Selector2CNAME)" -ForegroundColor Green

# Test DNS resolution
Write-Host "`n[3/4] Testing DNS Resolution:" -ForegroundColor Yellow

$s1 = "selector1._domainkey.cogitativo.net"
$s2 = "selector2._domainkey.cogitativo.net"

Write-Host "`nChecking $s1..." -ForegroundColor Cyan
try {
    $dns1 = Resolve-DnsName -Name $s1 -Type CNAME -ErrorAction Stop
    Write-Host "  ✅ FOUND: Points to $($dns1.NameHost)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ NOT FOUND - This record is missing!" -ForegroundColor Red
}

Write-Host "`nChecking $s2..." -ForegroundColor Cyan
try {
    $dns2 = Resolve-DnsName -Name $s2 -Type CNAME -ErrorAction Stop
    Write-Host "  ✅ FOUND: Points to $($dns2.NameHost)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ NOT FOUND - This record is missing!" -ForegroundColor Red
}

# Try to enable if not already
Write-Host "`n[4/4] Attempting to Enable DKIM:" -ForegroundColor Yellow

if (!$dkim.Enabled) {
    try {
        Set-DkimSigningConfig -Identity cogitativo.net -Enabled $true -ErrorAction Stop
        Write-Host "✅ DKIM has been ENABLED for cogitativo.net!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Cannot enable: $_" -ForegroundColor Red
        
        if ($_ -match "CnameMissing") {
            Write-Host "`n⚠️ DNS RECORDS ARE MISSING OR INCORRECT" -ForegroundColor Red
            Write-Host ""
            Write-Host "IMPORTANT DNS TIPS:" -ForegroundColor Yellow
            Write-Host "1. Some DNS providers require you to enter just 'selector1._domainkey'" -ForegroundColor White
            Write-Host "   (without the .cogitativo.net part)" -ForegroundColor Gray
            Write-Host "2. Make sure there are NO TYPOS in the CNAME values" -ForegroundColor White
            Write-Host "3. DNS propagation can take up to 48 hours" -ForegroundColor White
            Write-Host "4. Try clearing your DNS cache: ipconfig /flushdns" -ForegroundColor White
        }
    }
} else {
    Write-Host "✅ DKIM is already enabled for cogitativo.net" -ForegroundColor Green
}

# Alternative check using nslookup
Write-Host "`n========== ALTERNATIVE DNS CHECK ==========" -ForegroundColor Cyan
Write-Host "Using nslookup to verify..." -ForegroundColor Yellow

$nslookup1 = nslookup selector1._domainkey.cogitativo.net 8.8.8.8 2>&1 | Out-String
$nslookup2 = nslookup selector2._domainkey.cogitativo.net 8.8.8.8 2>&1 | Out-String

if ($nslookup1 -match "can't find") {
    Write-Host "Selector1: NOT FOUND via Google DNS" -ForegroundColor Red
} else {
    Write-Host "Selector1: Found via Google DNS" -ForegroundColor Green
}

if ($nslookup2 -match "can't find") {
    Write-Host "Selector2: NOT FOUND via Google DNS" -ForegroundColor Red
} else {
    Write-Host "Selector2: Found via Google DNS" -ForegroundColor Green
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($dkim.Status -eq "CnameMissing") {
    Write-Host ""
    Write-Host "❌ DKIM cannot be enabled - DNS records are missing" -ForegroundColor Red
    Write-Host ""
    Write-Host "EXACT DNS RECORDS NEEDED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ADD THESE TO YOUR DNS FOR cogitativo.net:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Record 1:" -ForegroundColor White
    Write-Host "  Host/Name: selector1._domainkey" -ForegroundColor Yellow
    Write-Host "  Type: CNAME" -ForegroundColor White
    Write-Host "  Points to/Value:" -ForegroundColor White
    Write-Host "  $($dkim.Selector1CNAME)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Record 2:" -ForegroundColor White
    Write-Host "  Host/Name: selector2._domainkey" -ForegroundColor Yellow
    Write-Host "  Type: CNAME" -ForegroundColor White
    Write-Host "  Points to/Value:" -ForegroundColor White
    Write-Host "  $($dkim.Selector2CNAME)" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: Some DNS providers auto-add .cogitativo.net, so you may" -ForegroundColor Gray
    Write-Host "      only need to enter 'selector1._domainkey' not the full name" -ForegroundColor Gray
} elseif ($dkim.Enabled) {
    Write-Host ""
    Write-Host "✅ DKIM is WORKING for cogitativo.net!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Status: $($dkim.Status)" -ForegroundColor Yellow
}

Write-Host "`nDisconnecting..." -ForegroundColor Yellow
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Done!" -ForegroundColor Green