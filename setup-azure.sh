#!/bin/bash

# EchoVault Azure Quick Setup Script
# This script automates Azure resource creation and GitHub secrets configuration

set -e

echo "╔════════════════════════════════════════╗"
echo "║  EchoVault Azure Deployment Setup      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
RESOURCE_GROUP="echovault-rg"
REGISTRY_NAME="echovaultregistry"
LOCATION="eastus"
APP_NAME="echovault-app"
APP_PLAN="echovault-plan"
GITHUB_REPO="${1:-iamkonnect/EchoVault}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Registry Name: $REGISTRY_NAME"
echo "  Location: $LOCATION"
echo "  GitHub Repo: $GITHUB_REPO"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required. Install from https://docs.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "❌ Git is required."; exit 1; }

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Login to Azure
echo -e "${BLUE}Logging in to Azure...${NC}"
az login

# Get subscription info
echo -e "${BLUE}Getting subscription info...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)${NC}"
echo ""

# Create resource group
echo -e "${BLUE}Creating resource group...${NC}"
if az group exists --name $RESOURCE_GROUP --query value -o tsv | grep -q "true"; then
  echo -e "${YELLOW}ℹ Resource group already exists${NC}"
else
  az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
  echo -e "${GREEN}✓ Resource group created${NC}"
fi
echo ""

# Create container registry
echo -e "${BLUE}Creating Azure Container Registry...${NC}"
if az acr show --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
  echo -e "${YELLOW}ℹ Registry already exists${NC}"
else
  az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $REGISTRY_NAME \
    --sku Basic \
    --admin-enabled true
  echo -e "${GREEN}✓ Container Registry created${NC}"
fi
echo ""

# Get registry credentials
echo -e "${BLUE}Retrieving registry credentials...${NC}"
REGISTRY_URL=$(az acr show --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP --query loginServer -o tsv)
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP --query username -o tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --resource-group $RESOURCE_GROUP --query 'passwords[0].value' -o tsv)

echo -e "${GREEN}✓ Registry Credentials:${NC}"
echo "  URL: $REGISTRY_URL"
echo "  Username: $REGISTRY_USERNAME"
echo "  Password: (hidden)"
echo ""

# Create App Service Plan
echo -e "${BLUE}Creating App Service Plan...${NC}"
if az appservice plan show --name $APP_PLAN --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
  echo -e "${YELLOW}ℹ App Service Plan already exists${NC}"
else
  az appservice plan create \
    --name $APP_PLAN \
    --resource-group $RESOURCE_GROUP \
    --sku B1 \
    --is-linux
  echo -e "${GREEN}✓ App Service Plan created${NC}"
fi
echo ""

# Create Web App
echo -e "${BLUE}Creating Web App...${NC}"
if az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
  echo -e "${YELLOW}ℹ Web App already exists${NC}"
else
  az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_PLAN \
    --name $APP_NAME \
    --deployment-container-image-name-user-provided true
  echo -e "${GREEN}✓ Web App created${NC}"
fi
echo ""

# Configure Web App with container
echo -e "${BLUE}Configuring Web App container settings...${NC}"
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name "${REGISTRY_URL}/${APP_NAME}:latest" \
  --docker-registry-server-url "https://${REGISTRY_URL}" \
  --docker-registry-server-user "$REGISTRY_USERNAME" \
  --docker-registry-server-password "$REGISTRY_PASSWORD"
echo -e "${GREEN}✓ Container configured${NC}"
echo ""

# Enable continuous deployment
echo -e "${BLUE}Enabling continuous deployment...${NC}"
az webapp deployment container config \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --enable-cd true
echo -e "${GREEN}✓ Continuous deployment enabled${NC}"
echo ""

# Display summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "Add these GitHub Secrets (https://github.com/$GITHUB_REPO/settings/secrets/actions):"
echo ""
echo "  AZURE_REGISTRY_USERNAME: $REGISTRY_USERNAME"
echo "  AZURE_REGISTRY_PASSWORD: $REGISTRY_PASSWORD"
echo "  AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Next steps:"
echo "  1. Add the secrets above to your GitHub repository"
echo "  2. Push changes to main branch to trigger deployment"
echo "  3. Access app at: https://${APP_NAME}.azurewebsites.net"
echo ""
echo "Useful commands:"
echo ""
echo "  View logs:"
echo "    az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo ""
echo "  Restart app:"
echo "    az webapp restart --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo ""
echo "  Get app URL:"
echo "    az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query defaultHostName -o tsv"
echo ""
