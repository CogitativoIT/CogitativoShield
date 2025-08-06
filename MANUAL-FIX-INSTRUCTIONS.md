# Manual Fix for Guest User VM Access

## The Issue
The test user (tester1@cogitativo.net) is getting a 403 error when trying to access vm-pbi-vendor. The Azure CLI is having issues applying role assignments.

## Manual Steps to Fix (Do this in Azure Portal)

### 1. Navigate to the VM
- Go to: **Resource groups** → **vision** → **vm-pbi-vendor**

### 2. Add Access Control (IAM)
- Click on **Access control (IAM)** in the left menu
- Click **+ Add** → **Add role assignment**

### 3. Assign Reader Role
- **Role tab**: Select **Reader**
- Click **Next**
- **Members tab**: 
  - Select **Assign access to**: User, group, or service principal
  - Click **+ Select members**
  - Search for **visionbidevvm**
  - Select the group and click **Select**
- Click **Review + assign**

### 4. Assign Virtual Machine User Login
- Click **+ Add** → **Add role assignment** again
- **Role tab**: Search for and select **Virtual Machine User Login**
- Click **Next**
- **Members tab**: Select the **visionbidevvm** group again
- Click **Review + assign**

### 5. Add Bastion Access
- Navigate to: **Resource groups** → **openai-dev**
- Click on **Access control (IAM)**
- Add **Reader** role to **visionbidevvm** group (same process as above)

### 6. Alternative: Use Azure CLI locally
If you have Azure CLI on your local machine:

```bash
# Login
az login

# Set subscription
az account set --subscription "fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"

# Assign roles
az role assignment create \
  --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" \
  --role "Reader" \
  --resource-group "vision"

az role assignment create \
  --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" \
  --role "Virtual Machine User Login" \
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor"

az role assignment create \
  --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" \
  --role "Reader" \
  --resource-group "openai-dev"
```

### 7. Test User Actions
After adding permissions:
1. Test user must **log out completely**
2. **Clear browser cache**
3. Log back in
4. Navigate to **Virtual machines**
5. Search for **vm-pbi-vendor**
6. Click **Connect** → **Bastion**

## Summary of Required Permissions
- **Reader** on vision resource group (to see the VM)
- **Virtual Machine User Login** on vm-pbi-vendor (to login as user)
- **Reader** on openai-dev resource group (to use Bastion)

## If Still Not Working
1. Verify user accepted the guest invitation
2. Check user is signing into correct tenant (cogitativo.net)
3. Try InPrivate/Incognito browser mode
4. Wait 15-30 minutes for permissions to fully propagate