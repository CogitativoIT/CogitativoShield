# ⚠️ IMPORTANT: Dependencies to Handle When Moving Resources

## Current Status

### ✅ Safe to Move:
1. **VM (vm-pbi-vendor)** - Can be moved
2. **VM Disk** - Moves with VM
3. **Network Interface** - Moves with VM
4. **Storage Account (pbivend9084)** - Can be moved

### ❌ Already Broken:
- **Private Endpoint (pe-pbivend9084)** - Already deleted/missing
  - This means the VM currently CANNOT access the storage account

### 🔧 What Will Need Fixing After Move:

#### 1. Private Endpoint Recreation
After moving the storage account to the new RG, you'll need to recreate the private endpoint:

```bash
az network private-endpoint create \
  --name pe-pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --vnet-name vision-vnet \
  --subnet gitlab-private-subnet \
  --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084" \
  --group-id dfs \
  --connection-name pe-conn-pbivend9084
```

#### 2. Cross-Resource Group Networking
- The VM's NIC is connected to subnet `snet-pbi-vendor` in the `vision-vnet` (in vision RG)
- After move, the VM will be in `rg-pbi-vendor-isolated` but still connected to the VNet in `vision` RG
- This is **NORMAL and SUPPORTED** - VMs can connect to VNets in different RGs

#### 3. Bastion Access
- Bastion is in `openai-dev` RG
- Will still work after move (Bastion can connect to VMs in any RG)
- Just need to ensure the security group has Reader permission on the new RG

## ✅ No Breaking Changes Expected:

1. **Network Connectivity** - VM keeps its subnet connection
2. **Bastion Access** - Works across resource groups
3. **VM Operation** - No impact on running VM
4. **Storage Data** - Remains intact

## 🚨 Current Issue to Fix First:

**The storage private endpoint is missing!** This means:
- VM currently cannot access the storage account
- This needs to be fixed regardless of moving resources

### Fix Private Endpoint Now:
```bash
# Create private endpoint in current location
az network private-endpoint create \
  --name pe-pbivend9084 \
  --resource-group vision \
  --vnet-name vision-vnet \
  --subnet gitlab-private-subnet \
  --private-connection-resource-id "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084" \
  --group-id dfs \
  --connection-name pe-conn-pbivend9084
```

## Recommended Action Plan:

1. **Fix the private endpoint first** (it's broken now)
2. **Then move resources** via Portal
3. **Recreate private endpoint** in new RG after move
4. **Update permissions** on new RG

The move itself won't break anything that isn't already broken!