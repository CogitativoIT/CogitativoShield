@echo off
echo === Quick Windows 11 VM Migration ===
echo.
echo This script will help migrate to Windows 11 for Azure AD support
echo.

echo Current Setup:
echo - VM: vm-pbi-vendor (Windows Server 2022)
echo - Storage: pbivend9084 
echo - Resource Group: rg-pbi-vendor-isolated
echo.

echo IMPORTANT: This requires:
echo 1. Backing up any data on the current VM
echo 2. Deleting current VM (keeping network/disks)
echo 3. Creating new Windows 11 VM
echo 4. Enabling Azure AD authentication
echo.

echo Ready to proceed? 
echo Run: powershell -ExecutionPolicy Bypass -File recreate-as-windows11.ps1
echo.

echo Alternative: For immediate access without recreating:
echo 1. Create local user on current VM
echo 2. Run on VM: net user vendoruser TempPass123! /add
echo 3. Run on VM: net localgroup "Remote Desktop Users" vendoruser /add
echo.
pause