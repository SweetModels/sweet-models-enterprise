# Deployment Notes

## Artifacts
- Android APK: `mobile_app/build/app/outputs/flutter-apk/app-release.apk`
- Web bundle: `mobile_app/build/web`
- Backend (release binary via cargo): build with `cargo build --release` in `backend_api`

## Android publish (Play Console)
1. Sign with your keystore (example):
   ```powershell
   cd "c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app"
   & "$Env:JAVA_HOME\bin\jarsigner.exe" -verbose -sigalg SHA256withRSA -digestalg SHA-256 `
     -keystore "<path-to-keystore>.jks" build\app\outputs\flutter-apk\app-release.apk <key-alias>
   ```
2. Align/optimize (if using older toolchain):
   ```powershell
   & "<path-to-zipalign.exe>" -v 4 build\app\outputs\flutter-apk\app-release.apk app-release-aligned.apk
   ```
3. Upload to Play Console internal testing track.

## Web deploy (static hosting)
- Any static host works. Example (Nginx copy):
  ```bash
  rsync -avz mobile_app/build/web/ user@server:/var/www/sweetmodels/
  ```
- Or Firebase Hosting:
  ```bash
  firebase login
  firebase init hosting  # select existing project
  firebase deploy --only hosting
  ```

## iOS build (requires macOS + Xcode)
1. On macOS, install deps: `brew install cocoapods` if missing.
2. In `mobile_app`:
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter build ios --release
   ```
3. Open `ios/Runner.xcworkspace` in Xcode to archive and upload via Organizer.

## Firebase config placement
- Android: place `google-services.json` at `mobile_app/android/app/google-services.json` and ensure `com.google.gms.google-services` plugin is applied (already in project if using FCM).
- iOS: place `GoogleService-Info.plist` at `mobile_app/ios/Runner/GoogleService-Info.plist` and add to Xcode project if missing.

## Backend (Rust) run/deploy
- Local run (release):
  ```powershell
  cd "c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\backend_api"
  cargo build --release
  .\target\release\backend_api.exe
  ```
- Container: build/push with Dockerfile in `backend_api` as needed.

## Warnings to track
- Flutter: remaining analyzer infos (style/const). Not blocking builds.
- Rust: redis/sqlx-postgres emit future-compat warnings; consider updating versions when convenient.
