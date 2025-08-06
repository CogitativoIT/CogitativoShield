# VM Access Security Group Configuration

**Created:** July 29, 2025  
**Security Group Name:** visionbidevvm  
**Group ID:** b6dc070d-f050-41c0-af1a-c9bdf043ecef

## ✅ Configuration Complete

### Security Group Details

- **Display Name:** visionbidevvm
- **Description:** Security group for Power BI vendor VM access via Bastion
- **Type:** Security Group (mail-disabled)

### Permissions Granted

The security group has been assigned the following roles:

1. **Custom Role: "Power BI VM Bastion User"**
   - Scope: vm-pbi-vendor
   - Allows viewing VM details and connecting via Bastion
   - Includes read permissions for network resources

2. **Built-in Role: "Reader"**
   - Scope: Dtlaidev1-bastion (Bastion host)
   - Allows viewing the Bastion resource in portal

3. **Built-in Role: "Virtual Machine User Login"**
   - Scope: vm-pbi-vendor
   - Allows users to log into the VM as a regular user

### What Users Can Do

Members of this security group can:
- ✅ View the vm-pbi-vendor in Azure Portal
- ✅ Connect to the VM using Bastion
- ✅ Login to the VM with user-level privileges
- ✅ View network configuration (read-only)

### What Users Cannot Do

Members of this security group cannot:
- ❌ Start, stop, or restart the VM
- ❌ Change VM configuration
- ❌ Access other VMs in the subscription
- ❌ Modify network settings
- ❌ Access storage accounts or other resources

### How to Add Users

1. **Via Azure Portal:**
   ```
   Azure AD → Groups → Search "visionbidevvm" → Members → Add members
   ```

2. **Via Azure CLI:**
   ```bash
   # Get user object ID first
   az ad user show --id user@domain.com --query id -o tsv
   
   # Add user to group
   az ad group member add --group visionbidevvm --member-id <user-object-id>
   ```

### Testing Access

After adding a user to the group:

1. User logs into Azure Portal
2. Navigate to: **Virtual Machines** → **vm-pbi-vendor**
3. Click **Connect** → **Bastion**
4. Enter VM credentials:
   - Username: azureadmin
   - Password: (the password you set)

### Important Notes

- Users need to be added to this security group to get access
- It may take up to 30 minutes for permissions to propagate
- Users will only see resources they have access to in the portal
- The VM password should be changed from the default
- Consider enabling Azure AD authentication on the VM for better security

### Custom Role Definition

The custom role "Power BI VM Bastion User" includes:
- Read access to VM and network resources
- Bastion connection permissions
- Virtual machine login data action

Role ID: 28990946-4347-4149-84af-b9be9b38ee17