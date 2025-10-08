# Intelligent Hub - Archived Container App

**Archived Date:** October 8, 2025
**Status:** Retired
**Reason:** MCP infrastructure sunset

## What Was This?

The Intelligent Hub was an experimental MCP (Model Context Protocol) container application that provided AI-powered capabilities. It has been retired as part of infrastructure cleanup.

## Backup Contents

This archive contains:
- **intelligent-hub-backup.json** - Complete container app configuration
- **intelligent-hub-revisions.json** - All deployment revisions
- **intelligent-hub-environment.json** - Container environment settings
- **INTELLIGENT-HUB-RETIREMENT-BACKUP.md** - Detailed retirement documentation
- **RESTORE-INTELLIGENT-HUB.sh** - Automated restoration script

## Docker Image Location

The container images are preserved in Azure Container Registry:
- **Registry:** cogitativohubacr.azurecr.io
- **Repository:** intelligent-hub
- **Tags Available:**
  - security-fix-v2 (latest/recommended)
  - security-fix
  - auth-improved
  - db-fix
  - url-fixed

## Quick Restoration

To restore this container app:

```bash
cd Archive/intelligent-hub-backup
chmod +x RESTORE-INTELLIGENT-HUB.sh
./RESTORE-INTELLIGENT-HUB.sh
```

Or manually:
```bash
az containerapp create \
  --name cogitativo-intelligent-hub \
  --resource-group cogitativo-rg \
  --environment cogitativo-intelligent-hub-env \
  --image cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2 \
  --target-port 8080 \
  --ingress external
```

## Cost Savings from Retirement

- Container App: ~$15-30/month
- Container App Environment: ~$5-10/month
- **Total Savings:** ~$20-40/month

## Original Specifications

- **Platform:** Azure Container Apps
- **Runtime:** Docker container
- **Port:** 8080
- **Ingress:** External (public)
- **Resources:** 0.5 CPU, 1GB RAM
- **Scaling:** 1 replica (no autoscale)

## Notes

- Images remain in ACR for recovery if needed
- All configuration can be restored from JSON files
- No active dependencies existed at time of retirement