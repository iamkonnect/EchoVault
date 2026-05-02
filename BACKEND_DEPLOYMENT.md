# EchoVault Backend Deployment Guide

## Quick Start (Azure)

### Step 1: Create App Service Plan and Web App

```bash
# Set variables
RESOURCE_GROUP="echovault-rg"
PLAN_NAME="echovault-plan"
BACKEND_NAME="echovault-backend"
LOCATION="eastus"
SKU="B1"  # Free tier: "F1", Production: "P1V2"

# Create App Service Plan (if it doesn't exist)
az appservice plan create \
  --name $PLAN_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku $SKU \
  --is-linux

# Create Web App for Node.js
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --name $BACKEND_NAME \
  --runtime "NODE|18-lts"

# Configure web app for Node.js
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NAME \
  --settings \
    WEBSITES_PORT=3000 \
    NODE_ENV=production \
    NPM_CONFIG_PRODUCTION=false
```

### Step 2: Deploy Your Backend Code

Choose one of these options:

#### Option A: ZIP Deployment (Simplest)

```bash
cd /path/to/your/backend
# Create zip excluding node_modules
zip -r backend.zip . -x "node_modules/*" ".git/*" ".env.local"

# Deploy
az webapp deploy \
  --resource-group echovault-rg \
  --name echovault-backend \
  --src-path backend.zip \
  --type zip
```

#### Option B: Git Deployment

```bash
cd /path/to/your/backend

# Initialize git if not already done
git init
git add .
git commit -m "Deploy to Azure"

# Add Azure remote
git remote add azure https://echovault-backend.scm.azurewebsites.net:443/echovault-backend.git

# Push to Azure (will prompt for credentials or use deployment center)
git push -u azure main
```

#### Option C: Docker Deployment (Best for complex apps)

```bash
# Build Docker image
docker build -t echovault-backend:latest .

# Tag for registry
docker tag echovault-backend:latest echovaultacr.azurecr.io/echovault-backend:latest

# Push to ACR
docker push echovaultacr.azurecr.io/echovault-backend:latest

# Create webapp from container
az webapp create \
  --resource-group echovault-rg \
  --plan echovault-plan \
  --name echovault-backend \
  --deployment-container-image-name echovaultacr.azurecr.io/echovault-backend:latest \
  --registry-login-server echovaultacr.azurecr.io \
  --registry-username <username> \
  --registry-password <password>
```

### Step 3: Update Flutter Configuration

**File:** `lib/config/api_config.dart`

```dart
static String get baseUrl {
  if (kIsWeb) {
    final windowLocation = Uri.base.toString();
    
    if (windowLocation.contains('localhost')) {
      return 'http://localhost:5000/api';
    }
    
    // Azure backend
    return 'https://echovault-backend.azurewebsites.net/api';
  }
  
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

### Step 4: Rebuild and Redeploy Frontend

```bash
# Update Flutter
flutter clean
flutter pub get

# Build web
flutter build web --release

# Rebuild Docker
docker build -f Dockerfile.prod -t echovault:latest .

# Tag for ACR
docker tag echovault:latest echovaultacr.azurecr.io/echo-vault-frontend:latest

# Push to ACR
docker push echovaultacr.azurecr.io/echo-vault-frontend:latest

# Restart container on Azure
az container restart --resource-group echovault-rg --name echovault-frontend
```

## Backend Requirements

Your backend needs these endpoints and features:

### REST API Endpoints

```
GET    /api/health                    - Health check (required)
GET    /api/gifts                     - Get available gifts
POST   /api/gifts/send                - Send gift
POST   /api/streams/start             - Start live stream
POST   /api/streams/stop              - Stop live stream
GET    /api/streams/:id               - Get stream details
POST   /api/streams/join-request      - Join stream
POST   /api/chat/send                 - Send chat message
```

### WebSocket Events (Socket.IO)

Server should emit/handle:
```
Events to handle (client → server):
- joinStream(streamId)
- leaveStream(streamId)
- sendChatMessage({ text, streamId })
- sendGift({ receiverId, amount, streamId })

