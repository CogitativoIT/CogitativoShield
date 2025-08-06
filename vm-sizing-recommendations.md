# VM Sizing Recommendations

## Current VM Analysis

| VM Name | Current Size | vCPUs | RAM | Monthly Cost | Usage Profile |
|---------|--------------|-------|-----|--------------|---------------|
| vm-pbi-vendor | D4s_v3 | 4 | 16GB | ~$140 | Power BI development |
| gitlab-server | D4s_v3 | 4 | 16GB | ~$140 | Git repository |
| atlassian-server | E2s_v3 | 2 | 16GB | ~$85 | Jira/Confluence |
| devops | B2s | 2 | 4GB | ~$30 | CI/CD tools |
| dns-forwarder | DS1_v2 | 1 | 3.5GB | ~$40 | DNS only |

**Total Current Cost**: ~$435/month

## Sizing Recommendations

### 1. ✅ vm-pbi-vendor (D4s_v3 → D2s_v3)
- **Current**: 4 vCPUs, 16GB RAM - $140/month
- **Recommended**: D2s_v3 (2 vCPUs, 8GB RAM) - $70/month
- **Reasoning**: Power BI Desktop rarely uses >8GB RAM for single user
- **Savings**: $70/month (50%)
- **Risk**: Low - can resize back if needed

### 2. ❓ gitlab-server (D4s_v3 → D2s_v3)
- **Current**: 4 vCPUs, 16GB RAM - $140/month
- **Recommended**: D2s_v3 (2 vCPUs, 8GB RAM) - $70/month
- **Reasoning**: GitLab can run on 8GB for small teams
- **Savings**: $70/month (50%)
- **Risk**: Medium - check current usage first

### 3. ✅ dns-forwarder (DS1_v2 → B1s)
- **Current**: 1 vCPU, 3.5GB RAM - $40/month
- **Recommended**: B1s (1 vCPU, 1GB RAM) - $8/month
- **Reasoning**: DNS forwarding needs minimal resources
- **Savings**: $32/month (80%)
- **Risk**: Low - DNS is lightweight

### 4. ✅ atlassian-server (Keep as E2s_v3)
- **Current**: E2s_v3 - Memory optimized
- **Reasoning**: Jira/Confluence benefit from RAM
- **Action**: No change recommended

### 5. ✅ devops (Keep as B2s)
- **Current**: B2s - Burstable
- **Reasoning**: Good for variable CI/CD workloads
- **Action**: No change recommended

## Implementation Plan

### Phase 1: Low Risk Changes (Immediate)
```bash
# Resize DNS forwarder
az vm resize --name dns-forwarder --resource-group VISION --size Standard_B1s

# Resize Power BI VM (coordinate with user)
az vm resize --name vm-pbi-vendor --resource-group RG-PBI-VENDOR-ISOLATED --size Standard_D2s_v3
```
**Savings**: $102/month

### Phase 2: Medium Risk (After Analysis)
1. Monitor GitLab server CPU/memory for 1 week
2. If usage <50%, resize to D2s_v3
3. **Additional Savings**: $70/month

## Cost Optimization Features

### Auto-Shutdown (Recommended for Dev VMs)
Set auto-shutdown for vm-pbi-vendor:
- Shutdown: 7 PM daily
- Weekend shutdown
- **Additional Savings**: ~$40-50/month

### Reserved Instances (1-year commitment)
If VMs are permanent:
- 1-year reservation: 20-30% discount
- 3-year reservation: 40-50% discount
- **Additional Savings**: $87-130/month

## Summary

| Action | Monthly Savings | Risk | Downtime |
|--------|----------------|------|----------|
| DNS to B1s | $32 | Low | 5 min |
| PBI to D2s_v3 | $70 | Low | 5 min |
| GitLab to D2s_v3 | $70 | Medium | 5 min |
| Auto-shutdown | $40-50 | None | None |
| **Total Immediate** | **$102** | Low | 10 min |
| **Total Potential** | **$212-222** | Mixed | 15 min |

## Next Steps

1. **Immediate**: Resize dns-forwarder to B1s (saves $32/month)
2. **Coordinate**: Schedule vm-pbi-vendor resize with user
3. **Monitor**: Check GitLab usage before resizing
4. **Consider**: Auto-shutdown for development VMs