# Launch Windows Terminal with the fix script
$wtCommand = @'
powershell -NoExit -Command "& {
    Write-Host 'O365 SECURITY FIX' -ForegroundColor Cyan
    Write-Host 'Connecting...' -ForegroundColor Yellow
    Connect-ExchangeOnline -UserPrincipalName andre.darby@cogitativo.com
    Write-Host 'Applying fixes...' -ForegroundColor Yellow
    Set-HostedContentFilterPolicy -Identity Default -SCLJunk 4 -SpamAction MoveToJmf -BulkSpamAction MoveToJmf -EnableEndUserSpamNotifications `$true
    Set-AntiPhishPolicy -Identity ''Office365 AntiPhish Default'' -DmarcQuarantineAction MoveToJmf
    Write-Host 'DONE! Changes active in 30 min' -ForegroundColor Green
    Get-HostedContentFilterPolicy -Identity Default | Select SCLJunk, SpamAction, EnableEndUserSpamNotifications
}"
'@

# Try to launch in Windows Terminal
try {
    Start-Process wt.exe -ArgumentList "new-tab", "--title", "O365 Fix", "powershell", "-NoExit", "-Command", $wtCommand
    Write-Host "Windows Terminal launched with fix script!" -ForegroundColor Green
} catch {
    # Fallback to regular PowerShell
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $wtCommand
    Write-Host "PowerShell launched with fix script!" -ForegroundColor Green
}