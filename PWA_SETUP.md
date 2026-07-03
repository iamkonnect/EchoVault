# EchoVault PWA Setup Guide

## What is PWA?

Progressive Web App (PWA) allows users to install EchoVault directly on their phones/computers like a native app without needing the app store.

## Features Enabled

✅ **Install to Home Screen** - Add app directly to phone/desktop
✅ **Offline Support** - Service Worker caches core files
✅ **App Icon** - Shows app icon instead of browser icon
✅ **Standalone Mode** - Opens fullscreen without browser UI
✅ **Fast Loading** - Cached resources load instantly
✅ **Auto-Updates** - Service Worker detects and installs updates

## How Users Install (On Different Devices)

### Android Chrome
1. Visit `https://echovaultz.com`
2. Tap the 3-dot menu → "Install app" or see install prompt
3. Tap "Install" on the popup
4. App appears on home screen

### iPhone/iPad Safari
1. Visit `https://echovaultz.com`
2. Tap Share icon (↑)
3. Select "Add to Home Screen"
4. Tap "Add"
5. App appears on home screen

### Desktop Chrome/Edge
1. Visit `https://echovaultz.com`
2. Click the install icon in address bar (or 3-dot menu → "Install app")
3. App installs to start menu/dock

### Desktop Firefox
1. Visit `https://echovaultz.com`
2. Click 3-dot menu → "Add to home screen" or "Install"
3. App installs to applications

## Technical Details

### Service Worker (`web/service_worker.js`)
- Caches static assets on first visit
- Serves from cache for fast loading
- Falls back to network if offline
- Auto-updates when new version deployed

### Manifest (`web/manifest.json`)
- Defines app name, description, icons
- Sets display mode (standalone - fullscreen)
- Specifies theme colors
- Includes maskable icons for adaptive display

### HTML Changes (`web/index.html`)
- Registers service worker on load
- PWA meta tags for iOS/Android
- Handles install prompts
- Detects controller changes for updates

## Deployment Requirements

For PWA to work, ensure:

1. **HTTPS only** - PWA requires secure connection ✅
2. **Valid manifest.json** - Already included ✅
3. **Service Worker** - Already included ✅
4. **Icons** - Uses existing `icons/Icon-192.png` and `Icon-512.png` ✅

## Testing PWA Locally

```bash
flutter build web --release
# Serve with: python -m http.server 8000 (or similar)
# Visit https://localhost:8000
# Check browser DevTools → Application → Manifest & Service Workers
```

## Monitoring Installation

Track PWA installs in Flutter by listening to install prompts:

```dart
// In your Flutter app
window.addEventListener('beforeinstallprompt', (event) {
  print('User can install app');
  // Optionally show custom install button
});
```

## Auto-Update Behavior

When new version is deployed:
1. Service Worker checks for updates
2. New version downloads in background
3. User notified or auto-refreshes
4. Updated app loads on next visit

## Cache Strategy

**Static Assets:** Cache first → Network fallback
**API Calls:** Network first → Cache fallback
**Max Cache Size:** Configured for mobile devices

## iOS Limitations

iOS PWA support is limited:
- No background sync
- No push notifications (yet)
- Limited offline functionality
- Requires manual install (no auto-prompt)

Consider native iOS app for full features if needed.

---

For more info: https://web.dev/progressive-web-apps/
