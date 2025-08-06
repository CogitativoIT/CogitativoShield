# Databricks Access Instructions for Jason Jones

## Current Situation

You have **two storage accounts** with different configurations:

1. **cogidatalake** (existing) - Works with Databricks ✅
   - Public access enabled with network restrictions
   - Databricks VNet-injected with direct connectivity
   - Uses access keys (less secure but works)

2. **pbivend9084** (new) - Doesn't work with Databricks yet ❌
   - Private endpoint only (maximum security)
   - Different VNet, no Databricks connectivity
   - No access keys (Azure AD only)

## Why cogidatalake Works

Your Databricks workspace `cogitativo-vision` is VNet-injected into `visionnetwork` with dedicated subnets. The cogidatalake storage account has firewall rules allowing these Databricks subnets, so it "just works."

## Immediate Solution for pbivend9084

### Option 1: Quick Fix (5 minutes)
Enable temporary public access with Databricks subnet whitelisting:

```bash
# Run this to enable access (I can do this for you)
az storage account update \
  --name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --public-network-access Enabled

# Add Databricks subnets to firewall
az storage account network-rule add \
  --account-name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --vnet-name visionnetwork \
  --subnet private-databricks-subnet

az storage account network-rule add \
  --account-name pbivend9084 \
  --resource-group rg-pbi-vendor-isolated \
  --vnet-name visionnetwork \
  --subnet public-databricks-subnet
```

Then use this code in Databricks:
```python
# After network fix is applied
storage_account_name = "pbivend9084"
container_name = "pbidata"

# Using your existing service principal
spark.conf.set("fs.azure.account.auth.type", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id", "<your-sp-client-id>")
spark.conf.set("fs.azure.account.oauth2.client.secret", "<your-sp-secret>")
spark.conf.set("fs.azure.account.oauth2.client.endpoint", "https://login.microsoftonline.com/<tenant-id>/oauth2/token")

# Access data
df = spark.read.parquet(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/")
```

### Option 2: Use Existing cogidatalake
If pbivend9084 setup is taking too long, use cogidatalake:

```python
# This already works in your Databricks
storage_account_name = "cogidatalake"
container_name = "<your-container>"

# If using access key (current method)
spark.conf.set(
  f"fs.azure.account.key.{storage_account_name}.dfs.core.windows.net",
  "<access-key-or-secret-from-key-vault>"
)

# Access data
df = spark.read.parquet(f"abfss://{container_name}@{storage_account_name}.dfs.core.windows.net/path")
```

## Security Comparison

| Aspect | cogidatalake | pbivend9084 | Winner |
|--------|--------------|-------------|---------|
| Network Security | Public with restrictions | Private only | pbivend9084 |
| Authentication | Access keys | Azure AD only | pbivend9084 |
| Ease of Use | Simple | Complex | cogidatalake |
| Databricks Ready | Yes | No (needs config) | cogidatalake |

## Recommended Architecture (Best of Both)

For a scalable, secure solution:

1. **Short-term**: Enable controlled public access on pbivend9084 with Databricks subnet whitelisting
2. **Medium-term**: Migrate to Service Principal authentication (no access keys)
3. **Long-term**: Implement VNet peering between vision-vnet and visionnetwork

## What Jason Needs to Do

1. **Test connectivity** in Databricks:
   ```python
   # Run this to check if you can reach the storage
   import socket
   try:
       socket.gethostbyname("pbivend9084.dfs.core.windows.net")
       print("✓ Can resolve pbivend9084")
   except:
       print("✗ Cannot resolve pbivend9084 - need network fix")
   ```

2. **If test fails**, we need to apply the network fix (Option 1 above)

3. **Once connected**, use the mounting code with your service principal

## Questions for Jason

1. Do you have the service principal credentials for Databricks?
2. Which storage account do you prefer to use?
3. Is temporary public access acceptable for pbivend9084?

Let me know which option you'd like to proceed with!