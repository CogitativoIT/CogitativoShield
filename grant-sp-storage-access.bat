@echo off
echo Granting storage access to service principal...
call az role assignment create --assignee "f81022ff-d84f-47d5-ae95-5ad2b02fb945" --role "Storage Blob Data Contributor" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"
echo Done!
pause