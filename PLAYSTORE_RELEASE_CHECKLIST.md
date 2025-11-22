# Play Store Release Checklist (Flutter)

Use this checklist to prepare and publish the app now that the API is live.

## 1) Wire Production API URL
- In code, read env at compile time:
  ```dart
  const apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  ```
- Build with prod URL:
  ```bash
  flutter pub get
  flutter build appbundle --release \
    --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app
  ```

## 2) Version & Branding
- `pubspec.yaml` → bump `version: x.y.z+code`
- App name: `android/app/src/main/AndroidManifest.xml` or `res/values/strings.xml`
- Icons via `flutter_launcher_icons` if needed
- Ensure `INTERNET` permission in AndroidManifest

## 3) App Signing (Upload Key)
- Create keystore once:
  ```bash
  keytool -genkeypair -v -keystore ~/upload-keystore.jks -storetype JKS \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- Add secrets (recommended global): `~/.gradle/gradle.properties`
  ```properties
  MYAPP_UPLOAD_STORE_FILE=/Users/$USER/upload-keystore.jks
  MYAPP_UPLOAD_KEY_ALIAS=upload
  MYAPP_UPLOAD_STORE_PASSWORD=your-store-pass
  MYAPP_UPLOAD_KEY_PASSWORD=your-key-pass
  ```
- Wire signing in `android/app/build.gradle.kts` (signingConfigs + buildTypes.release)

## 4) Build Release AAB
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## 5) Google Play Console
- Create app entry
- Store listing: icon 512×512, feature 1024×500, screenshots
- Privacy Policy URL (use hosted `privacy_policy.html`)
- Content rating, Data Safety, category, contact

## 6) Internal Testing → Production
- Upload AAB to Internal testing
- Add testers, roll out, verify install
- Promote to Open testing or Production with staged rollout

## Quick Test Endpoints
- Health: `/health`
- Vehicles by PO: `/api/po/1/vehicles`

---
Update this checklist as you release new versions.