Events to emit (server → client):
- newChatMessage({ text, senderName, senderId })
- newGift({ senderName, amount, receiverId })
- userJoinedStream({ userId, count })
- userLeftStream({ userId, count })
- notification(...)
```

### CORS Configuration (Express)

```javascript
const cors = require('cors');

// Allow requests from your frontend domains
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost',
    'https://echovault-frontend.eastus.azurecontainer.io',
    'https://your-custom-domain.com'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### Socket.IO Configuration

```javascript
const io = require('socket.io')(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  transports: ['websocket', 'polling']
});

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('joinStream', (streamId) => {
    socket.join(`stream:${streamId}`);
    // Handle join logic
  });
  
  socket.on('sendChatMessage', (data) => {
    // Broadcast to stream
    io.to(`stream:${data.streamId}`).emit('newChatMessage', {
      text: data.text,
      senderName: 'User',
      senderId: socket.id,
      timestamp: new Date()
    });
  });
  
  socket.on('sendGift', (data) => {
    io.to(`stream:${data.streamId}`).emit('newGift', {
      senderName: 'User',
      amount: data.amount,
      receiverId: data.receiverId,
      timestamp: new Date()
    });
  });
});
```

## Monitoring and Logs

### View Live Logs

```bash
# Real-time logs
az webapp log tail \
  --resource-group echovault-rg \
  --name echovault-backend

# View last N lines
az webapp log download \
  --resource-group echovault-rg \
  --name echovault-backend
```

### Check App Status

```bash
# Get web app details
az webapp show \
  --resource-group echovault-rg \
  --name echovault-backend

# Get app settings
az webapp config appsettings list \
  --resource-group echovault-rg \
  --name echovault-backend

# Test endpoint
curl https://echovault-backend.azurewebsites.net/api/health
```

## Troubleshooting

### Backend Won't Start

1. Check logs:
   ```bash
   az webapp log tail --resource-group echovault-rg --name echovault-backend
   ```

2. Verify Node.js version:
   ```bash
   az webapp show --resource-group echovault-rg --name echovault-backend --query linuxFxVersion
   ```

3. Check app settings:
   ```bash
   az webapp config appsettings list --resource-group echovault-rg --name echovault-backend
   ```

### Connection Refused (5000 error in Flutter)

1. Verify backend URL in Flutter config matches Azure app name
2. Check CORS is enabled
3. Test endpoint:
   ```bash
   curl -v https://echovault-backend.azurewebsites.net/api/health
   ```

### WebSocket Connection Failed

1. Ensure Socket.IO is properly configured
2. Check transports include 'websocket'
3. Verify CORS allows WebSocket upgrades

### Port Issues

Azure App Service uses `WEBSITES_PORT` environment variable:
- Set it to your Node.js app's listening port
- Default: 3000
- Change if your app uses different port

## Cost Optimization

| SKU    | Price/Month | Best For |
|--------|------------|----------|
| Free (F1) | $0 | Development/Testing |
| Shared (D1) | $10 | Small apps |
| Basic (B1) | $55 | Production apps |
| Standard (S1) | $100+ | High traffic |

Use Free tier for testing, upgrade to B1 for production.

## Scaling

Enable auto-scale for production:

```bash
az appservice plan update \
  --name echovault-plan \
  --resource-group echovault-rg \
  --sku P1V2  # Premium tier for auto-scale

az monitor metrics alert create \
  --name backend-cpu-alert \
  --resource-group echovault-rg \
  --scopes /subscriptions/{subId}/resourceGroups/echovault-rg/providers/Microsoft.Web/serverfarms/echovault-plan \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Next Steps

1. Deploy your backend code using one of the methods above
2. Test health endpoint: `curl https://echovault-backend.azurewebsites.net/api/health`
3. Update Flutter API config
4. Rebuild and redeploy frontend
5. Monitor logs for any errors
6. Test live streaming functionality
