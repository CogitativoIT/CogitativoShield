# Azure Account Final Audit Report
*Generated: July 31, 2025*

## Executive Summary

### Account Status After Cleanup
- **Initial Resources**: 211
- **Resources Deleted**: ~60 (Network Watchers, unused VMs, disks, IPs, resource groups)
- **Current Active Resources**: ~150
- **Monthly Savings Achieved**: $129-159 (12-15% reduction)

## 🏢 Resource Group Analysis

### Production Workloads
1. **vision** (99 resources) - Main production hub
   - 5 VMs (GitLab, Atlassian, DNS, DevOps)
   - Multiple storage accounts
   - Databricks workspace
   - VNet with Bastion
   - **Monthly Cost**: $400-500

2. **rg-pbi-vendor-isolated** - Vendor access
   - Power BI VM (D4s_v3)
   - Private storage
   - **Monthly Cost**: $150-180

3. **cogitativo-rg** - Container Apps
   - Intelligent Hub app (100+ revisions)
   - Container registries
   - **Monthly Cost**: $100-150

### Development/Test
1. **openai-dev** - AI Development
   - OpenAI resources (S0)
   - AI Services
   - 2 storage accounts
   - **Monthly Cost**: $150-200 (usage-based)

2. **pi** & **databricks-pi** - PI Project
   - Databricks workspace
   - Storage account
   - **Monthly Cost**: $100-150

3. **app-rg** (eastus2) - AI Services
   - 2 AI Services accounts
   - **Monthly Cost**: $50-100

### Infrastructure/Security
1. **CogitativoSentinel** - Security monitoring
   - Log Analytics workspace
   - **Monthly Cost**: $20-30

2. **tenable-integration** - Vulnerability scanning
   - TenableIO integration
   - Log Analytics
   - **Monthly Cost**: $20-30

3. **dashboards** - Azure dashboards
   - Portal dashboards
   - Log Analytics
   - **Monthly Cost**: $10-20

4. **Sophos** - Security (appears empty)
   - **Monthly Cost**: $0

5. **NetworkWatcherRG** - Network monitoring
   - 3 Network Watchers (reduced from 42)
   - **Monthly Cost**: $0

## 💾 Storage Account Analysis

### Active Storage (11 accounts)
| Storage Account | Type | Purpose | Est. Monthly Cost |
|----------------|------|---------|-------------------|
| cogidatalake | Premium Block Blob | Main data lake | $50-80 |
| pbivend9084 | Standard | Vendor access | $10-20 |
| cogiaidev | Standard | AI development | $10-20 |
| cogiarchive | Standard | Archive data | $10-20 |
| cogipidatalake | Standard | PI project | $10-20 |
| cogitativoaistorage | Standard | OpenAI data | $20-30 |
| dbstorage* (2) | Standard GRS | Databricks managed | $20-30 |
| visionml8033658882 | Standard | ML projects | $10-20 |
| aaidev16811 | Standard | AI dev | $5-10 |
| cs410032000a6ab7916 | Standard | Cloud Shell | $1-2 |

**Total Storage**: $147-252/month

## 🤖 AI & Cognitive Services

1. **OpenAI Service** (cogitativo-ai) - S0 tier
   - **Cost**: Usage-based ($100-200/month estimated)

2. **AI Services** (3 accounts)
   - andre-mapn5a1h-eastus2
   - cogitai-foundry
   - cogitativo-intelligent-hub
   - **Cost**: $50-100/month total

3. **Text Analytics** (vision-language) - F0 (free tier)
   - **Cost**: $0

## 📊 Databricks Workspaces

1. **cogitativo-vision** (vision RG)
   - Production workspace
   - **Cost**: $50-100/month + compute

2. **cogitativo-pi** (pi RG)
   - PI project workspace
   - **Cost**: $50-100/month + compute

## 🎯 Optimization Opportunities

### Immediate Actions
1. **Consolidate Log Analytics Workspaces**
   - Found 5+ workspaces across different RGs
   - Keep 1-2 max
   - **Savings**: $20-40/month

2. **Review Storage Redundancy**
   - Databricks storage using GRS (geo-redundant)
   - Consider LRS for non-critical data
   - **Savings**: $10-20/month

3. **Empty Resource Groups**
   - Sophos RG appears empty
   - aidev12581458982000 (check if empty after VM deletion)
   - **Savings**: $0 (cleanup only)

### Medium-term Actions
1. **Storage Tiering**
   - Move cogiarchive to Cool/Archive tier
   - Review old data in other storage accounts
   - **Savings**: $10-30/month

2. **VM Right-sizing**
   - Review if D4s_v3 VMs can be downsized
   - Consider B-series for low-usage VMs
   - **Savings**: $50-100/month

3. **Databricks Optimization**
   - Review cluster usage patterns
   - Implement auto-termination policies
   - **Savings**: $50-100/month

## 💰 Updated Monthly Cost Projection

### By Category
| Category | Current Monthly Cost |
|----------|---------------------|
| Compute (VMs) | $350-450 |
| Storage | $147-252 |
| AI Services | $150-300 |
| Databricks | $100-200 |
| Container Apps | $50-100 |
| Networking | $80-120 |
| Security/Monitoring | $40-60 |
| Other PaaS | $30-50 |
| **TOTAL** | **$947-1,532** |

### Cost Breakdown
- **Already Saved**: $129-159/month
- **Additional Savings Available**: $150-250/month
- **Optimized Total**: $700-1,100/month

### Final Projection
**Current Monthly Spend**: $950-1,500
**After Full Optimization**: $700-1,100
**Total Potential Savings**: $250-400/month (25-30% reduction)

## ✅ Next Steps Priority

1. **This Week**
   - Consolidate Log Analytics workspaces
   - Delete empty Sophos RG
   - Review aidev12581458982000 RG

2. **This Month**
   - Implement storage tiering
   - Review VM sizes
   - Set up cost alerts

3. **Next Quarter**
   - Databricks optimization
   - Implement tagging strategy
   - Monthly cost reviews