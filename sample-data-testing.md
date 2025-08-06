# Sample Data Testing Guide

## Quick Start

1. **Generate Sample Data**
   ```bash
   python generate-sample-parquet.py
   ```
   This creates mock data in the `sample_data/` directory.

2. **Upload to Azure Storage**
   ```bash
   python upload-sample-data.py
   ```
   This uploads all files to the `data` container in `pbivend9084` storage account.

## Sample Data Overview

The mock dataset represents a retail business with:

### 📊 Data Files Created

1. **sales_transactions.parquet** (10,000 records)
   - Transaction-level sales data
   - Columns: TransactionID, Date, CustomerID, ProductID, Quantity, Price, etc.

2. **customers.parquet** (~3,000 records)
   - Customer master data
   - Columns: CustomerID, Name, Email, Location, Segment, etc.

3. **products.parquet** (~400 records)
   - Product catalog
   - Columns: ProductID, Name, Category, Price, Stock levels, etc.

4. **daily_sales_summary.parquet** (aggregated data)
   - Pre-aggregated daily sales by store and category
   - Great for Power BI dashboards

5. **inventory_snapshots.parquet** (weekly snapshots)
   - Historical inventory levels by warehouse

6. **sales_partitioned/** (partitioned by year/month)
   - Same as sales_transactions but partitioned for better query performance

## Testing in Databricks

```python
# Quick test - list files
dbutils.fs.ls("/mnt/data")

# Read sales data
df_sales = spark.read.parquet("/mnt/data/sales_transactions.parquet")
df_sales.show(10)

# Query partitioned data
df_2024 = spark.read.parquet("/mnt/data/sales_partitioned/year=2024/")
df_2024.groupBy("ProductCategory").sum("TotalAmount").show()

# Join example
df_customers = spark.read.parquet("/mnt/data/customers.parquet")
df_products = spark.read.parquet("/mnt/data/products.parquet")

sales_with_details = df_sales \
    .join(df_customers, "CustomerID") \
    .join(df_products, "ProductID") \
    .select("TransactionDate", "CustomerSegment", "ProductCategory", "TotalAmount")

sales_with_details.show()
```

## Testing in Power BI

### Method 1: Direct Parquet Files
1. Open Power BI Desktop
2. Get Data → Web
3. Enter URL: `https://pbivend9084.dfs.core.windows.net/data/daily_sales_summary.parquet`
4. Authenticate with Organizational Account

### Method 2: Folder Connection (Recommended)
1. Get Data → Azure → Azure Data Lake Storage Gen2
2. URL: `https://pbivend9084.dfs.core.windows.net/data`
3. Authenticate with Organizational Account
4. Navigate and select multiple files

### Sample Power BI Visualizations to Create

1. **Sales Dashboard**
   - Total Sales by Month (Line Chart)
   - Sales by Product Category (Pie Chart)
   - Top 10 Products by Revenue (Bar Chart)
   - Sales by Store Location (Map)

2. **Customer Analytics**
   - Customer Segmentation (Donut Chart)
   - Average Order Value by Segment
   - Customer Geographic Distribution

3. **Inventory Dashboard**
   - Current Stock Levels by Category
   - Products Below Reorder Level
   - Inventory Trends Over Time

## Data Relationships

```
customers (CustomerID) ----< sales_transactions >---- products (ProductID)
                                    |
                                    v
                          daily_sales_summary
                                    ^
                                    |
                          inventory_snapshots
```

## Sample Queries

### Find Top Customers
```sql
SELECT c.CustomerID, c.CustomerSegment, SUM(s.TotalAmount) as TotalSpent
FROM sales_transactions s
JOIN customers c ON s.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerSegment
ORDER BY TotalSpent DESC
LIMIT 10
```

### Monthly Sales Trend
```sql
SELECT 
    DATE_TRUNC('month', TransactionDate) as Month,
    ProductCategory,
    SUM(TotalAmount) as Revenue
FROM sales_transactions
GROUP BY Month, ProductCategory
ORDER BY Month, Revenue DESC
```

## File Sizes

- Total dataset: ~5-10 MB
- Suitable for testing without long load times
- Enough variety for meaningful analytics

## Notes

- All customer emails are fake (customer{id}@example.com)
- Product names are generic (Product 101, Product 102, etc.)
- Dates cover the last 2 years of data
- Prices and quantities are randomly generated but realistic