# Inline connection and fix
param(
    [string]$Password
)

$username = "andre.darby@cogitativo.com"

if (-not $Password) {
    Write-Host "Usage: .\inline-connect.ps1 -Password 'yourpassword'" -ForegroundColor Red
    exit
}

Write-Host "Connecting to O365..." -ForegroundColor Yellow

$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Legacy connection method that might work
$Session = New-PSSession -ConfigurationName Microsoft.Exchange `
    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -Credential $credential `
    -Authentication Basic `
    -AllowRedirection

Import-PSSession $Session -DisableNameChecking

Write-Host "Applying fixes..." -ForegroundColor Yellow

# Apply fixes
Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4
Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" -DmarcQuarantineAction MoveToJmf

Write-Host "✅ Done!" -ForegroundColor Green

Remove-PSSession $Session