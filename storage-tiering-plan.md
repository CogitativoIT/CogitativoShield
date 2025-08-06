# Azure Storage Tiering Plan

## Why Storage Tiering?

Storage tiering allows you to optimize costs by moving infrequently accessed data to cheaper tiers while keeping hot data readily available.

## Azure Storage Tiers Overview

| Tier | Access Pattern | Storage Cost | Access Cost | Use Case |
|------|---------------|--------------|-------------|----------|
| **Hot** | Frequent access | $0.0184/GB | Low | Active data |
| **Cool** | Infrequent (30+ days) | $0.01/GB | Higher | Backups, old logs |
| **Archive** | Rare (180+ days) | $0.00099/GB | Highest | Compliance data |

## Your Storage Accounts Analysis

### Prime Candidates for Tiering

1. **cogiarchive** (vision RG)
   - **Current**: Hot tier at $0.0184/GB
   - **Name suggests**: Archive purposes
   - **Recommendation**: Move to Cool or Archive
   - **Monthly Savings**: ~45-95% of current storage costs

2. **cogiaidev** (vision RG)
   - **Current**: Hot tier
   - **Purpose**: AI development (likely has old models/data)
   - **Recommendation**: Implement lifecycle policies
   - **Monthly Savings**: ~30-50% on old data

3. **visionml8033658882** (vision RG)
   - **Current**: Hot tier
   - **Purpose**: ML projects (likely has old training data)
   - **Recommendation**: Cool tier for data >30 days old
   - **Monthly Savings**: ~40% on old data

### Storage Accounts to Keep Hot

- **cogidatalake** - Premium/active data lake
- **pbivend9084** - Active vendor access
- **cogitativoaistorage** - Active AI operations
- **dbstorage*** - Databricks managed (don't touch)

## Cost Comparison Example

For 1TB of data:
- **Hot tier**: $18.40/month
- **Cool tier**: $10/month (45% savings)
- **Archive tier**: $0.99/month (95% savings)

## Implementation Options

### Option 1: Manual Tier Change (Immediate)
- **Commitment**: None
- **Flexibility**: Change anytime
- **Best for**: cogiarchive account
```bash
az storage account update --name cogiarchive --access-tier Cool
```

### Option 2: Lifecycle Management Policies (Recommended)
- **Commitment**: None
- **Flexibility**: Automatic based on last access
- **Best for**: Development/ML storage

Example policy:
- Move to Cool after 30 days
- Move to Archive after 90 days
- Delete after 365 days (optional)

### Option 3: Reserved Capacity (1-3 year commitment)
- **Commitment**: 1 or 3 years
- **Savings**: Additional 17-38% off
- **Best for**: Predictable storage needs

## Risks and Considerations

### Access Costs
- **Cool tier**: $0.01 per 10,000 reads
- **Archive tier**: $5 per GB to rehydrate + hours wait time

### Early Deletion Fees
- **Cool**: 30-day minimum
- **Archive**: 180-day minimum

## Recommended Action Plan

### Phase 1: Quick Wins (No Risk)
1. Change **cogiarchive** to Cool tier
   - Estimated savings: $8-15/month
   - Zero commitment
   - Instant change

### Phase 2: Lifecycle Policies (Low Risk)
1. Implement policies on development storage:
   - cogiaidev
   - visionml8033658882
   - Estimated savings: $20-40/month

### Phase 3: Review After 30 Days
1. Check access patterns
2. Consider Archive tier for truly cold data
3. Evaluate reserved capacity if usage is stable

## Total Estimated Savings

| Action | Monthly Savings | Annual Savings | Risk |
|--------|----------------|----------------|------|
| cogiarchive to Cool | $8-15 | $96-180 | None |
| Lifecycle policies | $20-40 | $240-480 | Low |
| Archive old data | $10-20 | $120-240 | Medium |
| **Total** | **$38-75** | **$456-900** | Low |

## No Commitment Required

- All tiering changes are reversible
- No upfront costs
- Pay only for what you use
- Can change tiers anytime (except early deletion fees)