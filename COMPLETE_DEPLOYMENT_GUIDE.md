# Complete EchoVault Azure Deployment Guide

## Prerequisites

- Azure account with active subscription
- Azure CLI installed (`az --version`)
- Docker installed (`docker --version`)
- Git installed with both repos cloned
- Node.js 18+ (for backend development)
- Flutter 3.24+ (for frontend development)

---

## Phase 1: Backend Deployment to Azure

### Step 1: Create App Service Plan

```bash
RESOURCE_GROUP="echovault-rg"
PLAN_NAME="echovault-plan"
BACKEND_NAME="echovault-backend"
LOCATION="eastus"
SKU="B1"  # Free: F1, Dev: B1, Production: P1V2

# Create plan (if doesn't exist)
az appservice plan create \
  --name $PLAN_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku $SKU \
  --is-linux
```

### Step 2: Create Web App for Backend

```bash
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --name $BACKEND_NAME \
  --runtime "NODE|18-lts"

# Configure Node.js settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --settings \
    WEBSITES_PORT=5000 \
    NODE_ENV=production \
    NPM_CONFIG_PRODUCTION=false
```

### Step 3: Deploy Backend Code

```bash
cd echo-vault-backend

# Install dependencies
npm install

# Create deployment zip (exclude node_modules)
zip -r backend.zip . -x "node_modules/*" ".git/*" ".env.local"

# Deploy to Azure
az webapp deploy \
  --resource-group echovault-rg \
  --name echovault-backend \
  --src-path backend.zip \
  --type zip

# Monitor deployment
az webapp log tail --resource-group echovault-rg --name echovault-backend
```

### Step 4: Verify Backend is Running

```bash
# Get backend URL
BACKEND_URL=$(az webapp show \
  --resource-group echovault-rg \
  --name echovault-backend \
  --query defaultHostName -o tsv)

# Test health endpoint
curl https://${BACKEND_URL}/api/health

# Expected response:
# {"status":"healthy","timestamp":"...","uptime":...}
```

---

## Phase 2: Frontend Configuration Update

### Update API Configuration

**File:** `lib/config/api_config.dart`

Change the backend URL to your Azure App Service:

```dart
static String get baseUrl {
  if (kIsWeb) {
    final windowLocation = Uri.base.toString();
    
    // For local development
    if (windowLocation.contains('localhost')) {
      return 'http://localhost:5000/api';
    }
    
    // For Azure production
    return 'https://echovault-backend.azurewebsites.net/api';
  }
  
  // Android emulator
  return 'http://10.0.2.2:5000/api';
}

static String get realtimeUrl {
  if (kIsWeb) {
    final windowLocation = Uri.base.toString();
    
    if (windowLocation.contains('localhost')) {
      return 'http://localhost:5000';
    }
    
    return 'https://echovault-backend.azurewebsites.net';
  }
  
  return 'http://10.0.2.2:5000';
}
```

### Commit Frontend Changes

```bash
cd echovault_working

git add lib/config/api_config.dart
git commit -m "Update API endpoint to Azure backend"
git push origin main
```

---

## Phase 3: Frontend Build & Deployment

### Build Flutter Web

```bash
cd echovault_working

# Clean and prepare
flutter clean
flutter pub get

# Build for production
flutter build web --release

# Verify build
ls build/web/index.html  # Should exist
```

### Build Docker Image

```bash
# Build the production image
docker build -f Dockerfile.prod -t echovault:latest .

# Test locally (optional)
docker run -p 8080:80 echovault:latest
# Visit http://localhost:8080
```

### Push to Azure Container Registry

```bash
# Tag image
docker tag echovault:latest \
  echovaultacr.azurecr.io/echo-vault-frontend:latest

# Login to ACR
az acr login --name echovaultacr

# Push to registry
docker push echovaultacr.azurecr.io/echo-vault-frontend:latest

# Verify pushed
az acr repository list --name echovaultacr --output table
```

### Update Container Instance

