/// POSTMAN API ENDPOINTS INTEGRATION DOCUMENTATION
/// EchoVault Flutter Frontend
/// Last Updated: 2026-05-27
///
/// This file documents all API endpoints from the Postman collection
/// and their Flutter implementation in the frontend services.

// ============================================================================
// AUTHENTICATION ENDPOINTS
// ============================================================================
// Location: lib/services/auth_service_v2.dart

/*
POST /api/auth/register
  Description: Register a new user (artist or listener)
  Body: {
    "email": "artist@test.com",
    "password": "password123",
    "name": "Test Artist",
    "role": "ARTIST"
  }
  Flutter: AuthService.register()

POST /api/auth/login
  Description: Login with email and password
  Body: {
    "email": "artist@test.com",
    "password": "password123"
  }
  Flutter: AuthService.login()
  Returns: { token, user }

POST /api/auth/logout
  Description: Logout and invalidate session
  Flutter: AuthService.logout()
*/

// ============================================================================
// ARTIST ENDPOINTS - DASHBOARD & MUSIC
// ============================================================================
// Location: lib/services/artist_service_v2.dart

/*
GET /api/artist/dashboard
  Description: Get artist dashboard data (overview, stats)
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getDashboardData()

GET /api/artist/music
  Description: Get artist's uploaded music library
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getArtistMusic()
*/

// ============================================================================
// ARTIST ENDPOINTS - INSIGHTS & ANALYTICS
// ============================================================================

/*
GET /api/artist/insights
  Description: Get artist insights and analytics
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getArtistInsights()

GET /api/artist/live-insights
  Description: Get live music insights and real-time analytics
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getLiveInsights()

GET /api/artist/shorts-insights
  Description: Get shorts-specific insights
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getShortsInsights()
*/

// ============================================================================
// ARTIST ENDPOINTS - REVENUE & WITHDRAWALS
// ============================================================================

/*
GET /api/artist/earnings
  Description: Get revenue data and earnings breakdown
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getRevenueData()

GET /api/artist/withdrawals
  Description: Get withdrawal history
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getPayoutHistory()

POST /api/artist/withdraw
  Description: Request fund withdrawal
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Body: {
    "amount": 50.00
  }
  Flutter: ArtistServiceV2.requestWithdrawal()
*/

// ============================================================================
// TRACK UPLOAD ENDPOINTS
// ============================================================================

/*
POST /api/tracks/upload
  Description: Upload audio track with metadata
  FormData:
    - audioFile (required): audio file
    - title (required): track title
    - quality (optional): HI_RES_LOSSLESS, etc.
    - genre (optional): music genre
    - description (optional): track description
    - coverArt (optional): cover art image
  Flutter: ArtistServiceV2.uploadAudio()

POST /api/artist/upload/video
  Description: Upload video content
  FormData:
    - videoFile (required): video file
    - title (required): video title
    - description (optional): video description
    - thumbnail (optional): thumbnail image
  Flutter: ArtistServiceV2.uploadVideo()

POST /api/artist/upload/shorts
  Description: Upload short-form video
  FormData:
    - shortFile (required): video file
    - title (required): short title
    - description (optional): short description
    - thumbnail (optional): thumbnail image
  Flutter: ArtistServiceV2.uploadShorts()
*/

// ============================================================================
// LIVE STREAM ENDPOINTS
// ============================================================================

/*
POST /api/artist/start-stream
  Description: Start a live stream
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Body: {
    "title": "stream title",
    "thumbnail": "..." (optional)
  }
  Flutter: ArtistServiceV2.startLiveStream()

POST /api/artist/stop-stream
  Description: Stop a live stream
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Body: {
    "streamId": "stream_id"
  }
  Flutter: ArtistServiceV2.stopLiveStream()
*/

// ============================================================================
// MUSIC MANAGEMENT ENDPOINTS
// ============================================================================

/*
PUT /api/artist/music/{musicId}
  Description: Edit music metadata
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Body: { metadata fields to update }
  Flutter: ArtistServiceV2.editMusic()

DELETE /api/artist/music/{musicId}
  Description: Delete music track
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.deleteMusic()

GET /api/artist/music/{musicId}/stats
  Description: Get detailed music statistics
  Headers: Authorization: Bearer YOUR_JWT_TOKEN_HERE
  Flutter: ArtistServiceV2.getMusicStats()
*/

// ============================================================================
// CONFIGURATION & SETUP
// ============================================================================

/*
API Base URL Configuration:
  File: lib/config/api_config.dart
  
  Development (localhost):
    - Web: http://localhost:5000
    - Mobile Android: http://10.0.2.2:5000
    - Mobile iOS: http://localhost:5000
  
  Production (Azure):
    - All: http://echovault-backend.eastus.azurecontainer.io:5000

All endpoints are prefixed with /api
Automatic token handling via ApiClient
*/

// ============================================================================
// TOKEN & AUTHENTICATION
// ============================================================================

/*
Token Storage:
  - Stored securely using flutter_secure_storage
  - Automatically included in all authenticated requests
  - Retrieved via AuthService.getToken()
  - Cleared on logout

Token Management in Frontend:
  1. After login/register: AuthService.setToken(token)
  2. For API requests: ApiClient automatically adds Authorization header
  3. On logout: AuthService.clearToken()

Bearer Token Format:
  Authorization: Bearer {token}
*/

// ============================================================================
// ERROR HANDLING
// ============================================================================

/*
API errors return Map<String, dynamic> with structure:
  {
    "success": false,
    "error": "error message"
  }

All methods return maps with "success" key for error detection.
Errors are logged via developer.log with service name tag.
*/
