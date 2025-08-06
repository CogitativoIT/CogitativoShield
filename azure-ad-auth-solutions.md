# Azure AD Authentication Solutions for Windows Server 2022

## Current Situation
- VM: Windows Server 2022 (not Windows 11 as originally intended)
- Challenge: Cannot join directly to Azure AD (only Windows 10/11 support this)
- Goal: Enable guest users to use their Azure AD credentials instead of managing separate VM credentials

## Solution Options

### 1. **Azure AD Domain Services (Recommended)**
Deploy Azure AD DS to enable domain join for Windows Server VMs.

**Pros:**
- Full domain join capability for Windows Server
- Users can login with Azure AD credentials
- Supports group policies and traditional AD features
- Works seamlessly with existing Azure AD users/groups

**Cons:**
- Additional monthly cost (~$110/month minimum)
- Requires setup time (45-60 minutes)
- Needs dedicated subnet in VNet

**Implementation:**
```bash
# Create Azure AD DS instance
az ad ds create \
  --name "yourcompany.onmicrosoft.com" \
  --resource-group "rg-pbi-vendor-isolated" \
  --replica-sets location="East US" subnet="/subscriptions/.../subnets/aadds-subnet"
```

### 2. **Azure Virtual Desktop (AVD)**
Replace standalone VM with AVD session host.

**Pros:**
- Native Azure AD join support
- Better user experience with web client
- Centralized management
- Auto-scaling capabilities

**Cons:**
- More complex setup
- Requires AVD infrastructure
- May be overkill for single user

**Quick Setup:**
```powershell
# Use Azure Portal > Create Virtual Desktop host pool
# Select "Personal" pool type for dedicated VMs
# Enable Azure AD join during creation
```

### 3. **Local User with Password Sync**
Create matching local accounts with same passwords as Azure AD.

**Pros:**
- No additional infrastructure
- Quick to implement
- No extra costs

**Cons:**
- Manual password management
- Not true SSO
- Security concerns with password sync

**PowerShell Script:**
```powershell
# Run on VM to create local user matching Azure AD user
$username = "vendor@company.com"
$password = ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force
New-LocalUser -Name $username -Password $password -FullName "Vendor User"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member $username
```

### 4. **Azure AD Application Proxy**
Publish RDP through App Proxy for web-based access.

**Pros:**
- Web-based RDP access
- Azure AD authentication at proxy level
- No VPN required

**Cons:**
- Requires Azure AD Premium
- Still need local VM credentials
- Additional latency

### 5. **Convert to Windows 11 VM**
Recreate VM with Windows 11 for native Azure AD join.

**Pros:**
- Native Azure AD join
- True SSO experience
- Modern OS features
- Matches original requirements

**Cons:**
- Requires VM recreation
- Data migration needed
- Licensing considerations

**Steps:**
```yaml
# Modify provision script to use Windows 11 image
imageReference:
  publisher: MicrosoftWindowsDesktop
  offer: Windows-11
  sku: win11-22h2-pro
  version: latest
```

## Recommended Approach

Given your requirements for simplicity and avoiding credential management:

1. **Short-term (Immediate):** Create local user account with strong password, share securely with vendor
2. **Medium-term (This week):** Deploy Windows 11 VM to replace Server 2022
3. **Long-term (If scaling):** Consider Azure AD DS for multiple vendors/VMs

## Windows 11 VM Recreation Script

Save as `recreate-as-windows11.ps1`:

```powershell
# Backup important data first
Write-Host "WARNING: This will delete and recreate the VM!" -ForegroundColor Red
$confirm = Read-Host "Have you backed up all data? (yes/no)"
if ($confirm -ne "yes") { exit }

# Variables
$rgName = "rg-pbi-vendor-isolated"
$vmName = "vm-pbi-vendor"
$location = "eastus"

# Stop and deallocate existing VM
Write-Host "Stopping existing VM..." -ForegroundColor Yellow
az vm stop --resource-group $rgName --name $vmName
az vm deallocate --resource-group $rgName --name $vmName

# Delete VM (keep disks and NICs)
Write-Host "Deleting VM (keeping disks)..." -ForegroundColor Yellow
az vm delete --resource-group $rgName --name $vmName --yes

# Create new Windows 11 VM with same configuration
Write-Host "Creating Windows 11 VM..." -ForegroundColor Yellow
az vm create `
  --resource-group $rgName `
  --name $vmName `
  --image MicrosoftWindowsDesktop:Windows-11:win11-22h2-pro:latest `
  --size Standard_D4s_v3 `
  --admin-username "pbiadmin" `
  --admin-password "P@ssw0rd123!ChangeMe" `
  --nics vm-pbi-vendor-nic `
  --os-disk-name "vm-pbi-vendor-osdisk" `
  --os-disk-size-gb 128 `
  --license-type Windows_Client

# Enable Azure AD login
Write-Host "Enabling Azure AD authentication..." -ForegroundColor Yellow
az vm extension set `
  --publisher Microsoft.Azure.ActiveDirectory `
  --name AADLoginForWindows `
  --resource-group $rgName `
  --vm-name $vmName

# Add visionbidevvm group for VM login
Write-Host "Granting VM access to security group..." -ForegroundColor Yellow
az role assignment create `
  --assignee "b6dc070d-f050-41c0-af1a-c9bdf043ecef" `
  --role "Virtual Machine User Login" `
  --scope "/subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName"

Write-Host "" 
Write-Host "Windows 11 VM created with Azure AD join!" -ForegroundColor Green
Write-Host "Users in visionbidevvm group can now login with their Azure AD credentials" -ForegroundColor Green
```

## Next Steps

1. Decide which approach fits your timeline and requirements
2. If choosing Windows 11 recreation, backup any data on current VM first
3. Update documentation to reflect the authentication method chosen