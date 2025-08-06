# Databricks Storage Mount Instructions for Jason Jones

## Prerequisites Checklist

### 1. Storage Account Configuration
- **Account Name**: pbivend9084
- **Type**: ADLS Gen2 (Hierarchical namespace enabled)
- **Access**: Private endpoint only (no public access)
- **Private Endpoint**: pe-pbivend9084 (DFS endpoint)
- **Network**: Default action = Deny, only accessible via private endpoint

### 2. Your Access
- **User**: jason.jones@cogitativo.com
- **Group**: visionbidevvm (with Storage Blob Data Contributor role)
- **Permissions**: Read/Write access to storage via group membership

### 3. Network Requirements
⚠️ **CRITICAL**: Your Databricks workspace MUST have network connectivity to the private endpoint. This means:
- Databricks workspace should be in the same VNet (vision-vnet) OR
- In a peered VNet with proper routing OR
- Using Azure Private Link for Databricks

**If you get network timeout errors, this is the issue!**

## Step 1: Grant Service Principal Access

If your existing Databricks service principal needs access to pbivend9084:

```bash
# Replace <service-principal-id> with your actual SP application ID
az role assignment create \
  --assignee "<service-principal-id>" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"
```

## Step 2: Mount Code for Databricks

### Option A: Using Service Principal (Recommended)

```python
# Databricks notebook code
# Replace these with your actual service principal details
tenant_id = "<your-tenant-id>"  # e.g., "24317511-81a4-42fb-bea5-f4b0735acba5"
client_id = "<your-service-principal-app-id>"
client_secret = "<your-service-principal-secret>"

# Storage details
storage_account_name = "pbivend9084"
container_name = "pbidata"  # Replace with your actual container name
mount_point = f"/mnt/{container_name}"

# Configuration for ADLS Gen2
configs = {
  "fs.azure.auth.type": "OAuth",
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": client_id,
  "fs.azure.account.oauth2.client.secret": client_secret,
  "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
}

# Mount using ABFS (Azure Blob File System) - REQUIRED for ADLS Gen2
try:
    dbutils.fs.mount(
      source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
      mount_point = mount_point,
      extra_configs = configs
    )
    print(f"Successfully mounted {container_name} at {mount_point}")
    
    # Test the mount
    display(dbutils.fs.ls(mount_point))
except Exception as e:
    print(f"Mount failed: {str(e)}")
```

### Option B: Direct Access Without Mounting

If mounting fails due to network issues, try direct access first:

```python
# Direct access to test connectivity
storage_account_name = "pbivend9084"
container_name = "pbidata"

# Configure Spark session for OAuth
spark.conf.set(f"fs.azure.account.auth.type.{storage_account_name}.dfs.core.windows.net", "OAuth")
spark.conf.set(f"fs.azure.account.oauth.provider.type.{storage_account_name}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(f"fs.azure.account.oauth2.client.id.{storage_account_name}.dfs.core.windows.net", "<your-client-id>")
spark.conf.set(f"fs.azure.account.oauth2.client.secret.{storage_account_name}.dfs.core.windows.net", "<your-client-secret>")
spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{storage_account_name}.dfs.core.windows.net", f"https://login.microsoftonline.com/<tenant-id>/oauth2/token")

# Try to list files
try:
    files = dbutils.fs.ls(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/")
    display(files)
except Exception as e:
    print(f"Access failed: {str(e)}")
```

## Common Issues and Solutions

### 1. Network Timeout / Connection Refused
**Error**: `java.net.ConnectException: Connection refused` or timeout errors
**Solution**: 
- Databricks cannot reach the private endpoint
- Contact your network admin to ensure Databricks workspace has connectivity to the private endpoint
- May need to deploy Databricks in the same VNet or set up VNet peering

### 2. Authentication Failed
**Error**: `401 Unauthorized` or `403 Forbidden`
**Solution**:
- Verify service principal has Storage Blob Data Contributor role
- Check client ID, secret, and tenant ID are correct
- Ensure secret hasn't expired

### 3. Invalid Endpoint
**Error**: `Invalid URI` or `Account not found`
**Solution**:
- Must use `dfs.core.windows.net` (not blob.core.windows.net)
- Must use `abfss://` protocol (not wasbs://)
- Verify container name exists

### 4. Mount Already Exists
**Error**: `Directory already mounted`
**Solution**:
```python
# Unmount first
dbutils.fs.unmount(mount_point)
# Then try mounting again
```

## Important Notes

1. **DO NOT USE**:
   - ❌ `blob.core.windows.net` endpoint
   - ❌ `wasbs://` protocol
   - ❌ Access keys (they're disabled)

2. **MUST USE**:
   - ✅ `dfs.core.windows.net` endpoint
   - ✅ `abfss://` protocol
   - ✅ Service Principal OAuth authentication

3. **Network Connectivity**: If you're getting timeouts, the issue is network connectivity, not authentication. Your Databricks workspace needs to be able to reach the private endpoint.

## Need Help?

If you encounter issues:
1. Try Option B (direct access) first to test connectivity
2. Verify your Databricks workspace network configuration
3. Check if your service principal has the correct permissions
4. Ensure you're using the DFS endpoint with ABFS protocol

Contact your admin if you need:
- Service principal credentials
- Network connectivity setup between Databricks and the storage private endpoint
- Additional permissions on the storage account