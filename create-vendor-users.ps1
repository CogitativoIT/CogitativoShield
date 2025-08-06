# Script to create vendor user accounts on Windows Server 2022
# Run this script on the VM after connecting via Bastion

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$FullName,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$Password
)

Write-Host "Creating vendor user account..." -ForegroundColor Yellow

# Create local user
New-LocalUser -Name $Username `
              -FullName $FullName `
              -Description "Power BI Vendor User" `
              -Password $Password `
              -PasswordNeverExpires `
              -AccountNeverExpires

# Add to Remote Desktop Users group
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $Username

Write-Host "User created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "User details:" -ForegroundColor Cyan
Write-Host "Username: $Username" -ForegroundColor White
Write-Host "Full Name: $FullName" -ForegroundColor White
Write-Host "Groups: Remote Desktop Users" -ForegroundColor White
Write-Host ""
Write-Host "This user can now:" -ForegroundColor Yellow
Write-Host "- Connect via Bastion using these credentials" -ForegroundColor White
Write-Host "- Access Power BI Desktop on the VM" -ForegroundColor White
Write-Host "- Access storage account pbivend9084" -ForegroundColor White

# Example usage:
# $password = ConvertTo-SecureString "VendorP@ssw0rd123!" -AsPlainText -Force
# .\create-vendor-users.ps1 -Username "vendor1" -FullName "Vendor User 1" -Password $password