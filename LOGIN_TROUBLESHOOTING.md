# Troubleshooting Login Issues

## Masalah: Tidak Bisa Login - Connection Abort Error

### Error yang Muncul
```
Exception: Error: ClientException: Software caused connection abort, 
uri=https://travel-api-production-23ae.up.railway.app/api/customer/login
```

### Penyebab Umum
1. **Network Security Configuration** - Android memblokir koneksi HTTPS
2. **SSL Certificate Issues** - Masalah dengan sertifikat SSL
3. **Timeout** - Request terlalu lama
4. **Backend Server Down** - API tidak merespon

---

## Solusi yang Sudah Diterapkan

### ✅ 1. Network Security Configuration
File: `android/app/src/main/res/xml/network_security_config.xml`

Menambahkan konfigurasi untuk mengizinkan koneksi ke Railway.app:
- Trust system certificates
- Allow connections to railway.app domains
- Enable cleartext traffic untuk debugging

### ✅ 2. Update AndroidManifest.xml
File: `android/app/src/main/AndroidManifest.xml`

Menambahkan:
- `android:networkSecurityConfig="@xml/network_security_config"`
- `android:usesCleartextTraffic="true"`

### ✅ 3. Improved API Error Handling
File: `lib/services/api_service.dart`

- Menambahkan timeout 30 detik
- Better error messages
- Logging untuk debugging
- ClientException handling khusus

### ✅ 4. Better Error Display
File: `lib/screens/auth/login_screen.dart`

- Clean error messages
- Longer duration untuk error display (5 seconds)

---

## Cara Testing Setelah Perubahan

### 1. Clean & Rebuild App
```bash
cd /Volumes/SSD_PORTABLE/Projects/travel_booking_app

# Clean flutter cache
flutter clean

# Get dependencies
flutter pub get

# Rebuild app
flutter build apk --release
# atau untuk development
flutter run
```

### 2. Test Credentials
Gunakan akun yang sudah terdaftar:
- Email: `a@gmail.com`
- Password: `123456`

Atau daftar akun baru terlebih dahulu.

### 3. Check Logs
Saat testing, perhatikan log di console untuk melihat:
- URL yang dipanggil
- Response status code
- Error messages detail

---

## Jika Masih Tidak Bisa Login

### A. Cek Koneksi Internet
```bash
# Ping ke Railway
ping travel-api-production-23ae.up.railway.app
```

### B. Test API Langsung
```bash
# Test health endpoint
curl https://travel-api-production-23ae.up.railway.app/health

# Test login endpoint
curl -X POST https://travel-api-production-23ae.up.railway.app/api/customer/login \
  -H "Content-Type: application/json" \
  -d '{"email":"a@gmail.com","password":"123456"}'
```

### C. Cek Railway Dashboard
1. Login ke https://railway.app
2. Buka project: travel-api-production
3. Cek status deployment
4. Lihat logs untuk error

### D. Cek Database
Pastikan customer sudah terdaftar di database:
```sql
SELECT * FROM customers WHERE email = 'a@gmail.com';
```

### E. Test dengan Emulator Lain
- Coba di device fisik
- Coba di emulator yang berbeda
- Coba di iOS (jika ada)

---

## Alternative Solutions

### 1. Use Local API for Development
Update `lib/config/app_config.dart`:
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api', // Android emulator
  // defaultValue: 'http://localhost:3000/api', // iOS simulator
);
```

Jalankan API lokal:
```bash
cd /Volumes/SSD_PORTABLE/Projects/travel_api
npm start
```

### 2. Enable More Logging
Tambahkan di `main.dart`:
```dart
void main() {
  // Enable more detailed HTTP logging
  HttpClient.enableTimelineLogging = true;
  runApp(const MyApp());
}
```

### 3. Add Proxy (Untuk Development)
Install Charles Proxy atau Postman Proxy untuk melihat detail request/response.

---

## Contact Backend Team

Jika masalah persisten, kontak backend developer untuk:
1. Cek status server Railway
2. Cek database connection
3. Cek logs di Railway dashboard
4. Verify customer data di database

---

## Checklist Troubleshooting

- [ ] Flutter clean & rebuild
- [ ] Test dengan credentials yang benar
- [ ] Cek koneksi internet
- [ ] Test API endpoint dengan curl
- [ ] Cek Railway dashboard & logs
- [ ] Cek database records
- [ ] Test di device fisik
- [ ] Try local API
- [ ] Enable detailed logging
- [ ] Contact backend team

---

**Last Updated:** 2025-11-20