```bash
# Stop old container
az container stop \
  --resource-group echovault-rg \
  --name echovault-frontend

# Delete old container
az container delete \
  --resource-group echovault-rg \
  --name echovault-frontend \
  --yes

# Create new container
az container create \
  --resource-group echovault-rg \
  --name echovault-frontend \
  --image echovaultacr.azurecr.io/echo-vault-frontend:latest \
  --cpu 1 \
  --memory 1 \
  --ports 80 \
  --dns-name-label echovault-frontend \
  --registry-login-server echovaultacr.azurecr.io \
  --registry-username echovaultacr \
  --registry-password '<password_from_acr>'

# Get the URL
az container show \
  --resource-group echovault-rg \
  --name echovault-frontend \
  --query ipAddress.fqdn
```

---

## Phase 4: End-to-End Testing

### Test 1: Backend Health Check

```bash
curl https://echovault-backend.azurewebsites.net/api/health
# Expected: {"status":"healthy",...}
```

### Test 2: API Endpoints

```bash
# Get live streams
curl https://echovault-backend.azurewebsites.net/api/live/streams

# Get gifts
curl https://echovault-backend.azurewebsites.net/api/gifting

# Get coin packages
curl https://echovault-backend.azurewebsites.net/api/payments/coin-packages
```

### Test 3: Frontend Access

Open browser and visit:
```
https://echovault-frontend.eastus.azurecontainer.io
```

Should load without errors.

### Test 4: WebSocket Connection

Open browser DevTools (F12) and check Network/Console:
```javascript
// In console, check if socket connects
// Should see: ✓ Socket connected or connection in progress
```

### Test 5: Live Streaming Flow

1. Login as artist
2. Click "Go Live"
3. Allow camera/microphone permissions
4. Stream should start and show "LIVE" badge
5. Open another browser/device and view stream
6. Test sending gifts
7. Test chat messages

---

## Phase 5: Monitoring & Maintenance

### View Backend Logs

```bash
# Real-time logs
az webapp log tail \
  --resource-group echovault-rg \
  --name echovault-backend

# Download logs
az webapp log download \
  --resource-group echovault-rg \
  --name echovault-backend
```

### View Frontend Logs

```bash
# Container logs
az container logs \
  --resource-group echovault-rg \
  --name echovault-frontend
```

### Monitor Performance

```bash
# Backend metrics
az monitor metrics list \
  --resource-group echovault-rg \
  --resource-type "Microsoft.Web/sites" \
  --resource-name echovault-backend \
  --metric "HttpResponseTime"

# Container metrics
az container show \
  --resource-group echovault-rg \
  --name echovault-frontend
```

---

## Troubleshooting

### Issue: "API Failed 5000"

**Solution:**
```bash
# 1. Verify backend is running
curl https://echovault-backend.azurewebsites.net/api/health

# 2. Check if CORS is blocking
# Open DevTools (F12) > Console
# Look for CORS errors

# 3. Verify API URL in frontend config
# Check lib/config/api_config.dart

# 4. Restart backend
az webapp restart \
  --resource-group echovault-rg \
  --name echovault-backend
```

### Issue: "Container Restart Failed"

**Solution:**
```bash
# Check logs
az container logs \
  --resource-group echovault-rg \
  --name echovault-frontend

# Restart container
az container restart \
  --resource-group echovault-rg \
  --name echovault-frontend

# If still failing, recreate container
az container delete \
  --resource-group echovault-rg \
  --name echovault-frontend \
  --yes

# Then redeploy with az container create...
```

### Issue: "WebSocket Connection Failed"

**Solution:**
```bash
# 1. Verify backend Socket.IO is running
# 2. Check if realtimeUrl matches backend URL
# 3. Enable WebSocket transports in socket config
# 4. Check browser network tab for ws:// connections
```

### Issue: "Memory/CPU Issues"

**Solution:**
```bash
# Increase resources
az container update \
  --resource-group echovault-rg \
  --name echovault-frontend \
  --set containers[0].resources.requests.cpu=2 \
  --set containers[0].resources.requests.memoryInGb=2
```

---

## Cost Optimization

### Current Setup Costs
- App Service Plan (B1): ~$55/month
- Container Instances: ~$0.0000015/second (pay-per-second)
- Container Registry: ~$30/month

### Cost Reduction Options
1. Use Free tier App Service (F1) for dev/testing
2. Delete unused resources
3. Use Azure Spot instances for non-production
4. Schedule containers to stop during off-hours

