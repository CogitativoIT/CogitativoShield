# Alternative Solution: Setup Permissions Without Moving Resources

Since moving resources between resource groups can be complex and may impact existing configurations, here's an alternative approach that maintains security:

## Option 1: Manual Move (Recommended)

### In Azure Portal:
1. Go to **Resource groups** → **vision**
2. Select these resources (checkbox):
   - vm-pbi-vendor
   - pbivend9084 (storage account)
   - vm-pbi-vendorVMNic
   - vm-pbi-vendor_OsDisk_1_*
3. Click **Move** → **Move to another resource group**
4. Select **rg-pbi-vendor-isolated**
5. Check "I understand" and click **OK**

### After Move Completes:
1. Go to **rg-pbi-vendor-isolated** → **Access control (IAM)**
2. Add role assignment:
   - Role: **Reader**
   - Assign to: **visionbidevvm** group
3. Go to the VM → **Access control (IAM)**
4. Add role assignment:
   - Role: **Virtual Machine User Login**
   - Assign to: **visionbidevvm** group

## Option 2: Create Resource-Specific Permissions (Without Moving)

If you prefer not to move resources, we can create a custom role that ONLY allows access to specific resources:

### Custom Role Definition:
```json
{
  "Name": "PBI Vendor VM Access Only",
  "Description": "Access to specific PBI vendor resources only",
  "IsCustom": true,
  "Actions": [
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Network/networkInterfaces/read",
    "Microsoft.Network/bastionHosts/read",
    "Microsoft.Storage/storageAccounts/read"
  ],
  "DataActions": [
    "Microsoft.Compute/virtualMachines/login/action"
  ],
  "AssignableScopes": [
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor",
    "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084"
  ]
}
```

This custom role would ONLY work on the specific VM and storage account, not the entire resource group.

## Option 3: Use Azure Policy

Create an Azure Policy that denies the guest group access to all resources in the vision RG except:
- vm-pbi-vendor
- pbivend9084

## Recommendation

**Option 1 (Manual Move)** is the cleanest solution:
- Complete isolation of vendor resources
- Simple permission model
- Easy to audit and manage
- No risk of accidental access to other resources

Would you like me to:
1. Help with the manual move process?
2. Create the custom role for Option 2?
3. Set up an Azure Policy for Option 3?