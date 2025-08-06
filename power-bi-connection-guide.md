# Power BI Connection Guide - pbivend9084 Storage

## Method 1: Connect to Entire Folder (Recommended)

This method lets you access all parquet files at once and combine them if needed.

### Steps:
1. Open **Power BI Desktop**

2. Click **Get Data** → **More...**

3. Search for and select **Azure Data Lake Storage Gen2**
   - Click **Connect**

4. In the URL field, enter:
   ```
   https://pbivend9084.dfs.core.windows.net/data
   ```

5. For **Authentication**, select **Organizational account**
   - Click **Sign in**
   - Use your Azure AD credentials (andre.darby@cogitativo.com)
   - Click **Connect**

6. You'll see a navigator showing all files:
   - ✓ customers.parquet
   - ✓ daily_sales_summary.parquet
   - ✓ inventory_snapshots.parquet
   - ✓ products.parquet
   - ✓ sales_transactions.parquet

7. Select the files you want to import (check multiple boxes)

8. Click **Transform Data** to open Power Query Editor
   - Or click **Load** to import directly

## Method 2: Direct Parquet File Access

For accessing a specific parquet file directly:

### Steps:
1. Open **Power BI Desktop**

2. Click **Get Data** → **Web**

3. Enter the direct file URL, for example:
   ```
   https://pbivend9084.dfs.core.windows.net/data/daily_sales_summary.parquet
   ```

4. Click **OK**

5. For **Authentication**:
   - Select **Organizational account**
   - Click **Sign in** with your Azure AD account
   - Click **Connect**

6. Power BI will automatically recognize the parquet format and load the data

## Method 3: Using Azure Blob Storage Connector

Alternative approach using the Blob Storage connector:

### Steps:
1. **Get Data** → **Azure** → **Azure Blob Storage**

2. Enter Account Name:
   ```
   pbivend9084
   ```

3. For **Authentication**:
   - Choose **Organizational account**
   - Sign in with Azure AD

4. Navigate to the **data** container

5. Select your parquet files

## Creating Relationships in Power BI

Once you've loaded multiple tables:

1. Go to **Model** view (left sidebar)

2. Create relationships:
   - Drag **CustomerID** from sales_transactions to customers
   - Drag **ProductID** from sales_transactions to products

3. Relationship diagram:
   ```
   customers ---(1:*)--- sales_transactions ---(1:*)--- products
   ```

## Sample Visualizations to Create

### 1. Sales Dashboard
- **Card Visual**: Total Revenue (sum of TotalAmount)
- **Line Chart**: Sales over time (TransactionDate by TotalAmount)
- **Pie Chart**: Sales by ProductCategory
- **Bar Chart**: Top 10 Products by Revenue

### 2. Customer Analysis
- **Donut Chart**: Customer Segments
- **Map**: Sales by StoreLocation
- **Table**: Top Customers by Total Spent

### 3. Inventory Dashboard
- **Column Chart**: Stock Levels by Product Category
- **Line Chart**: Inventory Trends over Time

## Power Query Tips

### Combine Monthly Partitioned Data
If you need to combine partitioned data later:

1. In Power Query Editor
2. Right-click on the folder → **Combine Files**
3. Power Query will automatically merge all parquet files

### Add Calculated Columns
Example DAX formulas:

```dax
// Profit Margin
Profit Margin = 
DIVIDE(
    SUM(sales_transactions[TotalAmount]) - SUM(products[CostPrice] * sales_transactions[Quantity]),
    SUM(sales_transactions[TotalAmount])
)

// Year-over-Year Growth
YoY Growth = 
VAR CurrentYearSales = SUM(sales_transactions[TotalAmount])
VAR PreviousYearSales = CALCULATE(
    SUM(sales_transactions[TotalAmount]),
    DATEADD(sales_transactions[TransactionDate], -1, YEAR)
)
RETURN
DIVIDE(CurrentYearSales - PreviousYearSales, PreviousYearSales)
```

## Troubleshooting

### Authentication Issues
- Ensure you're using **Organizational account** (not Account key)
- You must be member of **visionbidevvm** group (you are)
- Sign out and sign in again if needed

### Performance Tips
- Use **Import** mode for this dataset (it's small)
- For larger datasets, consider **DirectQuery**
- Use the pre-aggregated daily_sales_summary for faster dashboards

### Can't See Files?
- The storage account is configured to allow Azure services
- Your account has access via the visionbidevvm group
- Try refreshing credentials: File → Options → Data Source Settings

## Quick Test Query

After loading sales_transactions, try this quick measure:

1. New Measure:
   ```dax
   Total Sales = SUM(sales_transactions[TotalAmount])
   ```

2. Create a card visual with Total Sales

3. Add a slicer for StoreLocation

You should see the total sales amount change as you select different stores!