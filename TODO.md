# EchoVault Fix Plan - Tracking

## Issues Found & Status

### ✅ 1. Auth Registration Role Fix (DONE)
- Backend `authController.js` uses `role: 'USER'` for frontend registrations (already correct)
- `/auth/upgrade-artist` route exists with `protect` middleware
- `upgradeToArtist` controller is implemented

### ✅ 2. OAuth Buttons - Now Functional (DONE)
- Added `url_launcher: ^6.3.0` to `pubspec.yaml`
- `auth_screen.dart`: Google/Apple buttons call `_launchOAuth(provider)` → `launchUrl(Uri.parse(oauthUrl))`
- `auth_modal.dart`: Google/Apple buttons call `_launchOAuth(provider)` with same mechanism
- Backend handles OAuth flow and redirects to `auth_callback_screen.dart` with token

### ✅ 3. Missing Artist Service Methods (DONE)
Added to `artist_service_v2.dart`:
- `startLiveStream({required String title})`
- `stopLiveStream(String streamId)`
- `upgradeToArtist()`
- `getArtistInsights()`
- `getShortsInsights()`
- `getRevenueData()`
- `getPayoutHistory()`
- `requestWithdrawal({required double amount, String? paymentMethod})`

### ✅ 4. Payment Routes Verified (DONE)
- Both `paymentRoutes.js` and `paymentsRoutes.js` exist in `src/routes/`
- `server.js` correctly registers both under proper paths

### 🔲 5. Gift Revenue Split - Backend Base Done
- `GiftTemplate` schema has `artistShare` (0.4), `creatorShare` (0.4), `adminShare` (0.2)
- `giftingController.js` handles:
  - Standard: 80% artist, 20% admin
  - Short challenge (user created): 40% artist, 20% admin, 40% user
- **Needs**: Explicit 40/20/40 split for "user playing artist song during their own live"

### 🔲 6. Profile Screen Artist Toggle - Needs Backend API Call
- Profile screen has local-only toggle via `ref.read(userProvider.notifier).setRole()`
- Should call `artistService.upgradeToArtist()` and refresh user data from backend

### ✅ 7. Super Admin Seed Script (DONE)
- Created `seed-super-admin.js` at backend root
- Creates: `akwera@echovaultz.com` / `Deandre360xi!` (ADMIN role)
- Run: `cd C:\Users\infin\Downloads\echo-vault-backend && node seed-super-admin.js`

### ✅ 8. Schema & Routes Already Proper (DONE)
- Backend schema has `GiftTemplate`, `CoinPackage`, `Transaction`
- Auth routes include OAuth Google/Apple and upgrade-artist endpoints

### ✅ 9. Add Artist Management (Admin Panel) (DONE)
- Created `views/admin-add-artist.ejs` - Full admin page to add/edit/suspend artists with styled sidebar integration and search/filter
- **Add Artist Form**: Name, email, username, phone, genre, country - auto-generates password via `crypto.randomBytes`, sends styled HTML credentials email
- **Suspend/Reactivate**: POST endpoints toggle `isVerified` field
- **Resend Credentials**: Emails login instructions to artist's email
- **Artist List Table**: Shows all artists with name, email, username, content stats (songs/shorts), status badge (Active/Suspended), join date, action buttons
- **Routes in `src/routes/adminRoutes.js`**:
  - `GET /api/admin/add-artist` - Render EJS page
  - `POST /api/admin/artists/create` - Create + email credentials
  - `GET /api/admin/artists/api` - List all artists (JSON)
  - `POST /api/admin/artists/:id/suspend` - Suspend
  - `POST /api/admin/artists/:id/unsuspend` - Reactivate
  - `POST /api/admin/artists/:id/resend-credentials` - Email login info
- **Password Change**: Artists use backend `/login` → "Forgot Password" → email reset link
- **Sidebar**: "Add Artist" nav item under User Management in admin dashboards
