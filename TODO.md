# Fix Image Path & Deployment Issues

## Steps
- [x] 1. Delete `assets/assets/` directory (contains empty `featured_echo_1.jpeg`)
- [x] 2. Edit `pubspec.yaml` - remove `- assets/assets/` line
- [x] 3. Edit `Dockerfile` - add `RUN chmod -R a+rX /usr/share/nginx/html`
- [ ] 4. Run `flutter clean && flutter pub get && flutter build web --release`
- [ ] 5. Commit and push to main branch

