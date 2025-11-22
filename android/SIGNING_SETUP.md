CREATE TABLE IF NOT EXISTS customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  password VARCHAR(255) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (email),
  INDEX (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;# Android Release Signing Setup

## Option 1: Using key.properties (Recommended for local builds)

1. Create upload keystore (run once):
```bash
keytool -genkeypair -v -keystore ~/upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -dname "CN=Your Name, OU=Your Unit, O=Your Org, L=City, ST=State, C=CountryCode"
```

2. Create `android/key.properties` (NEVER commit this):
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/Users/YOUR_USERNAME/upload-keystore.jks
```

3. Add to `.gitignore`:
```
android/key.properties
*.jks
*.keystore
```

## Option 2: Using Gradle properties (for CI/CD)

Add to `~/.gradle/gradle.properties`:
```properties
MYAPP_UPLOAD_STORE_FILE=/Users/YOUR_USERNAME/upload-keystore.jks
MYAPP_UPLOAD_KEY_ALIAS=upload
MYAPP_UPLOAD_STORE_PASSWORD=your-store-password
MYAPP_UPLOAD_KEY_PASSWORD=your-key-password
```

## Build Release AAB

Development build (local API):
```bash
cd travel_booking_app
flutter build appbundle --release
```

Production build (Railway API):
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Test APK (optional)

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api
```

Output: `build/app/outputs/flutter-apk/app-release.apk`
