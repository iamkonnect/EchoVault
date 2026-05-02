# EchoVault API Configuration Guide

## API Endpoint Configuration

Your EchoVault app needs to connect to a backend API. The configuration depends on where your backend is deployed.

### Option 1: Local Development (localhost)

**Backend:** Running on `http://localhost:5000`

**Frontend Configuration (web):**
- Automatically detected and uses `http://localhost:5000/api`

**Frontend Configuration (mobile):**
- Android Emulator: `http://10.0.2.2:5000/api`
- Physical Device: Update `api_config.dart` with your computer's IP

### Option 2: Azure Deployment

**Backend:** Deployed on Azure App Service

**Steps:**

1. **Deploy your Node.js/Express backend to Azure:**
   ```bash
   az webapp create --resource-group echovault-rg --plan echovault-plan --name echovault-backend --runtime "NODE|18-lts"
   az webapp config appsettings set --resource-group echovault-rg --name echovault-backend --settings WEBSITES_PORT=5000
   ```

2. **Update `lib/config/api_config.dart`:**
   Replace:
   ```dart
   return 'https://echovault-backend.azurewebsites.net/api';
   ```

3. **Rebuild and redeploy:**
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release
   docker build -f Dockerfile.prod -t echovault:latest .
   # Push to Azure Container Registry
   ```

### Option 3: Same-Origin Proxy (Recommended for Production)

If your backend and frontend are served from the same domain, use relative paths:

**Update `lib/config/api_config.dart`:**
```dart
if (kIsWeb) {
  return '/api'; // Relative path - backend must be at /api
}
```

**Nginx reverse proxy setup:**
```nginx
location /api {
  proxy_pass http://backend-service:5000/api;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
}
```

## Checking Backend Connection

### 1. Browser Console
Open the app in your browser and check the developer console (F12):
- Network tab → look for API calls
- Console → any error messages

### 2. Check API Health
```bash
curl http://localhost:5000/api/health
# or
curl https://echovault-backend.azurewebsites.net/api/health
```

### 3. Check WebSocket Connection
Open browser console:
```javascript
// Check if WebSocket can connect
const ws = new WebSocket('ws://localhost:5000');
ws.onopen = () => console.log('WebSocket connected');
ws.onerror = (e) => console.log('WebSocket error:', e);
```

## Common Errors

### "API Failed 5000"
- Backend API is not running
- Backend URL is incorrect in `api_config.dart`
- CORS not enabled on backend
- Backend crashed or unresponsive

### Solution:
1. Verify backend is running: `curl http://localhost:5000/health`
2. Check backend logs
3. Enable CORS in Express:
   ```javascript
   app.use(cors({
     origin: '*', // For development
     methods: ['GET', 'POST', 'PUT', 'DELETE'],
     credentials: true,
   }));
   ```

### "WebSocket Connection Failed"
- Backend WebSocket not configured
- URL mismatch between REST API and WebSocket
- Port not exposed/accessible

### Solution:
1. Verify Socket.IO is configured on backend
2. Check that both REST and WebSocket use same base URL
3. For Azure, ensure port 5000 is exposed or use reverse proxy

## Environment Variables (for future use)

You can extend `api_config.dart` to support environment variables:

```dart
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // Read from environment or use defaults
    final env = Platform.environment;
    return env['API_BASE_URL'] ?? 'http://localhost:5000/api';
  }
}
```

## Deployment Checklist

- [ ] Backend API deployed to Azure
- [ ] API endpoint updated in `api_config.dart`
- [ ] CORS enabled on backend
- [ ] WebSocket configured on backend
- [ ] Health check endpoint working
- [ ] Flutter app rebuilt with new config
- [ ] Docker image rebuilt and pushed
- [ ] Container restarted on Azure
- [ ] Test live streaming functionality
- [ ] Check browser console for errors

## Backend Requirements for Live Streaming

Your backend needs these endpoints:

```
GET    /api/health                          - Health check
POST   /api/streams/start                   - Start live stream
POST   /api/streams/stop                    - Stop live stream
GET    /api/streams/:id                     - Get stream details
POST   /api/streams/join-request            - Join stream
WebSocket /socket.io                         - Real-time events
  - joinStream
  - leaveStream
  - sendChatMessage
  - sendGift
  - newChatMessage (receive)
  - newGift (receive)
```

See `services/realtime_service.dart` for expected event structure.
