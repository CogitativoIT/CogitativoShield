# Databricks Storage Access Test Instructions

## How to Run the Test

1. **Open Databricks Workspace**
   - Navigate to your `cogitativo-vision` workspace
   - Create a new Python notebook

2. **Copy the Test Code**
   - Copy all code from `databricks-test-access.py`
   - Paste into a notebook cell

3. **Run the Test**
   - Execute the cell
   - The script will:
     - ✅ Test connectivity to storage
     - ✅ Create a sample DataFrame
     - ✅ Write it as a parquet file
     - ✅ Read it back to verify access
     - ✅ List container contents

## Expected Output

If successful, you'll see:
```
✅ Configuration loaded
✅ Spark configuration set
✅ Successfully connected! Container is empty (as expected)
📝 Creating test data...
✅ Test DataFrame created:
+---+-----------+------+-------------------+
| id|       name| value|          timestamp|
+---+-----------+------+-------------------+
|  1|Test User 1| 100.5|2025-07-30 18:30:...|
|  2|Test User 2|200.75|2025-07-30 18:30:...|
|  3|Test User 3|300.25|2025-07-30 18:30:...|
+---+-----------+------+-------------------+

💾 Writing test parquet file...
✅ Test parquet file written successfully!
🎉 All tests passed! Storage access is working correctly.
```

## Troubleshooting

### Error: "Secret not found"
- Run `dbutils.secrets.listScopes()` to verify cogikeyvault scope exists
- Run `dbutils.secrets.list("cogikeyvault")` to check if ClientSecret exists

### Error: "Network timeout" or "Unknown host"
- VNet peering issue between Databricks and storage
- Contact admin to verify network configuration

### Error: "403 Forbidden"
- sp-databricks doesn't have Storage Blob Data Contributor role
- Already fixed, but verify with admin if still occurs

## After Successful Test

You can now:
1. Use the mounting code from the main instructions
2. Read/write parquet files to `abfss://data@pbivend9084.dfs.core.windows.net/`
3. Delete the test file if desired: `dbutils.fs.rm(test_path, True)`

## Power BI Access

From the VM, you can connect Power BI to the test file:
- **URL**: `https://pbivend9084.dfs.core.windows.net/data/test_data.parquet`
- **Auth**: Organizational account (your Azure AD)