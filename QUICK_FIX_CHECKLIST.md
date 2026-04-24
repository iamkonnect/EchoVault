# Quick-Start Checklist: Fixing API Issues Safely

## ✅ What's Already Done

- [x] Created `lib/config/api_config.dart` - Centralized configuration
- [x] Updated `lib/services/api_client.dart` - Enhanced with mapping & normalization
- [x] Created `lib/services/compatibility_service.dart` - Handles missing endpoints
- [x] Created comprehensive documentation

## 📋 Implementation Checklist

### Phase 1: Copy New Files (2 minutes)
- [x] `lib/config/api_config.dart` ✓ Ready
- [x] Updated `lib/services/api_client.dart` ✓ Ready
- [x] `lib/services/compatibility_service.dart` ✓ Ready

### Phase 2: Update Imports (10 minutes)
- [ ] In `lib/services/api_service_v2.dart`:
  - Add: `import 'package:echovault/config/api_config.dart';`
  - Add: `import 'compatibility_service.dart';`
  - Instantiate CompatibilityService in constructor
  
- [ ] In `lib/services/artist_service_v2.dart`:
  - Add: `import 'package:echovault/config/api_config.dart';`
  - Add: `import 'compatibility_service.dart';`
  - Instantiate CompatibilityService in constructor

- [ ] In `lib/services/auth_service_v2.dart`:
  - No changes needed (already uses ApiClient correctly)

### Phase 3: Update Providers (5 minutes)
- [ ] Create or update `lib/providers/api_providers.dart`:
  ```dart
  final compatibilityServiceProvider = Provider<CompatibilityService>((ref) {
    final apiClient = ref.watch(apiClientProvider);
    final cacheService = ref.watch(cacheServiceProvider);
    return CompatibilityService(
      apiClient: apiClient,
      cacheService: cacheService,
    );
  });
  ```

### Phase 4: Test (5 minutes)
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze` - Check for errors
- [ ] Run `flutter test` - Run existing tests
- [ ] No build errors? ✓ Success!

### Phase 5: Backend Coordination (Before merge)
- [ ] Share BACKEND_FIX_GUIDE.md with backend team
- [ ] Agree on endpoint implementation order
- [ ] Schedule implementation milestones

---

## 🔧 Backend Team: Required Fixes

Share this with your backend team. These are critical fixes needed:

### CRITICAL (Fix First)
1. **Search Endpoint**
   - `GET /api/tracks/search?q={query}`
   - Return: `{ success: true, data: [...tracks] }`

2. **Album Endpoints**
   - `GET /api/albums/{id}` - Get album details
   - `GET /api/albums/{id}/tracks` - Get album tracks
   - Return: `{ success: true, data: {...} }`

3. **Artist Browse Endpoints** (Different from dashboard)
   - `GET /api/artists/{id}` - Get artist profile
   - `GET /api/artists/{id}/tracks` - Get artist tracks
   - Return: `{ success: true, data: {...} }`

### HIGH PRIORITY (Fix Second)
4. **Standardize Response Format**
   - All endpoints return: `{ success: true/false, data: {...}, message: "..." }`
   - No more: `{ tracks: [...] }` or `{ items: [...] }`

5. **Fix Endpoint Naming**
   - Rename `/api/artist/earnings` → `/api/artist/revenue`
   - Rename `/api/artist/withdrawals` → `/api/artist/payouts`
   - Keep `/api/artist/upload-music` OR rename to `/api/artist/upload/audio`

### MEDIUM PRIORITY (Fix Third)
6. **Implement Missing Endpoints**
   - `GET /api/user/profile` - User profile data
   - `GET /api/user/liked-tracks` - Liked tracks list
   - `GET /api/chat/conversations` - Chat conversations
   - `GET /api/tracks/genre/{genre}` - Genre filtering
   - `GET /api/artist/live-insights` - Live insights
   - `POST /api/artist/start-stream` - Start stream
   - `POST /api/artist/stop-stream` - Stop stream

---

## 🚀 Before You Deploy

### Checklist
- [ ] All imports added successfully
- [ ] No build errors: `flutter analyze` ✓
- [ ] All tests pass: `flutter test` ✓
- [ ] Backend team confirms they'll implement endpoints
- [ ] Response format standardization confirmed
- [ ] Endpoint naming conflicts confirmed

### Safety Checks
- [ ] Old code still works (backward compatible)
- [ ] New code doesn't break old code
- [ ] Error messages are helpful
- [ ] Debug logging works
- [ ] Feature flags are accessible

### Test on Device
- [ ] App builds and launches: `flutter run`
- [ ] Login works
- [ ] Search returns empty (expected - not implemented)
- [ ] Other features still work
- [ ] No crashes on missing endpoints

---

## 📊 What Changes and What Doesn't

### What CHANGES (Invisible to User)
- API calls automatically mapped to correct endpoints
- Responses automatically normalized
- Debug logs show what's happening
- Port is always 5000 (not 3000)

### What STAYS THE SAME (User Won't Notice)
- UI looks identical
- Login works the same
- Trending, Featured, Live streams work
- Artist uploads work
- Everything else works

### What DOESN'T WORK YET (Expected)
- Search (backend not implemented)
- Albums (backend not implemented)
- Artist browsing (backend not implemented)
- Playlists (backend not implemented)
- User profile (backend not implemented)
- Chat (backend not implemented)

These will automatically work once backend implements them!

---

## 🔄 After Deployment

### Week 1: Backend Implements Search
1. Backend pushes `/api/tracks/search` endpoint
2. Remove this from `CompatibilityService.searchTracks()`
3. Frontend automatically uses real endpoint
4. Users can now search!

### Week 2: Backend Implements Albums
1. Backend pushes `/api/albums/` endpoints
2. Remove stubs from CompatibilityService
3. Frontend automatically uses real endpoints
4. Users can now browse albums!

### Week 3: Backend Fixes Naming
1. Backend renames endpoints
2. Update EndpointMapper
3. Frontend automatically uses correct names
4. Everything works perfectly!

---

## 💡 Pro Tips

### Enable Debug Mode
```dart
// In ApiConfig
static const bool enableDebugLogging = true;
```
Check logs: `flutter logs`

### Disable Features Temporarily
```dart
// If something breaks, disable temporarily:
static const bool enableEndpointMapping = false;
static const bool enableResponseNormalization = false;
```

### Test Specific Changes
```dart
// Test mapping
print(EndpointMapper.mapEndpoint('/api/artist/revenue'));

