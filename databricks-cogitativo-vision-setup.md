# Databricks cogitativo-vision Setup for Storage Access

## Current Configuration

### Databricks Workspace
- **Name**: cogitativo-vision
- **Resource Group**: vision
- **Location**: East US
- **SKU**: Premium
- **VNet**: Appears to be using default Databricks-managed VNet (not VNet-injected)

### Storage Account (pbivend9084)
- **VNet**: vision-vnet
- **Private Endpoint**: pe-pbivend9084 
- **Subnet**: gitlab-private-subnet (10.0.10.0/24)
- **Access**: Private endpoint only (no public access)

### Network Analysis
**ISSUE IDENTIFIED**: The Databricks workspace `cogitativo-vision` appears to be using Databricks-managed networking (not VNet-injected into vision-vnet). This means:
- ❌ Databricks cannot directly reach the private endpoint
- ❌ Standard mounting will fail with network timeouts

## Solution Options

### Option 1: Enable Temporary Public Access (Quick Fix)
```bash
# Temporarily allow public access from Databricks IP ranges
az storage account update \
  --name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --public-network-access Enabled

# Add Databricks service tag to firewall
az storage account network-rule add \
  --account-name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --service-tag "DataFactory.EastUS"
```

### Option 2: Use Azure Private Link for Databricks (Recommended)
Configure Private Link between Databricks and storage. This requires:
1. Azure Databricks Premium tier (✓ you have this)
2. Network admin to configure Private Link
3. May incur additional networking costs

### Option 3: VNet Peering
If Databricks is in a different VNet, establish VNet peering between:
- Databricks VNet 
- vision-vnet (where storage private endpoint exists)

## Immediate Steps for Jason

### 1. Verify Databricks Network Configuration
Have Jason run this in a Databricks notebook to check network config:
```python
# Check Databricks runtime network
import socket
import requests

# Get Databricks IP
try:
    response = requests.get('https://api.ipify.org')
    print(f"Databricks public IP: {response.text}")
except:
    print("Could not determine public IP")

# Test connectivity to storage
storage_account = "pbivend9084"
try:
    socket.gethostbyname(f"{storage_account}.dfs.core.windows.net")
    print(f"✓ Can resolve {storage_account}")
except:
    print(f"✗ Cannot resolve {storage_account} - Network issue confirmed")
```

### 2. Grant Service Principal Access
If you have an existing Databricks service principal:
```bash
# Replace with your actual service principal ID
az role assignment create \
  --assignee "<service-principal-id>" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"
```

### 3. Test Direct Access (Will Fail Without Network Fix)
```python
# This will help identify the exact error
storage_account_name = "pbivend9084"
container_name = "pbidata"

# Configure authentication (replace with your SP details)
spark.conf.set(f"fs.azure.account.auth.type.{storage_account_name}.dfs.core.windows.net", "OAuth")
spark.conf.set(f"fs.azure.account.oauth.provider.type.{storage_account_name}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(f"fs.azure.account.oauth2.client.id.{storage_account_name}.dfs.core.windows.net", "<client-id>")
spark.conf.set(f"fs.azure.account.oauth2.client.secret.{storage_account_name}.dfs.core.windows.net", "<client-secret>")
spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{storage_account_name}.dfs.core.windows.net", "https://login.microsoftonline.com/<tenant-id>/oauth2/token")

# Try to access
try:
    dbutils.fs.ls(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/")
    print("✓ Access successful!")
except Exception as e:
    print(f"✗ Access failed: {str(e)}")
    if "UnknownHostException" in str(e) or "timeout" in str(e):
        print("CONFIRMED: Network connectivity issue - Databricks cannot reach private endpoint")
```

## Recommended Action Plan

1. **Immediate**: Run the network test above to confirm the issue
2. **Short-term**: Consider temporarily enabling public access with IP restrictions
3. **Long-term**: Implement Private Link or VNet injection for Databricks

## For Network Admin

To properly connect Databricks to the storage private endpoint:

1. **Option A - Private Link**:
   - Enable Private Link on Databricks workspace
   - Create private endpoint for storage in Databricks VNet
   - Configure DNS resolution

2. **Option B - VNet Injection**:
   - Deploy new Databricks workspace with VNet injection into vision-vnet
   - Or migrate existing workspace (requires recreation)

3. **Option C - Service Endpoint**:
   - If Databricks is in a peered VNet
   - Add service endpoint for Storage on Databricks subnets
   - Update storage firewall to allow Databricks subnets

## Questions to Answer

1. Is the Databricks workspace VNet-injected or using managed VNet?
2. If VNet-injected, which VNet and subnets?
3. Is there an existing service principal for Databricks?
4. What's the acceptable solution: temporary public access or proper private networking?