# VM Access Guide - Power BI Development

## Overview
This guide provides instructions for contractors to securely access the Power BI development VM using Azure Bastion in the Azure Web Portal.

## VM Access Instructions

### Direct Bastion URL

1. **Open this link in your browser (Chrome or Edge recommended):**
   ```
   https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/rg-pbi-vendor-isolated/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor/bastionHost
   ```

2. **Sign in to Azure Portal**
   - Use your provided Azure AD account credentials
   - If prompted, complete any multi-factor authentication

3. **Connect to the VM**
   - You'll see the Bastion connection page
   - Enter these VM credentials:
     - **Username**: `BiDev`
     - **Password**: `e4_F[)YaTJ4R`
   - Click **Connect**

4. **You're connected!**
   - A new browser tab opens with the Windows desktop

### Important: Bookmark the URL
After your first successful connection, bookmark the Bastion URL for quick access next time.

## Working on the VM

### Pre-installed Software
- **Power BI Desktop** (Latest version)
- **Azure Storage Explorer**
- **Visual Studio Code**
- **Git for Windows**
- **Python 3.11**
- **Chrome & Edge browsers**

### Accessing Storage Account
The VM has private endpoint access to storage account `pbivend9084`:

1. **Storage Explorer**
   - Already configured for Azure AD auth
   - Sign in with your account
   - Navigate to: pbivend9084 → Blob Containers → data

2. **Power BI Connection**
   - URL: `https://pbivend9084.dfs.core.windows.net/data`
   - Use Organizational Account authentication

### Important Paths
- **Project Files**: `C:\Dev\PowerBI`
- **Sample Data**: Available in storage account `data` container
- **Documentation**: `C:\Dev\Docs`

## Best Practices

### Do's
- ✅ Use Bastion for all connections
- ✅ Sign out when finished working
- ✅ Save work to the designated project folders
- ✅ Use Azure AD authentication for all services

### Don'ts
- ❌ Don't attempt to install VPN software
- ❌ Don't try to expose RDP publicly
- ❌ Don't save sensitive data to desktop
- ❌ Don't share your credentials

## Troubleshooting

### Can't Connect via Bastion?
1. **Clear browser cache** and cookies
2. **Try different browser** (Edge/Chrome work best)
3. **Disable pop-up blockers** temporarily
4. **Check account permissions** - ensure you're added to the access group

### Slow Performance?
- Bastion provides good performance for development work
- If experiencing lag:
  - Close unnecessary browser tabs
  - Use wired internet connection
  - Try during off-peak hours

### Can't Access Storage?
1. Ensure you're signed into Storage Explorer
2. Your account needs to be in `visionbidevvm` group
3. Contact admin if you see permission errors

### Session Disconnected?
- Bastion sessions timeout after 4 hours of inactivity
- Simply reconnect using the same steps
- Your work is preserved on the VM

## Security Notes
- All connections are encrypted end-to-end
- No public IP exposure - everything goes through Azure backbone
- All actions are logged for security compliance
- VM is isolated in a secure subnet with restricted egress

## Getting Help
- **Access Problems**: Verify your account is properly configured
- **Azure Portal Help**: https://docs.microsoft.com/azure/bastion/

## Quick Reference Card
```
VM Name: visionpbidevvm
Access URL: https://portal.azure.com
Method: Connect → Bastion
Username: [Your Azure AD email]
Password: [Your Azure AD password]
Storage URL: https://pbivend9084.dfs.core.windows.net/data
```

---