// Test normalization
print(ResponseNormalizer.normalize({'tracks': [...]}));
```

---

## ❓ Troubleshooting

### Build Error: "Cannot find package"
```bash
flutter pub get
flutter pub upgrade
```

### Import Error: "File not found"
- Check paths in imports match your project structure
- Ensure files are in correct directories

### API Calls Still Failing
- Check `ApiConfig.baseUrl` is correct
- Check `ApiConfig.enableDebugLogging = true` and read logs
- Ensure backend is running on port 5000

### Response Still Inconsistent
- Check `ApiConfig.enableResponseNormalization = true`
- Add logging to see what response looks like
- Share response format with backend team

### Tests Failing
```bash
# Run tests with verbose output
flutter test -v

# Run specific test
flutter test test/api_test.dart
```

---

## 📞 Communication with Backend

**Template Message to Backend Team:**
```
Hi team,

We've implemented a compatibility layer on the frontend to handle API 
inconsistencies. Here's what we need from you:

1. Response Format: All endpoints should return:
   { success: true/false, data: {...}, message: "..." }

2. Implement these critical endpoints:
   - GET /api/tracks/search?q={query}
   - GET /api/albums/{id}
   - GET /api/artists/{id}

3. Fix endpoint naming:
   - /api/artist/earnings → /api/artist/revenue
   - /api/artist/withdrawals → /api/artist/payouts

Timeline: We can start integration once first endpoint is ready.

See: BACKEND_FIX_GUIDE.md for details.
```

---

## ✅ Final Checklist

Before declaring success:
- [ ] Code compiles without errors
- [ ] Tests pass
- [ ] No breaking changes to existing functionality
- [ ] Debug logs show API calls
- [ ] Missing endpoints gracefully return empty
- [ ] Backend team has implementation plan
- [ ] Documentation is clear

---

**Status:** Ready to implement! 🚀

**Next Step:** Follow Phase 1 checklist above, then run `flutter test`

**Questions?** Check IMPLEMENTATION_GUIDE.md for detailed steps.
