# TODO - Web camera preview fix

- [ ] Implement web camera preview + mic using getUserMedia in `lib/services/camera_service.dart`.
  - [ ] Add `dart:html`-based video element preview wrapped in Flutter (`HtmlElementView`).
  - [ ] Ensure permissions are requested and errors are surfaced.
- [ ] Update `CameraService.startRecording()` on web to start the stream and mark ready only after getUserMedia resolves.
- [ ] Update `lib/screens/live_broadcast_screen.dart`:
  - [ ] Only show “✓ Stream started” after camera preview/stream is active.
  - [ ] Ensure `_cameraReady` becomes true on web after getUserMedia.
- [ ] Run/build checks:
  - [ ] `flutter analyze`
  - [ ] `flutter run -d chrome` (verify camera preview renders and permission prompt appears).

