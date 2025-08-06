# Databricks Storage Mount Instructions for Jason Jones

## Access Configuration
- **User**: jason.jones@cogitativo.com
- **Group**: visionbidevvm (Storage Blob Data Contributor)
- **Storage Account**: pbivend9084 (ADLS Gen2)
- **Access Method**: Azure AD authentication via group membership

## Mounting Code for Databricks

### Option 1: Azure AD Passthrough (Simplest)
Use this if your Databricks workspace supports Azure AD passthrough:

```python
# Run this in a Databricks notebook
storage_account_name = "pbivend9084"
container_name = "pbidata"  # Replace with actual container name
mount_point = f"/mnt/{container_name}"

# Mount using Azure AD passthrough authentication
dbutils.fs.mount(
  source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
  mount_point = mount_point,
  extra_configs = {
    "fs.azure.account.auth.type": "OAuth",
    "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider"
  }
)

# Test the mount
dbutils.fs.ls(mount_point)
```

### Option 2: Service Principal (More Control)
If passthrough doesn't work or you need a service principal:

```python
# Service Principal details (need to create one)
tenant_id = "<your-tenant-id>"
client_id = "<service-principal-app-id>"
client_secret = "<service-principal-secret>"

storage_account_name = "pbivend9084"
container_name = "pbidata"
mount_point = f"/mnt/{container_name}"

configs = {
  "fs.azure.auth.type": "OAuth",
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": client_id,
  "fs.azure.account.oauth2.client.secret": client_secret,
  "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
}

dbutils.fs.mount(
  source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
  mount_point = mount_point,
  extra_configs = configs
)
```

### Option 3: Direct Access (No Mount)
Access storage directly without mounting:

```python
# Direct access using Azure AD credentials
storage_account_name = "pbivend9084"
container_name = "pbidata"

# List files
dbutils.fs.ls(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/")

# Read a file
df = spark.read.parquet(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/path/to/file.parquet")
```

## Important Notes

1. **Network Access**: Ensure your Databricks workspace can reach the private endpoint
   - Workspace should be in the same VNet or peered VNet
   - Or have Private Link configured

2. **Authentication**: You're authenticated via Azure AD group membership
   - Group: visionbidevvm
   - Permission: Storage Blob Data Contributor

3. **Endpoint**: Use `dfs.core.windows.net` (not blob.core.windows.net)
   - This is required for ADLS Gen2 with hierarchical namespace

4. **No Access Keys**: This storage account doesn't use access keys
   - Only Azure AD authentication is allowed

## Troubleshooting

If you get authentication errors:
1. Verify you're logged into Databricks with jason.jones@cogitativo.com
2. Check that you're a member of visionbidevvm group
3. Ensure network connectivity to the private endpoint
4. Try Option 3 (direct access) first to test connectivity

## Need Help?
- For network issues: Check with your network admin about VNet/Private Link setup
- For auth issues: Verify group membership and permissions
- For mounting issues: Try direct access first, then mount