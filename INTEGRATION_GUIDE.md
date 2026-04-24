# EchoVault Frontend-Backend Integration Guide

## Overview
This guide covers the complete integration between your Flutter frontend (web & mobile) and Node.js/Express backend with Prisma ORM.

---

## Table of Contents
1. [Project Structure](#project-structure)
2. [Backend Setup](#backend-setup)
3. [Frontend Setup](#frontend-setup)
4. [API Integration](#api-integration)
5. [Running Locally](#running-locally)
6. [Docker Desktop Networking](#docker-desktop-networking)
6. [Docker Deployment](#docker-deployment)
7. [Testing](#testing)

---

## Project Structure

### Backend (`echo-vault-backend`)
```
├── src/
│   ├── controllers/      # Business logic
│   ├── routes/          # API endpoints
│   ├── middlewares/      # Authentication, validation
│   └── utils/           # Database, helpers
├── prisma/              # ORM schema & migrations
├── public/              # Static files (dashboards)
├── Dockerfile           # Container configuration
├── docker-compose.yml   # Service orchestration
└── server.js           # Main application entry
```

### Frontend (`echovault_working`)
```
├── lib/
│   ├── services/        # API clients & authentication
│   ├── providers/       # Riverpod state management
│   ├── screens/        # UI pages
│   ├── models/         # Data models
│   ├── config/         # Configuration files
│   └── main.dart       # App entry point
├── web/                # Flutter web build
├── android/            # Android native code
└── pubspec.yaml        # Dependencies
```

---

## Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- Docker & Docker Compose (optional)

### Installation

1. **Navigate to backend directory**
   ```bash
   cd echo-vault-backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   Create or update `.env`:
   ```env
   JWT_SECRET=echovault_supersecret2024
   PORT=5000
   CLIENT_URL=http://localhost:3000
   DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/echo_vault_db?schema=public
   NODE_ENV=development
   ```

4. **Set up database**
   ```bash
   # Create database
   createdb echo_vault_db
   
   # Run migrations
   npm run prisma:migrate
   
   # (Optional) Seed data
   node seed.js
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```
   Server runs on `http://localhost:5000`

### Available Routes

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/login-dashboard` - Login to dashboard
- `POST /api/auth/logout` - Logout user

#### Artist Routes (Protected)
- `GET /api/artist/dashboard` - Artist dashboard data
- `GET /api/artist/my-music` - Artist's uploaded music
- `GET /api/artist/live-insights` - Analytics data
- `GET /api/artist/revenue` - Revenue information
- `POST /api/artist/upload/audio` - Upload audio file
- `POST /api/artist/upload/video` - Upload video
- `POST /api/artist/withdraw` - Request payout

#### Admin Routes (Protected)
- `GET /api/admin/dashboard` - Admin dashboard
- `GET /api/admin/reports` - Platform reports
- `GET /api/admin/users` - User management
- `GET /api/admin/payouts` - Payout management

---

## Frontend Setup

### Prerequisites
- Flutter 3.24.0+
- Dart 3.4.4+
- Android Studio / Xcode (for mobile builds)
- Chrome (for web development)

### Installation

1. **Navigate to frontend directory**
   ```bash
   cd echovault_working
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Edit `lib/config/app_config.dart`:
   - Update `apiBaseUrl` for your backend URL
   - Adjust timeouts if needed

4. **Generate Hive type adapters** (required for local storage)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Running the Application

#### Web
```bash
# Development
flutter run -d chrome

# Build for production
flutter build web --release
```
Web app runs on `http://localhost:5173` (or configured port)

#### Android
```bash
# Debug
flutter run

# Build APK
flutter build apk --release
```
Note: Uses `10.0.2.2:5000` to connect to localhost backend from emulator

#### iOS
```bash
# Debug
flutter run

# Build IPA
flutter build ipa --release
```

---

## API Integration

### 1. API Client Architecture

**Location:** `lib/services/api_client.dart`

The centralized `ApiClient` handles:
- HTTP request/response
- JWT token management
- Error handling
- Request logging
- CORS compatibility

```dart
// Initialize API client
final apiClient = ApiClient(
  baseUrl: 'http://localhost:5000',
  isWeb: true, // Set based on platform
);

// Make authenticated requests
final response = await apiClient.get('/api/user/profile');
```

### 2. Service Layer

**Authentication Service** (`lib/services/auth_service_v2.dart`)
```dart
final authService = AuthService(apiClient: apiClient);

// Register
final result = await authService.register(
  email: 'artist@example.com',
  password: 'secure_password',
  name: 'Artist Name',
  role: 'ARTIST',
);

// Login
final login = await authService.login(
  email: 'artist@example.com',
  password: 'secure_password',
);

// Logout
await authService.logout();
```

**API Service** (`lib/services/api_service_v2.dart`)
```dart
final apiService = EchoVaultApiService(apiClient: apiClient);

// Search tracks
final tracks = await apiService.searchTracks('song name');

// Get trending
final trending = await apiService.getTrendingTracks();

// Get playlist
final playlistTracks = await apiService.getUserPlaylist('playlist-id');
```

**Artist Service** (`lib/services/artist_service_v2.dart`)
```dart
final artistService = ArtistServiceV2(apiClient: apiClient);

// Get dashboard
final dashboard = await artistService.getDashboardData();

// Upload music
final upload = await artistService.uploadAudio(
  title: 'Song Title',
  filePath: '/path/to/audio.mp3',
  genre: 'Pop',
);

// Get insights
final insights = await artistService.getArtistInsights();
```

### 3. State Management with Riverpod

**Location:** `lib/providers/api_providers.dart`

Providers are automatically cached and refreshed:

```dart
// Use in widgets
@override
Widget build(BuildContext context, WidgetRef ref) {
  final tracksAsync = ref.watch(trendingTracksProvider);
  
  return tracksAsync.when(
    data: (tracks) => ListView(children: tracks.map((t) => Text(t['title'])).toList()),
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => Text('Error: $err'),
  );
}

// Manual refresh
ref.refresh(trendingTracksProvider);

// Get service directly
final apiService = ref.watch(apiServiceProvider);
```

### 4. Authentication Flow

```dart
// 1. Login
final authService = ref.watch(authServiceProvider);
final loginResult = await authService.login(
  email: email,
  password: password,
);

// 2. Token is automatically saved and set in headers
// 3. All subsequent requests include Authorization header
// 4. On logout, token is cleared

if (loginResult['success']) {
  // Navigate to home
} else {
  // Show error: loginResult['error']
}
```

---

## Running Locally

### Option 1: Direct Execution (Development)

**Terminal 1 - Backend:**
```bash
cd echo-vault-backend
npm install
npm run prisma:migrate  # First time only
npm run dev
```

**Terminal 2 - Frontend (Web):**
```bash
cd echovault_working
flutter pub get
flutter run -d chrome
```

**Access:**
- Backend API: `http://localhost:5000`
- Frontend Web: `http://localhost:5173`
- Dashboard: `http://localhost:5000/` (served by backend)

### Option 2: Docker Compose (Recommended)

```bash
cd echo-vault-backend

# Development setup (hot reload)
docker-compose -f docker-compose-dev.yml up --build

# Production setup
docker-compose -f docker-compose-prod.yml up --build
```

**Services:**
- Backend API: `http://localhost:5000`
- PostgreSQL: `localhost:5432`
- pgAdmin: `http://localhost:5050` (credentials: admin/admin)

---

## Docker Desktop Networking

When running the backend in Docker Desktop, your Flutter frontend needs to know where to find the API. Update your `apiBaseUrl` based on your debug platform:

### 1. Flutter Web
If you are running `flutter run -d chrome`, Docker maps the ports to your machine's localhost.
- **Base URL:** `http://localhost:5000`

### 2. Android Emulator
The Android Emulator runs in a virtual machine. `localhost` inside the emulator refers to the emulator itself, not your computer.
- **Base URL:** `http://10.0.2.2:5000` (This is a special alias to your host's loopback interface).

### 3. iOS Simulator
The iOS simulator shares the network stack with your Mac.
- **Base URL:** `http://localhost:5000`

### 4. Physical Mobile Device
Your phone must be on the same Wi-Fi network as your computer running Docker.
- **Base URL:** `http://<YOUR_COMPUTER_IP>:5000` (e.g., `http://192.168.1.5:5000`)
- *Note:* Ensure your computer's firewall allows incoming traffic on port 5000.

---

## Docker Deployment

### Build Backend Image

```bash
cd echo-vault-backend

# Build
docker build -t echo-vault-api:latest .

# Run
docker run -p 5000:5000 \
  -e DATABASE_URL=postgresql://... \
  -e JWT_SECRET=your_secret \
  echo-vault-api:latest
```

### Build Frontend Web

```bash
cd echovault_working

# Build production web
flutter build web --release

# Serve with nginx or your server
# The output is in build/web/
```

### Full Stack Docker

```bash
# Use docker-compose (includes backend + database)
docker-compose -f docker-compose-prod.yml up -d

# For frontend, deploy separately:
# 1. Build: flutter build web
# 2. Upload build/web to web server
# 3. Configure CORS in backend to allow web origin
```

---

## Testing

### Backend Testing

```bash
# Test specific endpoint
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Test authenticated endpoint
curl -X GET http://localhost:5000/api/artist/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Testing

**Test API Connection:**
```dart
void testApiConnection() async {
  final apiClient = ApiClient();
  try {
    final response = await apiClient.get('/api/tracks/trending');
    print('Success: $response');
  } catch (e) {
    print('Error: $e');
  }
}
```

**Test Authentication:**
```dart
void testAuth() async {
  final authService = AuthService(apiClient: ApiClient());
  final result = await authService.login(
    email: 'test@example.com',
    password: 'password',
  );
  print('Auth Result: $result');
}
```

---

## Common Issues & Solutions

### Issue: CORS Error
**Solution:** Backend already has CORS configured. Ensure:
1. `CLIENT_URL` env var matches your frontend URL
2. Frontend is not on a different port than expected
3. Check `server.js` CORS configuration

### Issue: Connection Refused (localhost:5000)
**Solution:**
1. Ensure backend is running: `npm run dev`
2. Check if port 5000 is in use: `lsof -i :5000`
3. For mobile, use `10.0.2.2:5000` (Android) or `localhost:5000` (iOS)

### Issue: Token Expiration
**Solution:** Implement token refresh:
1. Add refresh endpoint to backend
2. Update `_AuthInterceptor` to handle 401 responses
3. Automatically refresh token on expiry

### Issue: File Upload Fails
**Solution:**
1. Check upload directory permissions
2. Ensure `multer` config is correct in `multerConfig.js`
3. Verify file size limits

---

## Next Steps

1. **Implement remaining endpoints** - Add any missing API routes
2. **Add WebSocket support** - Backend has socket.io configured for real-time updates
3. **Implement offline mode** - Use Hive caching for offline functionality
4. **Add error handling** - Global error dialog/toast notifications
5. **Performance optimization** - Implement pagination, lazy loading
6. **Analytics & monitoring** - Add Sentry, Mixpanel
7. **CI/CD setup** - GitHub Actions for automated testing/deployment

---

## API Documentation

### Base URL
- **Development:** `http://localhost:5000`
- **Production:** Your deployed domain

### Authentication
All protected routes require:
```
Authorization: Bearer <JWT_TOKEN>
```

### Response Format
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Success message"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "statusCode": 400
}
```

---

## Support

For issues or questions:
1. Check server logs: `docker logs echo-vault-api`
2. Check Flutter logs: `flutter logs`
3. Database queries: Access pgAdmin at `http://localhost:5050`
