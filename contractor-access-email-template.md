# Email Template - Contractor VM Access

## Subject: Power BI Development VM Access Instructions

Hi [Contractor Name],

Your access to the Power BI development environment has been set up. You can connect to the Windows VM directly through your web browser - no VPN or special software needed.

**Quick Connect Instructions:**

1. Click this link: https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor/bastionHost

2. Sign in with your Azure account: [contractor-email@cogitativo.com]

3. Enter the VM credentials:
   - Username: BiDev
   - Password: e4_F[)YaTJ4R

4. Click Connect - the Windows desktop will open in your browser

**What's Available:**
- Power BI Desktop (pre-installed)
- Sample data already loaded in storage
- All necessary tools for development

**Data Access in Power BI:**
- Storage URL: https://pbivend9084.dfs.core.windows.net/data
- Use "Organizational account" authentication

I've attached two guides:
- contractor-quick-start.md - Simple 1-page instructions
- contractor-vm-access-guide.md - Detailed guide with troubleshooting

The VM uses Azure Bastion for security, which means:
- Works from any browser (Chrome/Edge recommended)
- No public IP exposure
- Encrypted connection
- No VPN needed

Please let me know once you've successfully connected, or if you encounter any issues.

Best regards,
[Your Name]

---

**First-time connection tip:** Make sure to allow pop-ups from portal.azure.com in your browser.