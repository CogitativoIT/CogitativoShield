# Power BI Vendor Sandbox - Deployment Summary

**Deployment Date:** July 29, 2025  
**Deployed By:** Claude Code for andre.darby@cogitativo.com

## ✅ Deployment Completed Successfully!

### 📊 Infrastructure Details

#### Storage Account
- **Name:** pbivend9084
- **Resource Group:** vision
- **Location:** East US
- **Type:** ADLS Gen2 (Hierarchical Namespace enabled)
- **Container:** parquet
- **Endpoint:** `https://pbivend9084.dfs.core.windows.net/parquet`
- **Access:** Private endpoint only (no public access)

#### Private Endpoint
- **Name:** pe-pbivend9084
- **Subnet:** gitlab-private-subnet (10.0.10.0/24)
- **Connection:** Successfully established to storage account

#### Virtual Machine
- **Name:** vm-pbi-vendor
- **Resource Group:** vision
- **Type:** Windows Server 2022 Datacenter
- **Size:** Standard_D4s_v3 (4 vCPUs, 16 GB RAM)
- **Private IP:** 10.0.11.4
- **Subnet:** snet-pbi-vendor (10.0.11.0/24) - *New subnet created*
- **Public IP:** None (Bastion access only)

### 🔐 Access Credentials

#### VM Access
- **Username:** azureadmin
- **Password:** PbiVend0r2025!@#$
- **⚠️ IMPORTANT:** Change this password immediately upon first login!

#### Bastion Access
- **Bastion Host:** Dtlaidev1-bastion (in openai-dev resource group)
- **Access Method:** Via Azure Portal

### 🔑 Permissions Configured

#### Databricks Service Principal
- **Name:** sp-databricks
- **Object ID:** 9898eeb9-ca55-454a-a700-277787530074
- **Role:** Storage Blob Data Contributor (pending manual configuration)
- **Scope:** Storage account level

### 📋 Next Steps

1. **Access the VM via Bastion**
   - Navigate to the VM in Azure Portal
   - Click "Connect" → "Bastion"
   - Use the credentials above

2. **Change the default password**
   - This is critical for security!

3. **Install Power BI Desktop**
   - Open Edge browser in the VM
   - Download from: https://powerbi.microsoft.com/desktop/
   - Or use: `winget install --id Microsoft.PowerBI -e`

4. **Configure Storage Access**
   - The storage account is ready with private endpoint
   - Vendor users need to be granted "Storage Blob Data Reader" role

5. **Add Vendor User Access**
   ```bash
   # Replace with actual vendor email
   az ad user show --id vendor@email.com --query id -o tsv
   az role assignment create --role "Storage Blob Data Reader" --assignee-object-id <user-id> --scope /subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084
   ```

### 🔗 Useful Links

- **VM in Portal:** [View VM](https://portal.azure.com/#@24317511-81a4-42fb-bea5-f4b0735acba5/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Compute/virtualMachines/vm-pbi-vendor)
- **Storage Account:** [View Storage](https://portal.azure.com/#@24317511-81a4-42fb-bea5-f4b0735acba5/resource/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/vision/providers/Microsoft.Storage/storageAccounts/pbivend9084)

### 🛡️ Security Configuration

- ✅ Storage account has private endpoint only (no public access)
- ✅ VM has no public IP (Bastion access only)
- ✅ Storage requires authentication (no anonymous access)
- ✅ Minimum TLS 1.2 enforced
- ⚠️ NSG rules need to be configured to restrict outbound traffic

### 💰 Cost Optimization

To reduce costs, consider:
- Setting up auto-shutdown schedule for the VM
- Using Azure Dev/Test pricing if eligible
- Monitoring usage and scaling down if needed

---

**Note:** This deployment used Windows Server 2022 instead of Windows 11 due to subnet availability. Power BI Desktop runs perfectly on Windows Server 2022.