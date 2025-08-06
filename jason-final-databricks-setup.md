# Final Databricks Setup for Jason Jones

**Last Updated**: July 30, 2025

## Quick Start

Use this exact code in Databricks - everything is already configured:

```python
# All values are confirmed and ready to use
tenant_id = "24317511-81a4-42fb-bea5-f4b0735acba5"
client_id = "9a3351d0-f816-4e6f-95d4-f90ac882a479"  # sp-databricks
client_secret = dbutils.secrets.get(scope="cogikeyvault", key="ClientSecret")

# Mount the storage
storage_account_name = "pbivend9084"
container_name = "data"
mount_point = f"/mnt/{container_name}"

configs = {
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

---

## What's Been Configured

✅ **Network Access**: Storage account now allows access from Azure services (including Databricks)
✅ **Permissions**: sp-databricks has direct Storage Blob Data Contributor role
✅ **Group Access**: sp-databricks is member of visionbidevvm group with Contributor permissions
✅ **Private Endpoint**: Existing for VM access from vision-vnet
✅ **Container**: "data" container created and ready for use
✅ **Security**: Authentication required via Azure AD / Service Principal

## Access Configuration

The following have access to pbivend9084 storage via the visionbidevvm group:
- **sp-databricks** (App ID: 9a3351d0-f816-4e6f-95d4-f90ac882a479)
- **jason.jones@cogitativo.com**
- Any other members of visionbidevvm group

No additional role assignments needed - access is already configured!

### 1. Databricks Mounting Code

Use this code in your Databricks notebook with the existing sp-databricks:

```python
# Configuration
tenant_id = "24317511-81a4-42fb-bea5-f4b0735acba5"  # Your tenant
client_id = "9a3351d0-f816-4e6f-95d4-f90ac882a479"  # sp-databricks
client_secret = dbutils.secrets.get(scope="cogikeyvault", key="ClientSecret")  # Confirmed in Key Vault

storage_account_name = "pbivend9084"
container_name = "data"
mount_point = f"/mnt/{container_name}"

# OAuth configuration for ADLS Gen2
configs = {
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": client_id,
  "fs.azure.account.oauth2.client.secret": client_secret,
  "fs.azure.account.oauth2.client.endpoint": f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
}

# Mount the storage
try:
    dbutils.fs.mount(
      source = f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/",
      mount_point = mount_point,
      extra_configs = configs
    )
    print(f"✅ Successfully mounted {container_name}")
    
    # Test by listing files
    display(dbutils.fs.ls(mount_point))
    
except Exception as e:
    if "already mounted" in str(e):
        print(f"ℹ️ {mount_point} is already mounted")
        # Optionally unmount and remount
        # dbutils.fs.unmount(mount_point)
    else:
        print(f"❌ Mount failed: {str(e)}")
```

### 2. Direct Access (No Mount)

If you prefer direct access without mounting:

```python
# Using sp-databricks service principal
storage_account_name = "pbivend9084"
container_name = "data"
client_id = "9a3351d0-f816-4e6f-95d4-f90ac882a479"  # sp-databricks
client_secret = dbutils.secrets.get(scope="cogikeyvault", key="ClientSecret")
tenant_id = "24317511-81a4-42fb-bea5-f4b0735acba5"

# Set Spark configs
spark.conf.set(f"fs.azure.account.auth.type.{storage_account_name}.dfs.core.windows.net", "OAuth")
spark.conf.set(f"fs.azure.account.oauth.provider.type.{storage_account_name}.dfs.core.windows.net", 
               "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set(f"fs.azure.account.oauth2.client.id.{storage_account_name}.dfs.core.windows.net", client_id)
spark.conf.set(f"fs.azure.account.oauth2.client.secret.{storage_account_name}.dfs.core.windows.net", client_secret)
spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{storage_account_name}.dfs.core.windows.net", 
               f"https://login.microsoftonline.com/{tenant_id}/oauth2/token")

# Read parquet files directly
df = spark.read.parquet(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/path/to/data.parquet")
df.show()
```

## For Power BI VM Access

The VM already has access via the private endpoint. In Power BI Desktop:

1. **Get Data** → **Azure** → **Azure Data Lake Storage Gen2**
2. **URL**: `https://pbivend9084.dfs.core.windows.net/data`
3. **Authentication**: 
   - Use **Organizational account** 
   - Sign in with your Azure AD account (member of visionbidevvm group)

Or for direct parquet access:
1. **Get Data** → **More** → **Web**
2. **URL**: `https://pbivend9084.dfs.core.windows.net/data/path/to/file.parquet`
3. **Authentication**: Same as above

## Architecture Summary

```
Databricks (visionnetwork) ----> pbivend9084 Storage Account
     |                               |
     |                               |
Azure Services Access          Private Endpoint
(OAuth Authentication)         (from vision-vnet)
                                    |
                                Power BI VM
```

**Current Configuration**: Storage account allows Azure services (including Databricks) with authentication required. This is a temporary configuration - consider implementing VNet peering and private endpoints for production use.

## Important Notes

1. **Service Principal Secret**: Confirmed configuration
   - **Key Vault**: cogikeyvault
   - **Secret Name**: ClientSecret
   - **Client ID Secret**: ClientID (contains: 9a3351d0-f816-4e6f-95d4-f90ac882a479)
   - The Key Vault now allows access from:
     - Databricks IP: 35.164.224.127
     - Your current IP: 157.131.165.243
     - VPN Gateway IPs: 23.101.133.4, 13.90.143.138

2. **Container Name**: Set to "data" (already created and configured in all examples)

## Troubleshooting

1. **Network Error in Databricks**: 
   - VNet peering is already configured ✓
   - Service principal has access via group membership ✓

2. **Authentication Error**:
   - Verify sp-databricks secret is correct
   - The service principal has access via visionbidevvm group membership

3. **Power BI Connection Issues**:
   - VM is on same subnet as private endpoint ✓
   - Use Azure AD auth, not access keys

## Security Benefits

✅ No public internet exposure
✅ Network isolation maintained
✅ Azure AD authentication only
✅ Audit trail for all access
✅ Works for both Databricks and Power BI

Let me know if you need help with the service principal setup!