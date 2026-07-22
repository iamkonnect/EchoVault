# Fix Frontend API URL & Asset Issues

## Changes Applied
- [x] 1. Delete `assets/assets/` directory (empty nested folder)
- [x] 2. Fixed `pubspec.yaml` - removed `- assets/assets/` line
- [x] 3. Fixed `Dockerfile` - added `RUN chmod -R a+rX /usr/share/nginx/html`
- [x] 4. Fixed `lib/services/api_client.dart` - removed extra `/api` prefix from all URL constructions (GET, POST, PUT, DELETE, postFormData)
- [x] 5. Fixed `lib/screens/live_screen.dart` - corrected URL construction to use `ApiConfig.baseUrl + "/api/live/streams/active"` instead of the broken double-`/api` pattern
- [ ] 6. `flutter clean && flutter pub get && flutter build web --release`
- [ ] 7. Commit and push to GitHub master

## Root Cause of `api/api` Bug
`api_client.dart` was constructing URLs as `$baseUrl/api$mappedEndpoint` but all V2 services (`auth_service_v2.dart`, `api_service_v2.dart`, `artist_service_v2.dart`, `compatibility_service.dart`) already pass endpoints starting with `/api/...`. This resulted in requests like:
- `https://admin.echovaultz.com/api/api/auth/register` ❌
- `https://admin.echovaultz.com/api/api/tracks/featured` ❌

**Fix:** Removed the extra `/api` from `api_client.dart` URL construction. Now produces:
- `https://admin.echovaultz.com/api/auth/register` ✅
- `https://admin.echovaultz.com/api/tracks/featured` ✅
