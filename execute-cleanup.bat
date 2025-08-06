@echo off
echo === Executing Azure Resource Cleanup ===
echo.
echo This will delete the identified unused resources to save $79/month
echo.

REM 1. Delete deallocated VM
echo [1/6] Deleting deallocated VM: aidev-tuan...
call az vm delete --name aidev-tuan --resource-group AIDEV12581458982000 --yes --no-wait

REM 2. Delete unattached disks
echo [2/6] Deleting unattached disk: vm-pbi-vendor_OsDisk_1...
call az disk delete --name vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075 --resource-group RG-PBI-VENDOR-ISOLATED --yes --no-wait

echo [3/6] Deleting unattached disk: adftransfer_OsDisk_1...
call az disk delete --name adftransfer_OsDisk_1_d6a4777c2f8747edb1bf5879f56c055b --resource-group VISION --yes --no-wait

echo [4/6] Deleting unattached disk: atlassian-server_OsDisk_1...
call az disk delete --name atlassian-server_OsDisk_1_e16f3b26d6c2473da17bc1aa6207372f --resource-group VISION --yes --no-wait

REM 3. Delete unattached public IPs
echo [5/6] Deleting unattached public IP: pip-vpn-azure-aws...
call az network public-ip delete --name pip-vpn-azure-aws --resource-group vision --yes

echo [6/6] Deleting unattached public IP: vm-pbi-vendorPublicIP...
call az network public-ip delete --name vm-pbi-vendorPublicIP --resource-group vision --yes

echo.
echo === Cleanup Complete ===
echo.
echo Resources deleted:
echo - 1 deallocated VM (aidev-tuan) - Saves $50/month
echo - 3 unattached disks - Saves $22/month  
echo - 2 unattached public IPs - Saves $7/month
echo.
echo Total monthly savings: $79
echo.
echo Note: Deletions may take a few minutes to complete in Azure.
echo Check the Azure Portal to verify all resources are removed.
pause