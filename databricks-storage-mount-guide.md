# Databricks Storage Mount Guide for pbivend9084

## Storage Account Configuration
- **Storage Account**: pbivend9084
- **Type**: ADLS Gen2 (Hierarchical namespace enabled)
- **Access**: Private endpoint only (no public access)
- **Authentication**: Azure AD only (no access keys)

## Mounting Options for Jason Jones

### Option 1: Service Principal Authentication (Recommended)
Since the storage account doesn't use access keys, use Azure AD authentication:

```python
# Databricks notebook code
storage_account_name = "pbivend9084"
container_name = "pbidata"  # or your container name
mount_point = f"/mnt/{container_name}"

# Service Principal credentials (need to create)
client_id = "<service-principal-application-id>"
client_secret = "<service-principal-secret>"
tenant_id = "<your-tenant-id>"

configs = {
  "fs.azure.auth.type": "OAuth",
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": client_id,
  "fs.azure.account.oauth2.client.secret": client_secret,
  "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
}

# Mount using ABFS (Azure Blob File System) for ADLS Gen2
dbutils.fs.mount(
  source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
  mount_point = mount_point,
  extra_configs = configs
)
```

### Option 2: Direct User Authentication (If Jason has direct access)
If Jason Jones is added to the storage account with proper RBAC:

```python
# Use Azure AD passthrough authentication
storage_account_name = "pbivend9084"
container_name = "pbidata"
mount_point = f"/mnt/{container_name}"

configs = {
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider",
}

dbutils.fs.mount(
  source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
  mount_point = mount_point,
  extra_configs = configs
)
```

### Option 3: Temporary Direct Access (Not recommended for production)
For quick testing, you could temporarily enable access keys:

```bash
# Enable access keys (requires owner permissions)
az storage account update \
  --name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --allow-shared-key-access true

# Get access key
az storage account keys list \
  --account-name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --query "[0].value" -o tsv
```

Then use the original mounting code with the access key.

## Prerequisites

### For Option 1 (Service Principal):
1. Create a Service Principal
2. Grant Storage Blob Data Contributor role to the Service Principal
3. Ensure Databricks workspace can reach the private endpoint

### For Option 2 (User Authentication):
1. Add Jason Jones with Storage Blob Data Contributor role
2. Ensure Databricks has network connectivity to private endpoint

## Network Considerations
Since the storage uses private endpoints:
- Databricks workspace must be in the same VNet or peered VNet
- Or use Private Link/ExpressRoute for connectivity
- Public internet access is blocked

## Recommended Approach
1. Create a dedicated Service Principal for Databricks
2. Grant appropriate permissions on the storage account
3. Use Option 1 mounting code
4. Store Service Principal credentials in Databricks secrets

Would you like me to help create the Service Principal and set up the permissions?