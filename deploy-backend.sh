#!/bin/bash

# EchoVault Backend Azure Deployment Script
# Creates App Service Plan and deploys Node.js backend

set -e

echo "╔════════════════════════════════════════╗"
echo "║  EchoVault Backend Azure Setup         ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="echovault-rg"
PLAN_NAME="echovault-plan"
BACKEND_NAME="echovault-backend"
LOCATION="eastus"
SKU="B1" # Free/Shared tier for testing, upgrade to B1/P1 for production

echo -e "${BLUE}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  App Service Plan: $PLAN_NAME"
echo "  Web App Name: $BACKEND_NAME"
echo "  Location: $LOCATION"
echo "  SKU: $SKU"
echo ""

# Step 1: Check if resource group exists
echo -e "${BLUE}[1/4] Checking resource group...${NC}"
if az group exists --name $RESOURCE_GROUP --query value -o tsv | grep -q "true"; then
  echo -e "${GREEN}✓ Resource group exists${NC}"
else
  echo -e "${YELLOW}Creating resource group...${NC}"
  az group create --name $RESOURCE_GROUP --location $LOCATION
  echo -e "${GREEN}✓ Resource group created${NC}"
fi
echo ""

# Step 2: Create App Service Plan
echo -e "${BLUE}[2/4] Creating App Service Plan...${NC}"
if az appservice plan show --name $PLAN_NAME --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
  echo -e "${GREEN}✓ App Service Plan already exists${NC}"
else
  az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku $SKU \
    --is-linux
  echo -e "${GREEN}✓ App Service Plan created${NC}"
fi
echo ""

# Step 3: Create Web App
echo -e "${BLUE}[3/4] Creating Web App for Node.js backend...${NC}"
if az webapp show --name $BACKEND_NAME --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Web App already exists${NC}"
else
  az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --name $BACKEND_NAME \
    --runtime "NODE|18-lts"
  echo -e "${GREEN}✓ Web App created${NC}"
fi
echo ""

# Step 4: Configure web app settings
echo -e "${BLUE}[4/4] Configuring web app...${NC}"

# Set Node.js environment
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --settings \
    WEBSITES_PORT=3000 \
    NODE_ENV=production \
    NPM_CONFIG_PRODUCTION=false

# Enable logging
az webapp log config \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --docker-container-logging filesystem

echo -e "${GREEN}✓ Web app configured${NC}"
echo ""

# Display summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Backend Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

# Get the app URL
APP_URL=$(az webapp show --resource-group $RESOURCE_GROUP --name $BACKEND_NAME --query defaultHostName -o tsv)

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Prepare your backend code:"
echo "   - Ensure package.json is in root directory"
echo "   - Server must listen on port 3000 (or WEBSITES_PORT env var)"
echo "   - Add CORS configuration"
echo ""
echo "2. Deploy your backend code:"
echo ""
echo "   Option A - Using ZIP deployment:"
echo "   cd /path/to/backend"
echo "   zip -r backend.zip . -x 'node_modules/*' '.git/*'"
echo "   az webapp deploy --resource-group $RESOURCE_GROUP --name $BACKEND_NAME --src-path backend.zip --type zip"
echo ""
echo "   Option B - Using Git deployment:"
echo "   cd /path/to/backend"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git remote add azure https://${BACKEND_NAME}.scm.azurewebsites.net:443/${BACKEND_NAME}.git"
echo "   git push -u azure main"
echo ""
echo "   Option C - Using Docker:"
echo "   docker build -t ${BACKEND_NAME}:latest ."
echo "   docker tag ${BACKEND_NAME}:latest echovaultacr.azurecr.io/${BACKEND_NAME}:latest"
echo "   docker push echovaultacr.azurecr.io/${BACKEND_NAME}:latest"
echo "   az webapp create --resource-group $RESOURCE_GROUP --plan $PLAN_NAME --name ${BACKEND_NAME}-container --deployment-container-image-name echovaultacr.azurecr.io/${BACKEND_NAME}:latest"
echo ""
echo "3. Update Flutter config:"
echo "   File: lib/config/api_config.dart"
echo "   Change backend URL to: https://${APP_URL}/api"
echo ""
echo "4. Rebuild and redeploy frontend:"
echo "   flutter clean && flutter pub get && flutter build web --release"
echo ""
echo "5. Check logs:"
echo "   az webapp log tail --resource-group $RESOURCE_GROUP --name $BACKEND_NAME"
echo ""
echo "6. Test backend:"
echo "   curl https://${APP_URL}/api/health"
echo ""
echo -e "${YELLOW}Backend URL:${NC} https://${APP_URL}"
echo ""