### Stop All Resources When Not in Use
```bash
# Stop backend
az webapp stop \
  --resource-group echovault-rg \
  --name echovault-backend

# Stop container
az container stop \
  --resource-group echovault-rg \
  --name echovault-frontend
```

### Restart When Needed
```bash
# Start backend
az webapp start \
  --resource-group echovault-rg \
  --name echovault-backend

# Start container
az container start \
  --resource-group echovault-rg \
  --name echovault-frontend
```

---

## Advanced: Auto-Scaling

### Enable Auto-Scale for Backend

```bash
# Create autoscale rule
az monitor autoscale create \
  --resource-group echovault-rg \
  --resource echovault-plan \
  --resource-type "Microsoft.Web/serverfarms" \
  --min-count 1 \
  --max-count 3 \
  --count 1

# Add CPU-based scale-out rule
az monitor autoscale rule create \
  --resource-group echovault-rg \
  --autoscale-name echovault-autoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1
```

---

## Production Checklist

- [ ] Backend deployed and health check passing
- [ ] Frontend builds without errors
- [ ] API endpoints are synchronized
- [ ] CORS allows frontend domain
- [ ] WebSocket connects successfully
- [ ] Live streaming works end-to-end
- [ ] Gifts and payments tested
- [ ] Error logging configured
- [ ] Monitoring alerts set up
- [ ] Backup strategy in place
- [ ] SSL/TLS certificates valid
- [ ] Rate limiting configured
- [ ] User authentication works
- [ ] Database backups automated

---

## Rollback Plan

### If Deployment Fails

```bash
# Revert to previous frontend image
docker pull echovaultacr.azurecr.io/echo-vault-frontend:previous
docker tag echovaultacr.azurecr.io/echo-vault-frontend:previous echovaultacr.azurecr.io/echo-vault-frontend:latest
docker push echovaultacr.azurecr.io/echo-vault-frontend:latest

# Restart container
az container restart \
  --resource-group echovault-rg \
  --name echovault-frontend
```

### If Backend API Changes Break Frontend

```bash
# Revert API configuration
git revert HEAD~1  # Revert last commit
flutter build web --release
# Rebuild and redeploy frontend
```

---

## Useful Commands Summary

```bash
# Health checks
curl https://echovault-backend.azurewebsites.net/api/health
curl https://echovault-frontend.eastus.azurecontainer.io

# Logs
az webapp log tail --resource-group echovault-rg --name echovault-backend
az container logs --resource-group echovault-rg --name echovault-frontend

# Restart
az webapp restart --resource-group echovault-rg --name echovault-backend
az container restart --resource-group echovault-rg --name echovault-frontend

# Stop/Start
az webapp stop --resource-group echovault-rg --name echovault-backend
az webapp start --resource-group echovault-rg --name echovault-backend

# URLs
az webapp show --resource-group echovault-rg --name echovault-backend --query defaultHostName
az container show --resource-group echovault-rg --name echovault-frontend --query ipAddress.fqdn

# Status
az webapp show --resource-group echovault-rg --name echovault-backend --query state
az container show --resource-group echovault-rg --name echovault-frontend --query instanceView.state
```

---

## Support & Documentation

- **Backend API Contract**: `API_CONTRACT.md` (backend repo)
- **Frontend API Config**: `API_CONFIGURATION.md` (frontend repo)
- **Sync Status**: `SYNC_COMPLETE.md` (frontend repo)
- **Deployment Guides**: `BACKEND_DEPLOYMENT.md`, `AZURE_DEPLOYMENT.md` (both repos)

---

## Success Indicators

✓ App is live at https://echovault-frontend.eastus.azurecontainer.io
✓ API responding at https://echovault-backend.azurewebsites.net/api
✓ Live streaming works end-to-end
✓ Gifts and payments process correctly
✓ No console errors in browser DevTools
✓ WebSocket connects without CORS errors
✓ Logs show clean shutdown on restart
✓ Performance metrics look healthy

---

## Next Steps

1. Monitor logs for any errors
2. Test with real users
3. Gather feedback on streaming quality
4. Optimize database queries if needed
5. Add analytics tracking
6. Set up automated backups
7. Plan scaling for growth
8. Consider CDN for static assets

Good luck with your EchoVault deployment! 🚀
