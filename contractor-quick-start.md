# Quick Start - VM Access for Contractors

## 🚀 Connect in 3 Steps

### 1. Click this link:
🔗 https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor/bastionHost

### 2. Sign in and Connect
- Sign in with your Azure account (if prompted)
- Enter VM credentials:
  - Username: `BiDev`
  - Password: `e4_F[)YaTJ4R`
- Click **Connect**

### 3. You're In!
- Browser window shows Windows desktop
- Power BI Desktop is on the desktop
- Storage data is ready to use

## 📁 Access Your Data in Power BI

1. Open Power BI Desktop
2. Get Data → Azure → Azure Data Lake Storage Gen2
3. Paste: `https://pbivend9084.dfs.core.windows.net/data`
4. Choose "Organizational account" → Sign in
5. Select parquet files → Load

## 💡 Tips
- **Bookmark this**: After first connection, bookmark the Bastion page
- **Session timeout**: 4 hours - just reconnect if disconnected
- **Best browsers**: Edge or Chrome
- **Pop-ups**: Allow pop-ups from portal.azure.com

## ❓ Need Help?
Can't connect? Check:
- ✓ Using correct email/password
- ✓ Pop-up blocker disabled
- ✓ Using Chrome/Edge browser

---
That's it! No VPN, no RDP client needed - just your browser.