# PowerShell script to install Power BI Desktop
$powerBIUrl = "https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe"
$tempPath = "C:\temp"
$installerPath = "$tempPath\PBIDesktopSetup_x64.exe"

# Create temp directory
New-Item -ItemType Directory -Force -Path $tempPath | Out-Null

# Download Power BI Desktop
Write-Host "Downloading Power BI Desktop..."
Invoke-WebRequest -Uri $powerBIUrl -OutFile $installerPath

# Install silently
Write-Host "Installing Power BI Desktop..."
Start-Process -FilePath $installerPath -ArgumentList '/quiet', '/norestart', 'ACCEPT_EULA=1' -Wait

# Clean up
Remove-Item $installerPath -Force

Write-Host "Power BI Desktop installation complete!"