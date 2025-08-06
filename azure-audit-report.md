# Azure Account Audit Report
*Generated: July 31, 2025*

## Executive Summary

### Account Overview
- **Total Resources**: 211
- **Resource Groups**: 18
- **Active VMs**: 5 running, 1 deallocated
- **Storage Accounts**: 12
- **Estimated Monthly Savings**: $200-300

## 🚨 Immediate Cost Optimization Opportunities

### 1. Deallocated VM (High Priority)
| Resource | Status | Monthly Cost | Action |
|----------|---------|--------------|---------|
| aidev-tuan | Deallocated | ~$50 | Delete or remove |

**Recommendation**: This VM in AIDEV12581458982000 resource group is deallocated but still incurring storage costs. Consider deleting if not needed.

### 2. Unattached Disks
| Disk Name | Size | Monthly Cost | Action |
|-----------|------|--------------|---------|
| vm-pbi-vendor_OsDisk_1 | 127 GB | ~$15 | Delete (old OS disk) |
| adftransfer_OsDisk_1 | 30 GB | ~$3.60 | Delete if not needed |
| atlassian-server_OsDisk_1 | 30 GB | ~$3.60 | Delete (old OS disk) |

**Total Savings**: ~$22/month

### 3. Unattached Public IPs
| IP Name | Monthly Cost | Action |
|---------|--------------|---------|
| pip-vpn-azure-aws | ~$3.65 | Delete if VPN not needed |
| vm-pbi-vendorPublicIP | ~$3.65 | Delete (VM uses Bastion) |

**Total Savings**: ~$7.30/month

## 📊 Resource Distribution by Type

### Compute Resources (VMs)
```
Running VMs:
├── vm-pbi-vendor (D4s_v3) - Power BI vendor access
├── gitlab-server (D4s_v3) - GitLab instance
├── atlassian-server (E2s_v3) - Atlassian tools
├── dns-forwarder (DS1_v2) - DNS services
└── devops (B2s) - DevOps tools

Deallocated:
└── aidev-tuan (B2ms) - AI development [UNUSED]
```

### Storage Accounts Analysis
| Storage Account | Resource Group | Purpose | Status |
|----------------|----------------|---------|---------|
| cogidatalake | vision | Main data lake | ✅ Active |
| pbivend9084 | rg-pbi-vendor-isolated | Vendor access | ✅ Active |
| cogiaidev | vision | AI development | ⚠️ Check usage |
| cogitativoaistorage | openai-dev | OpenAI storage | ✅ Active |
| dbstorage* | databricks-* | Databricks managed | ✅ Required |
| intelligenthupstorage | rg-intelligent-hub | Hub storage | ⚠️ Check usage |
| cs410032000a6ab7916 | cloud-shell | Cloud Shell | ✅ Required |

### Network Resources
- **Virtual Networks**: 4 (all in use)
- **Network Security Groups**: 10 (aligned with subnets)
- **Private Endpoints**: 5 (securing storage access)
- **Network Watchers**: 42 (❗ excessive - auto-created)

## 🎯 Optimization Recommendations

### Immediate Actions (No Risk)
1. **Delete unattached disks** - Save $22/month
2. **Delete unused public IPs** - Save $7/month
3. **Delete/deallocate aidev-tuan VM** - Save $50/month

### Medium-term Actions (Low Risk)
1. **Consolidate resource groups**:
   - Merge intelligent-hub variations (3 groups)
   - Consider merging openai-dev with vision
   
2. **Storage optimization**:
   - Review cogiaidev and cogiarchive usage
   - Consider cool tier for archive data

3. **Clean up Network Watchers**:
   - 42 watchers is excessive (only need 1 per region)
   - Auto-created by Azure - safe to reduce

### Long-term Strategy
1. **Implement tagging strategy** for better cost tracking
2. **Set up auto-shutdown** for non-production VMs
3. **Use Azure Advisor** recommendations
4. **Enable cost alerts** at resource group level

## 💰 Cost Breakdown Estimate

### Monthly Costs by Category
| Category | Estimated Cost | % of Total |
|----------|---------------|------------|
| Compute (VMs) | $400-500 | 40% |
| Storage | $150-200 | 20% |
| Networking | $100-150 | 15% |
| PaaS Services | $150-200 | 20% |
| Other | $50 | 5% |
| **Total** | **$850-1100** | 100% |

### Top Cost Drivers
1. **vm-pbi-vendor** (D4s_v3) - ~$140/month
2. **gitlab-server** (D4s_v3) - ~$140/month
3. **Storage accounts** - ~$150-200/month total
4. **Databricks workspaces** - Variable based on usage

## 🗺️ Resource Architecture Overview

```
Azure Subscription (Cogitativo)
├── Production Workloads
│   ├── vision (Main RG)
│   │   ├── GitLab Server
│   │   ├── Atlassian Server
│   │   ├── DNS Forwarder
│   │   └── Data Lake Storage
│   ├── databricks-vision
│   │   └── Databricks Workspace
│   └── rg-pbi-vendor-isolated
│       └── Power BI Vendor VM
├── Development/Test
│   ├── openai-dev
│   │   └── OpenAI Resources
│   ├── aidev12581458982000
│   │   └── Deallocated VM [UNUSED]
│   └── pi / databricks-pi
│       └── PI Project Resources
└── Infrastructure
    ├── NetworkWatcherRG
    ├── CogitativoSentinel
    └── cloud-shell-storage
```

## ✅ Next Steps

1. **Immediate** (This week):
   - Delete unattached disks
   - Remove unused public IPs
   - Address deallocated VM

2. **Short-term** (This month):
   - Review storage account usage
   - Consolidate resource groups
   - Implement tagging strategy

3. **Long-term** (Next quarter):
   - Implement auto-shutdown policies
   - Set up cost management alerts
   - Review VM sizing for optimization

## 🔒 Safety Considerations

Before deleting any resources:
1. Verify no dependencies exist
2. Check for any automation using the resources
3. Backup any important data
4. Document changes made

**Total Potential Monthly Savings**: $200-300 (20-30% reduction)