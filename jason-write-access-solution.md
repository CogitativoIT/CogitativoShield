# Solution: Databricks Write Access for Jason Jones

## Problem Summary
Jason is getting a 403 error when trying to write parquet files from Databricks:
- **Error**: "This request is not authorized to perform this operation using this permission"
- **Operation**: Writing parquet files to `/mnt/data/test/persons_filtered_features`
- **Root Cause**: The visionbidevvm group only has **Read** permissions, not **Write**

## Solution Required

### Grant Storage Blob Data Contributor Role
The visionbidevvm group needs to be upgraded from "Storage Blob Data Reader" to "Storage Blob Data Contributor" role.

**Azure Portal Steps:**
1. Navigate to the storage account: `pbivend9084`
2. Go to "Access Control (IAM)" in the left menu
3. Click "+ Add" → "Add role assignment"
4. Search for "Storage Blob Data Contributor"
5. Click Next to "Members" tab
6. Select "User, group, or service principal"
7. Search for "visionbidevvm" and select it
8. Click "Review + assign"

**Azure CLI Command:**
```bash
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee b6dc070d-f050-41c0-af1a-c9bdf043ecef \
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"
```

## What This Enables

Once the role is granted, Jason (and all visionbidevvm group members) can:
- ✅ Read existing files (current capability)
- ✅ Write new parquet files
- ✅ Create new directories
- ✅ Overwrite existing files
- ✅ Delete files if needed

## For Jason - Test After Permission Update

Once permissions are updated, test with this code:

```python
# Test write access
test_df = spark.range(10).toDF("id")
test_path = "/mnt/data/test/permission_test.parquet"

try:
    # Write test file
    test_df.write.mode("overwrite").parquet(test_path)
    print("✅ Write successful!")
    
    # Read it back
    df_check = spark.read.parquet(test_path)
    print(f"✅ Read successful! Rows: {df_check.count()}")
    
    # Clean up
    dbutils.fs.rm(test_path, True)
    print("✅ Delete successful! All permissions working.")
    
except Exception as e:
    print(f"❌ Still getting error: {str(e)}")
```

## Important Notes

1. **Permission Propagation**: After granting the role, it may take 2-5 minutes for permissions to fully propagate.

2. **Group Membership Verified**: 
   - Jason Jones ✅ (member of visionbidevvm)
   - sp-databricks ✅ (member of visionbidevvm)

3. **Current vs Required Permissions**:
   - **Current**: Storage Blob Data Reader (read-only)
   - **Required**: Storage Blob Data Contributor (read/write)

4. **No Code Changes Needed**: Jason's existing Databricks code will work once permissions are updated.

## Alternative: Direct Assignment
If group permissions don't work, assign directly to Jason:
```bash
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee jason.jones@cogitativo.com \
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Storage/storageAccounts/pbivend9084"
```