# Bastion Connection Instructions for Guest Users

## The Problem
When the VM was moved to `rg-pbi-vendor-isolated`, the Azure Portal's automatic Bastion discovery doesn't work properly. The portal tries to create a NEW Bastion instead of using the existing one.

## The Solution - Two Options:

### Option 1: Direct Bastion Navigation (Recommended)
1. Share this URL with your test user:
   ```
   https://portal.azure.com/#@24317511-81a4-42fb-bea5-f4b0735acba5/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/openai-dev/providers/Microsoft.Network/bastionHosts/Dtlaidev1-bastion/connect
   ```

2. User clicks the link and:
   - Selects **Resource type**: Virtual Machine
   - Selects **Subscription**: Cogitativo
   - Selects **Virtual machine**: vm-pbi-vendor
   - Enters credentials
   - Clicks **Connect**

### Option 2: Manual Navigation
1. User logs into Azure Portal
2. Search for "Bastion" in the top search bar
3. Click on **Dtlaidev1-bastion**
4. Click **Connect** in the left menu
5. Select the VM and enter credentials

### Option 3: Create a Bastion in the Isolated RG (Not Recommended)
This would require additional cost and management but would make the portal experience smoother.

## Why This Happens
- Bastion auto-discovery expects resources in the same resource group
- Cross-RG Bastion connections work fine but require manual selection
- The portal's "Deploy Bastion" button appears because it can't find a Bastion in the VM's current RG

## For Your Admin Account
You don't see this issue because you have permissions across all resource groups, so the portal can discover the Bastion automatically.

## Permanent Fix Options
1. **Use Option 1** - Bookmark the direct Bastion URL
2. **Create documentation** for guest users with the direct link
3. **Consider moving Bastion** to the isolated RG (not recommended due to cost)