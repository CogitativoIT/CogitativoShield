# Windows Server 2022 Setup Complete

## VM Configuration
- **OS**: Windows Server 2022 Datacenter
- **VM Name**: vm-pbi-vendor
- **Resource Group**: rg-pbi-vendor-isolated
- **Size**: Standard_D4s_v3
- **Private IP**: 10.0.11.4
- **Access**: Via VISION-VNET-BASTION only

## Why Windows Server 2022?
✅ **Multiple concurrent RDP sessions** without additional licensing
✅ **Built-in Remote Desktop Services** 
✅ **No RDP CAL requirements** for admin connections
✅ **Better for shared vendor access**

## Admin Credentials
- **Username**: pbiadmin
- **Password**: SecureP@ssw0rd2024!

## Creating Vendor Users
Since Windows Server 2022 doesn't support Azure AD join, create local users:

1. Connect to VM via Bastion using admin credentials
2. Run PowerShell as Administrator
3. Use the provided script:

```powershell
# Example: Create a vendor user
$password = ConvertTo-SecureString "VendorP@ssw0rd123!" -AsPlainText -Force
.\create-vendor-users.ps1 -Username "vendor1" -FullName "Power BI Vendor 1" -Password $password
```

## Access Permissions
The `visionbidevvm` security group has:
- ✅ Virtual Machine User Login 
- ✅ Storage Blob Data Reader on pbivend9084
- ✅ Reader access to required resources

## Software Installed
- ✅ Power BI Desktop (installation in progress)
- ✅ Windows Server with RDS capabilities

## Next Steps
1. Connect via Bastion with admin account
2. Create vendor user accounts as needed
3. Share vendor credentials securely
4. Each vendor can connect simultaneously via Bastion