# EXTRACT AND BLOCK SPAMMERS FROM INTERNAL REPORTS
# Simple script to find and block spam senders

Write-Host "================================================" -ForegroundColor Red
Write-Host "  BLOCKING SPAMMERS FROM FORWARDED EMAILS" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Red

# Connect
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com -ShowBanner:$false

# Search for forwarded spam reports
Write-Host "`nSearching for forwarded spam reports..." -ForegroundColor Yellow
$reports = Get-MessageTrace -RecipientAddress security@cogitativo.com `
                          -StartDate (Get-Date).AddDays(-7) `
                          -EndDate (Get-Date) | 
          Where-Object {
              $_.SenderAddress -like "*@cogitativo.com" -and
              $_.Subject -match "(FW:|Fwd:|spam|phish|scam)"
          }

Write-Host "Found $($reports.Count) reports from internal users" -ForegroundColor Cyan

# Extract email addresses from subjects
$spammers = @()
foreach ($report in $reports) {
    # Look for email addresses in the subject
    $matches = [regex]::Matches($report.Subject, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
    foreach ($match in $matches) {
        $email = $match.Value
        if ($email -notlike "*@cogitativo.com") {
            $spammers += $email
            Write-Host "  Found spammer: $email" -ForegroundColor Yellow
        }
    }
}

# Get unique spammers
$uniqueSpammers = $spammers | Select-Object -Unique
Write-Host "`nUnique spammers to block: $($uniqueSpammers.Count)" -ForegroundColor Red

# Block each spammer
$blocked = 0
foreach ($spammer in $uniqueSpammers) {
    Write-Host "  Blocking $spammer..." -ForegroundColor Red -NoNewline
    try {
        New-TenantAllowBlockListItems -ListType Sender `
                                     -Block `
                                     -Entries $spammer `
                                     -Notes "Reported by internal user" `
                                     -ExpirationDate (Get-Date).AddDays(90) `
                                     -ErrorAction Stop | Out-Null
        Write-Host " BLOCKED" -ForegroundColor Green
        $blocked++
    } catch {
        if ($_ -match "already exists") {
            Write-Host " Already blocked" -ForegroundColor Gray
        } else {
            Write-Host " Failed" -ForegroundColor Red
        }
    }
}

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  RESULTS" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "Reports processed: $($reports.Count)"
Write-Host "Spammers blocked: $blocked"
Write-Host "`nTIP: Ask users to forward spam as ATTACHMENTS" -ForegroundColor Yellow
Write-Host "This preserves headers for better extraction!" -ForegroundColor Yellow

Disconnect-ExchangeOnline -Confirm:$false
Write-Host "`nDone!" -ForegroundColor Green