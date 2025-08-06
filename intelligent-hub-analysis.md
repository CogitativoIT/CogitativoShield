# Intelligent Hub Resource Groups Analysis
*Generated: July 31, 2025*

## ⚠️ IMPORTANT: This is a LIVE production web app - NO ACTIONS TAKEN

## Current State

You have 3 resource groups related to Intelligent Hub:

### 1. rg-intelligent-hub (ACTIVE - Has Resources)
**Resources:**
- workspace-rgintelligenthubeu9H (Log Analytics)
- my-intelligent-hub-env (Container Apps Environment)
- myintelligenthubacr (Container Registry)
- intelligenthupstorage (Storage Account)
- intelligent-hub-logs (Log Analytics)
- cae88a8e8234acr (Container Registry)

**Analysis:** This appears to be the main/active resource group with the Container Apps Environment.

### 2. intelligent-hub-rg (ACTIVE - Has Resources)
**Resources:**
- intelligenthubreg (Container Registry)
- workspace-intelligenthubrglLuz (Log Analytics)
- workspace-intelligenthubrgWoqW (Log Analytics)
- cogitativo-hub-env (Container Apps Environment)

**Analysis:** This has another Container Apps Environment and duplicate Log Analytics workspaces.

### 3. rg-Intelligent-Hub-MCP (EMPTY)
**Resources:** None
**Analysis:** This resource group is completely empty and can be safely deleted.

## 🔍 Key Findings

1. **Duplicate Resources:**
   - 3 Container Registries (only need 1)
   - 4 Log Analytics Workspaces (only need 1)
   - 2 Container Apps Environments (need to identify which is active)

2. **Naming Inconsistency:**
   - Different naming patterns across groups
   - Mix of camelCase and kebab-case

3. **Cost Impact:**
   - Log Analytics Workspaces: ~$2.50/GB/month each
   - Container Registries: ~$5-20/month each
   - Storage: Variable based on usage

## 🎯 Consolidation Plan (DO NOT EXECUTE WITHOUT APPROVAL)

### Phase 1: Identify Active Resources
1. Determine which Container Apps Environment hosts the live app
2. Check which Container Registry contains active images
3. Verify which Log Analytics workspace is receiving logs

### Phase 2: Safe Cleanup (After Verification)
1. **Immediate:** Delete empty resource group `rg-Intelligent-Hub-MCP`
2. **After Testing:** Remove duplicate Log Analytics workspaces
3. **After Migration:** Consolidate Container Registries

### Phase 3: Final State
Consolidate to ONE resource group with:
- 1 Container Apps Environment
- 1 Container Registry
- 1 Log Analytics Workspace
- 1 Storage Account

## 💰 Potential Savings
- Removing duplicate Log Analytics: ~$10-20/month
- Removing duplicate Container Registries: ~$10-30/month
- **Total: ~$20-50/month**

## ⚠️ CRITICAL STEPS BEFORE ANY ACTION

1. **Identify the live Container App:**
   ```bash
   az containerapp list --query "[].{Name:name, Env:managedEnvironmentId, State:state}" -o table
   ```

2. **Check active Container Registry:**
   ```bash
   az acr repository list --name myintelligenthubacr
   az acr repository list --name intelligenthubreg
   ```

3. **Verify Log Analytics usage:**
   ```bash
   az monitor log-analytics workspace get-shared-keys --workspace-name intelligent-hub-logs -g rg-intelligent-hub
   ```

## 📋 Recommended Action Plan

### Safe to do NOW:
1. Delete empty resource group: `rg-Intelligent-Hub-MCP`

### Requires your approval:
1. Identify which Container Apps Environment is live
2. Plan migration to consolidate resources
3. Test thoroughly before removing anything

### DO NOT TOUCH until verified:
- Any Container Apps Environment
- Container Registries with images
- Active Log Analytics workspaces
- Storage accounts

Would you like me to:
1. Delete the empty resource group `rg-Intelligent-Hub-MCP`?
2. Run commands to identify which resources are actively being used?