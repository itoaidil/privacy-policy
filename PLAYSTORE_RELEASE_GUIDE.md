# Travel Booking App - Play Store Release Guide

## 🎯 Overview

App siap untuk dipublish ke Google Play Store. Backend API sudah live di Railway.

**Production API:** `https://travel-api-production-23ae.up.railway.app`

## ✅ Persiapan Selesai

- [x] API Base URL environment-aware
- [x] Android signing configuration
- [x] INTERNET permission
- [x] Build scripts & automation
- [x] .gitignore untuk keystore
- [x] Documentation lengkap

## 🔑 Step 1: Buat Upload Keystore (Sekali Saja)

```bash
keytool -genkeypair -v -keystore ~/upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -dname "CN=Your Name, OU=Dev, O=Your Company, L=Jakarta, ST=Jakarta, C=ID"
```

Simpan password yang Anda buat - jangan sampai hilang!

## 🔐 Step 2: Configure Signing

### Cara A: File key.properties (Recommended untuk lokal)

Buat file `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password  
keyAlias=upload
storeFile=/Users/YOUR_USERNAME/upload-keystore.jks
```

**PENTING:** File ini sudah di `.gitignore` - jangan commit!

### Cara B: Gradle properties (Untuk CI/CD)

Tambahkan ke `~/.gradle/gradle.properties`:

```properties
MYAPP_UPLOAD_STORE_FILE=/Users/YOUR_USERNAME/upload-keystore.jks
MYAPP_UPLOAD_KEY_ALIAS=upload
MYAPP_UPLOAD_STORE_PASSWORD=your-password
MYAPP_UPLOAD_KEY_PASSWORD=your-password
```

## 🏗️ Step 3: Build Release AAB

### Cara Mudah: Pakai Script

```bash
cd travel_booking_app
./build_release.sh
```

Pilih opsi 2 (Production) untuk Railway API.

### Cara Manual: Flutter Command

```bash
cd travel_booking_app
flutter clean
flutter pub get

# Production build dengan Railway API
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Test APK (Optional)

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Step 4: Google Play Console Setup

### 4.1 Buat App

1. Buka https://play.google.com/console
2. **Create app**
3. Isi:
   - App name: "Travel Booking App" (atau sesuai keinginan)
   - Default language: Indonesia
   - App/game: App
   - Free/Paid: Free

### 4.2 Store Listing

**Teks:**
- Short description (80 chars max)
- Full description (4000 chars max)
- App category: Maps & Navigation atau Travel & Local

**Grafis:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: Min 2, ukuran 1080x1920 atau device-native
  - Ambil screenshot dari emulator/device dengan app yang sudah jalan

**Kontak:**
- Email
- Website (optional)
- Phone (optional)

### 4.3 Privacy Policy

Upload file `privacy_policy.html` ke hosting (GitHub Pages, Vercel, atau lainnya).

Contoh GitHub Pages:
1. Push `privacy_policy.html` ke repo
2. Enable Pages di repo settings
3. URL: `https://USERNAME.github.io/REPO/privacy_policy.html`

Paste URL di Play Console.

### 4.4 App Content

**Content rating:**
- Isi questionnaire (pilih: Non-violent, No mature content, dll)
- Akan dapat rating seperti PEGI 3, Everyone, dll

**Data Safety:**
- Deklarasi data yang dikumpulkan:
  - Personal info: Name, Email, Phone
  - Location: User-selected pickup/dropoff (not precise)
  - Financial: Payment method info
- Purpose: Account creation, Booking service
- Data encrypted in transit: Yes
- Users can request deletion: Yes (via email)

**Ads:**
- Contains ads: No (jika tidak pakai ads)

**Target audience:**
- Age: 13+ atau All ages

**Government apps:**
- No (kecuali app pemerintah)

### 4.5 App Access

- All features available to all users: Yes
- Special access (SYSTEM_ALERT_WINDOW, etc): None

