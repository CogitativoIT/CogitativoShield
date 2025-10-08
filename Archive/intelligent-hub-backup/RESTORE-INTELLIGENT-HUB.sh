#!/bin/bash
# Intelligent Hub Container App Restoration Script
# Date: October 8, 2025

set -e

echo "=================================================="
echo " INTELLIGENT HUB RESTORATION SCRIPT"
echo "=================================================="
echo ""

# Variables
SUBSCRIPTION_ID="fb344b4b-f3a4-45a5-81d6-c1f911fcb4ed"
RESOURCE_GROUP="cogitativo-rg"
LOCATION="eastus"
APP_NAME="cogitativo-intelligent-hub"
ENV_NAME="cogitativo-intelligent-hub-env"
ACR_NAME="cogitativohubacr"
IMAGE="cogitativohubacr.azurecr.io/intelligent-hub:security-fix-v2"

echo "Configuration:"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Container App: $APP_NAME"
echo ""

# Set subscription
echo "Setting Azure subscription..."
az account set --subscription $SUBSCRIPTION_ID

# Check if resource group exists
echo "Checking resource group..."
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "Creating resource group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group exists"
fi

# Create Container App Environment
echo ""
echo "Creating Container App Environment..."
if ! az containerapp env show --name $ENV_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    az containerapp env create \
        --name $ENV_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION
    echo "✓ Environment created"
else
    echo "Environment already exists"
fi

# Get ACR credentials
echo ""
echo "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# Create Container App
echo ""
echo "Creating Container App..."
if ! az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
    az containerapp create \
        --name $APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --environment $ENV_NAME \
        --image $IMAGE \
        --target-port 8080 \
        --ingress external \
        --registry-server cogitativohubacr.azurecr.io \
        --registry-username $ACR_USERNAME \
        --registry-password $ACR_PASSWORD \
        --cpu 0.5 \
        --memory 1.0Gi \
        --min-replicas 1 \
        --max-replicas 1
    echo "✓ Container App created"
else
    echo "Container App already exists"
fi

# Get FQDN
echo ""
FQDN=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv)
echo "=================================================="
echo "✓ RESTORATION COMPLETE"
echo "=================================================="
echo ""
echo "Container App URL: https://$FQDN"
echo ""
echo "To verify:"
echo "  curl https://$FQDN"
echo ""