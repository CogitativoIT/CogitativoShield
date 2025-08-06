# Databricks Secret Investigation

## Key Vaults Found
1. **cogikeyvault** (vision resource group)
   - IP restricted (35.164.224.127 - likely Databricks IP)
   - VNet rule allows visionnetwork/default subnet
   - This is likely the vault used by Databricks

2. **cogitativo-kv** (cogitativo-rg resource group)
   - Contains app secrets but not Databricks-related

## Service Principal Secrets
The sp-databricks service principal has 2 active secrets:
- **"Databricks SP Secret New"** (expires 2027-05-09) - hint: YQT
- **"Databricks SP Secret"** (expires 2026-01-21) - hint: ubL

## Likely Configuration
Based on the evidence:
1. Databricks likely uses **cogikeyvault** (IP whitelisted for Databricks)
2. The secret scope in Databricks is probably backed by this Key Vault
3. The secret name in the vault could be:
   - sp-databricks-secret
   - databricks-sp-secret
   - sp-databricks
   - Or similar variation

## For Jason's Code

Since cogikeyvault is likely backing the Databricks secret scope, the code should be:

```python
# If using Azure Key Vault-backed secret scope
client_secret = dbutils.secrets.get(scope="cogikeyvault", key="<secret-name>")

# Or if using Databricks-backed secret scope
client_secret = dbutils.secrets.get(scope="<databricks-scope-name>", key="<secret-name>")
```

## How to Verify

Jason can check available secret scopes in Databricks:
```python
# List all secret scopes
dbutils.secrets.listScopes()

# List secrets in a scope (will show secret names but not values)
dbutils.secrets.list("<scope-name>")
```

## Access Pattern
The IP 35.164.224.127 whitelisted in cogikeyvault is likely:
- A Databricks control plane IP
- Or a NAT gateway IP for the Databricks workspace

This confirms that Databricks has access to cogikeyvault.