## 📤 Step 5: Upload & Testing

### 5.1 Internal Testing Track

1. Di Play Console → **Testing** → **Internal testing**
2. **Create new release**
3. Upload `app-release.aab`
4. Release notes (contoh):
   ```
   Version 1.0.0
   - Initial release
   - Book travel tickets
   - Select seats
   - Payment integration
   - Booking history
   ```
5. **Save** → **Review release** → **Start rollout to Internal testing**

### 5.2 Add Testers

1. **Testers** tab
2. **Create email list** atau gunakan Google Group
3. Add emails (min 1, bisa email sendiri)
4. Testers akan dapat link untuk install via Play Store

### 5.3 Test Installation

1. Tester buka link dari email
2. Accept invitation
3. Install app dari Play Store (Internal testing)
4. Test semua fitur:
   - Login/Register
   - Search PO
   - Book tickets
   - Payment
   - Booking history

### 5.4 Pre-launch Report

Play Console akan otomatis test app di berbagai device.
Check report untuk crash/ANR/compatibility issues.

## 🚀 Step 6: Production Release

Setelah internal testing OK:

### 6.1 Promote to Production

1. **Testing** → **Internal testing** → pilih release
2. **Promote release** → **Production**
3. Atau buat release baru di **Production** track

### 6.2 Staged Rollout (Recommended)

- Start dengan 10% users
- Monitor crashes/ANRs di Play Console
- Gradually increase: 10% → 25% → 50% → 100%

### 6.3 Release Notes

Tulis dalam Bahasa Indonesia dan English:

```
🎉 Versi 1.0.0

Fitur:
✅ Pemesanan tiket travel online
✅ Pilih kursi langsung
✅ Berbagai metode pembayaran
✅ Riwayat pemesanan
✅ Informasi PO & jadwal lengkap

---

🎉 Version 1.0.0

Features:
✅ Online travel ticket booking
✅ Direct seat selection  
✅ Multiple payment methods
✅ Booking history
✅ Complete PO & schedule information
```

## 🔄 Update App (Version 2.0.0+)

1. **Update code**
2. **Bump version** di `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 = versionName, +2 = versionCode
   ```
   - `versionCode` HARUS increment setiap upload
   - `versionName` untuk display (1.0.0, 1.0.1, 1.1.0, 2.0.0)

3. **Build new AAB**:
   ```bash
   ./build_release.sh
   ```

4. **Upload ke Play Console** (production atau testing track)

## 📊 Monitoring

Di Play Console dashboard:

- **Crashes & ANRs:** Fix ASAP
- **User ratings:** Respond to reviews
- **Statistics:** Install, uninstall, active users
- **Android vitals:** Performance metrics

## 🆘 Troubleshooting

### Build gagal: "Keystore not found"

Check path di `android/key.properties` atau Gradle properties.

### Upload ditolak: "Signature invalid"

Pastikan pakai signing config yang benar (bukan debug).

### App crash setelah install

1. Check logs di Play Console → **Android vitals**
2. Check ProGuard rules jika enable minifyEnabled
3. Test di berbagai Android versions (8+)

### API tidak connect

Verify Railway API masih running:
```bash
curl https://travel-api-production-23ae.up.railway.app/health
```

## 📚 Resources

- Play Console: https://play.google.com/console
- Flutter Deployment: https://docs.flutter.dev/deployment/android
- Android Signing: https://developer.android.com/studio/publish/app-signing
- Play Policy: https://play.google.com/about/developer-content-policy

## 🎯 Quick Commands Reference

```bash
# Build production AAB
./build_release.sh

# Or manual:
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api

# Build test APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api

# Run on device/emulator
flutter run --release \
  --dart-define=API_BASE_URL=https://travel-api-production-23ae.up.railway.app/api

# Check app size
flutter build appbundle --release --analyze-size

# Generate signing report
cd android && ./gradlew signingReport
```

---

**Good luck with your Play Store launch! 🚀**
