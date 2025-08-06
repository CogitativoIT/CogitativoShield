@echo off
echo Fixing Bastion discovery issue...
echo.

echo Current Bastion configuration:
call az network bastion list --output table

echo.
echo The issue: Portal is trying to create a NEW Bastion instead of using existing one.
echo.

REM Check if the VM has any Bastion associations
echo Checking VM's current Bastion configuration...
call az vm show -g rg-pbi-vendor-isolated -n vm-pbi-vendor --query "{BastionHost:tags.BastionHost}" -o json

echo.
echo To fix this, the test user needs to:
echo 1. Go to the Bastion resource directly in openai-dev RG
echo 2. Or use the Bastion connection string
echo.

echo Generating Bastion connection URL...
echo.
echo Direct Bastion URL:
echo https://portal.azure.com/#@24317511-81a4-42fb-bea5-f4b0735acba5/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion/overview
echo.
echo To connect:
echo 1. Navigate to the Bastion host directly using the URL above
echo 2. Click "Connect"
echo 3. Select the VM: vm-pbi-vendor
echo 4. Enter credentials
echo.
pause