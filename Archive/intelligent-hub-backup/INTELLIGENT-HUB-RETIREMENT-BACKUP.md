# Intelligent Hub Container App - Retirement Backup
**Date:** October 8, 2025
**Performed by:** andre.darby@cogitativo.com

## Overview
This document contains the complete backup and retirement information for the cogitativo-intelligent-hub container app.

## Container App Details

### Basic Information
- **Name:** cogitativo-intelligent-hub
- **Resource Group:** cogitativo-rg
- **Location:** East US
- **FQDN:** cogitativo-intelligent-hub.lemoncoast-18e54811.eastus.azurecontainerapps.io
- **Latest Revision:** cogitativo-intelligent-hub--0000014

### Container Image
- **Registry:** cogitativohubacr.azurecr.io
- **Repository:** intelligent-hub
- **Active Tag:** security-fix-v2
- **Full Image:** cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2

### All Image Tags (Historical)
1. auth-improved
2. db-fix
3. security-fix
4. security-fix-v2 (current)
5. url-fixed

## Backed Up Files

### Configuration Files
1. **intelligent-hub-backup.json** - Complete container app configuration
2. **intelligent-hub-revisions.json** - All revision history
3. **intelligent-hub-environment.json** - Container app environment settings

### Container Registry
- **ACR Name:** cogitativohubacr
- **Login Server:** cogitativohubacr.azurecr.io
- **Images Preserved:** All 5 tags remain in ACR for recovery if needed

## Associated Resources

### Container App Environment
- **Name:** cogitativo-intelligent-hub-env
- **ID:** /subscriptions/fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed/resourceGroups/cogitativo-rg/providers/Microsoft.App/managedEnvironments/cogitativo-intelligent-hub-env

### Network Configuration
- **Ingress:** External (port 8080)
- **Traffic:** 100% to latest revision
- **Transport:** Auto (HTTP/HTTPS)

### Outbound IP Addresses
The container app used these outbound IPs (documented in backup.json):
- Primary: 20.127.248.50
- Secondary: 20.241.171.30
- (Full list in backup.json)

## Secrets and Credentials
- **ACR Password Secret:** cogitativohubacrazurecrio-cogitativohubacr (stored in container app)
- **ACR Username:** cogitativohubacr

## Recovery Instructions

### To Restore This Container App

1. **Recreate Container App Environment:**
```bash
az containerapp env create \
  --name cogitativo-intelligent-hub-env \
  --resource-group cogitativo-rg \
  --location "East US"
```

2. **Recreate Container App:**
```bash
az containerapp create \
  --name cogitativo-intelligent-hub \
  --resource-group cogitativo-rg \
  --environment cogitativo-intelligent-hub-env \
  --image cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2 \
  --target-port 8080 \
  --ingress external \
  --registry-server cogitativohubacr.azurecr.io \
  --registry-username cogitativohubacr \
  --registry-password <password-from-secret>
```

3. **Pull Docker Image (if Docker available):**
```bash
# Login to ACR
az acr login --name cogitativohubacr --expose-token

# Pull image
docker pull cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2

# Export to tar
docker save cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2 -o intelligent-hub-backup.tar
```

## Why This Was Retired
The intelligent-hub container app was part of an MCP (Model Context Protocol) experiment that is being sunset. The functionality has been replaced or is no longer needed.

## Deletion Checklist

Before deleting resources, ensure:
- [ ] Configuration files backed up to GitHub
- [ ] Docker images remain in ACR for 90 days
- [ ] Documentation is complete
- [ ] No active dependencies on this container app
- [ ] All secrets documented

## Resources to Delete

1. **Container App:**
```bash
az containerapp delete \
  --name cogitativo-intelligent-hub \
  --resource-group cogitativo-rg \
  --yes
```

2. **Container App Environment:**
```bash
az containerapp env delete \
  --name cogitativo-intelligent-hub-env \
  --resource-group cogitativo-rg \
  --yes
```

3. **Container Registry (Optional - contains other images):**
```bash
# Only delete specific repository
az acr repository delete \
  --name cogitativohubacr \
  --repository intelligent-hub \
  --yes
```

4. **ACR Itself (Only if no other images):**
```bash
az acr delete \
  --name cogitativohubacr \
  --resource-group cogitativo-rg \
  --yes
```

## Cost Savings
- Container App: ~$15-30/month
- Container App Environment: ~$5-10/month
- ACR: ~$5/month (if no other images)
- **Total Estimated Savings:** ~$25-45/month

## Notes
- Container images will remain in ACR for recovery purposes
- All configuration can be restored from backup JSON files
- This retirement was performed as part of MCP infrastructure cleanup