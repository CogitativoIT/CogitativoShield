# Power BI Vendor - VM Connection Guide

## Direct Connection URL

Use this URL to access the Bastion host directly:

**https://portal.azure.com/#@cogitativo.net/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion/overview**

## Connection Steps

1. **Click the URL above** to go directly to the Bastion host

2. **Click "Connect"** in the left menu
   
3. **Configure connection:**
   - Resource type: `Virtual Machine`
   - Subscription: `Cogitativo`
   - Virtual machine: `vm-pbi-vendor`
   - Username: `azureadmin`
   - Password: `[provide password]`
   - Click **Connect**

## Alternative Method

If the direct URL doesn't work:

1. Go to https://portal.azure.com
2. In the search bar, type "Bastion"
3. Click on "Bastion hosts"
4. Click on "Dtlaidev1-bastion"
5. Follow steps 2-3 above

## Important Notes

- **DO NOT** click "Deploy Bastion" if prompted
- You must use the existing Bastion (Dtlaidev1-bastion)
- The VM name is: vm-pbi-vendor
- Change the password on first login

## Troubleshooting

If you see "No access" errors:
1. Make sure you're logged in with your guest account
2. Clear browser cache and try again
3. Contact admin if issues persist