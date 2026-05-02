# EchoVault Azure Deployment Guide

## Prerequisites

1. **Azure Account** with active subscription
2. **GitHub Repository** with secrets configured
3. **Azure CLI** installed locally
4. **Docker** installed locally (for testing)

## Setup Steps

### 1. Create Azure Container Registry

```bash
# Set variables
RESOURCE_GROUP="echovault-rg"
REGISTRY_NAME="echovaultregistry"
LOCATION="eastus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create container registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $REGISTRY_NAME \
  --sku Basic
```

### 2. Get Registry Credentials

```bash
# Get username and password
az acr credential show \
  --resource-group $RESOURCE_GROUP \
  --name $REGISTRY_NAME
```

### 3. Add GitHub Secrets

Go to **GitHub Repository Settings → Secrets and variables → Actions** and add:

- `AZURE_REGISTRY_USERNAME`: Your ACR username
- `AZURE_REGISTRY_PASSWORD`: Your ACR password (access key)
- `AZURE_RESOURCE_GROUP`: echovault-rg
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

Get subscription ID:
```bash
az account show --query id -o tsv
```

### 4. Create Azure App Service (Alternative to Container Instances)

```bash
# Create App Service Plan
az appservice plan create \
  --name echovault-plan \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan echovault-plan \
  --name echovault-app \
  --deployment-container-image-name-user-provided true

# Configure container
az webapp config container set \
  --name echovault-app \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name echovaultregistry.azurecr.io/echovault:latest \
  --docker-registry-server-url https://echovaultregistry.azurecr.io \
  --docker-registry-server-user <USERNAME> \
  --docker-registry-server-password <PASSWORD>

# Enable continuous deployment
az webapp deployment container config \
  --name echovault-app \
  --resource-group $RESOURCE_GROUP \
  --enable-cd true
```

### 5. Deploy via GitHub Actions

1. Push changes to `main` branch:
```bash
git push origin main
```

2. GitHub Actions will:
   - Build Flutter web
   - Build Docker image
   - Push to Azure Container Registry
   - Deploy to Azure Container Instances

3. Monitor deployment in **GitHub Actions** tab

### 6. Access Your App

**Container Instances:**
- View in Azure Portal → Container Instances → echovault-app
- Get public IP address

**App Service:**
```bash
az webapp show \
  --resource-group $RESOURCE_GROUP \
  --name echovault-app \
  --query defaultHostName -o tsv
```

### 7. Local Testing (Before Deployment)

Build and run locally:
```bash
# Build Docker image
docker build -f Dockerfile.prod -t echovault:latest .

# Run container
docker run -p 8080:80 echovault:latest

# Access at http://localhost:8080
```

## Troubleshooting

### Check GitHub Actions Logs
1. Go to **Actions** tab
2. Click failed workflow
3. Expand job steps for detailed logs

### Check Azure Logs
```bash
# Container Instances
az container logs \
  --resource-group $RESOURCE_GROUP \
  --name echovault-app

# App Service
az webapp log tail \
  --resource-group $RESOURCE_GROUP \
  --name echovault-app
```

### Common Issues

**Docker build fails:**
- Ensure `pubspec.yaml` is in root directory
- Check Flutter version compatibility
- Verify all assets paths are correct

**Permission denied:**
- Verify Azure credentials in GitHub secrets
- Check ACR permissions for your user

**App not starting:**
- Check nginx config in logs
- Verify port 80 is exposed
- Check health endpoint: `/health`

## Rollback

If deployment fails, rollback to previous image:
```bash
az acr repository show-tags \
  --name $REGISTRY_NAME \
  --repository echovault

# Redeploy with previous tag
az webapp config container set \
  --name echovault-app \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name echovaultregistry.azurecr.io/echovault:<PREVIOUS_TAG>
```

## Cost Optimization

- **Container Instances**: Pay-per-second (good for dev/test)
- **App Service B1**: ~$55/month (good for production)
- **Azure Blob Storage**: For asset caching
- Use **Azure CDN** for global content delivery

## Next Steps

1. Set up custom domain
2. Enable HTTPS/SSL certificate
3. Configure auto-scaling
4. Set up monitoring and alerts
5. Enable Docker multi-stage caching in GitHub Actions
