# Manual CLI Commands to Fix and Move Resources

The Git Bash environment is interfering with Azure CLI. Here are the commands to run manually in a **Windows Command Prompt** or **PowerShell** window:

## 1. Open Command Prompt or PowerShell
- Press `Win + R`
- Type `cmd` or `powershell`
- Press Enter

## 2. Verify Azure CLI is working
```cmd
az account show
```

## 3. Move Resources Command
Run this single command (copy exactly):

```cmd
az resource move --destination-group rg-pbi-vendor-isolated --ids "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Network/networkInterfaces/vm-pbi-vendorVMNic" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/disks/vm-pbi-vendor_OsDisk_1_c139da6a99294d3c8c52b7a520021075" "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"
```

## 4. After Move Completes

### Delete old private endpoint:
```cmd
az network private-endpoint delete --name pe-pbivend9084 --resource-group vision --yes
```

### Create new private endpoint:
```cmd
az network private-endpoint create --name pe-pbivend9084 --resource-group rg-pbi-vendor-isolated --vnet-name vision-vnet --subnet gitlab-private-subnet --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" --group-id dfs --connection-name pe-conn-pbivend9084
```

### Set permissions:
```cmd
az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Reader" --resource-group "rg-pbi-vendor-isolated"

az role assignment create --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" --role "Virtual Machine User Login" --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"
```

## Alternative: Use Azure Cloud Shell
1. Go to https://portal.azure.com
2. Click the Cloud Shell icon (top right)
3. Run the commands above

## Why is this happening?
Git Bash on Windows interprets forward slashes (/) as file paths and converts them to Windows paths (C:/...). This breaks Azure resource IDs. Using native Windows Command Prompt or PowerShell avoids this issue.