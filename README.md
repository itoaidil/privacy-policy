# Travel Booking App

Aplikasi pemesanan travel mobil berbasis Flutter untuk memudahkan pengguna mencari dan memesan travel berdasarkan rute perjalanan.

## Fitur

- 🔍 Pencarian travel berdasarkan tempat berangkat dan tujuan
- 📋 Daftar PO (Perusahaan Otobus) yang tersedia
- 📝 Form booking dengan validasi
- 💰 Perhitungan harga otomatis
- 📅 Pemilihan tanggal keberangkatan
- 📱 UI yang responsive dan user-friendly

## Screenshot

### Home Screen
Halaman utama dengan form pencarian rute travel

### Search Result Screen
Menampilkan daftar PO yang tersedia untuk rute yang dipilih

### Booking Screen
Form pemesanan dengan detail harga dan informasi lengkap

## Teknologi

- **Flutter**: Framework utama
- **Provider**: State management
- **HTTP**: Komunikasi dengan API
- **Intl**: Format mata uang dan tanggal

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/
│   ├── po_model.dart        # Model data PO
│   └── booking_model.dart   # Model data booking
├── providers/
│   └── travel_provider.dart # State management
├── services/
│   └── api_service.dart     # API service layer
└── screens/
    ├── home_screen.dart            # Halaman utama
    ├── search_result_screen.dart   # Halaman hasil pencarian
    └── booking_screen.dart         # Halaman booking
```

## Setup Backend API

Aplikasi ini membutuhkan backend API. Pastikan Anda sudah membuat backend dengan endpoint berikut:

### Endpoints yang dibutuhkan:

1. **GET /api/po/search?from={tempat_berangkat}&to={tujuan}**
   - Mencari PO berdasarkan rute
   - Response: Array of PO objects

2. **GET /api/po**
   - Mendapatkan semua PO
   - Response: Array of PO objects

3. **POST /api/booking**
   - Membuat booking baru
   - Request body: Booking object
   - Response: Created booking object

4. **GET /api/cities** (Optional)
   - Mendapatkan daftar kota
   - Response: Array of city names

### Format Data PO:
```json
{
  "id": 1,
  "nama": "Travel ABC",
  "tempat_berangkat": "Jakarta",
  "tujuan": "Bandung",
  "jam_keberangkatan": "08:00",
  "harga": 150000,
  "kapasitas": 7,
  "nomor_telepon": "081234567890",
  "jenis_kendaraan": "Avanza"
}
```

### Format Data Booking:
```json
{
  "po_id": 1,
  "nama_penumpang": "John Doe",
  "nomor_telepon": "081234567890",
  "jumlah_penumpang": 2,
  "tanggal_keberangkatan": "2025-11-20",
  "total_harga": 300000,
  "status": "pending"
}
```

## Instalasi

1. Clone repository atau ekstrak file project

2. Buka terminal di folder project

3. Install dependencies:
```bash
flutter pub get
```

4. Konfigurasi URL API di `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-api-url.com/api';
```

Untuk testing lokal, gunakan:
- Android Emulator: `http://10.0.2.2:8000/api`
- iOS Simulator: `http://localhost:8000/api`
- Physical Device: `http://192.168.x.x:8000/api` (ganti dengan IP komputer Anda)

5. Jalankan aplikasi:
```bash
flutter run
```

## Cara Menggunakan

1. **Pilih Rute**
   - Buka aplikasi
   - Pilih tempat berangkat dari dropdown
   - Pilih tujuan dari dropdown
   - Tap tombol "Cari Travel"

2. **Pilih PO**
   - Lihat daftar PO yang tersedia
   - Tap pada card PO untuk melihat detail
   - Tap "Pesan Sekarang" untuk lanjut booking

3. **Booking**
   - Isi nama lengkap
   - Isi nomor telepon
   - Pilih jumlah penumpang
   - Pilih tanggal keberangkatan
   - Review total harga
   - Tap "Konfirmasi Booking"

## Kustomisasi

### Mengubah Warna Tema
Edit di `lib/main.dart`:
```dart
theme: ThemeData(
  primarySwatch: Colors.blue, // Ganti warna di sini
  useMaterial3: true,
),
```

### Menambah Validasi
Edit form validator di file screen yang sesuai

### Mengubah Format Mata Uang
Edit di file screen yang menggunakan `NumberFormat`:
```dart
final currencyFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
```

## Troubleshooting

### Error koneksi ke API
- Pastikan backend API sudah berjalan
- Periksa URL di `api_service.dart`
- Untuk testing di device fisik, pastikan device dan komputer terhubung ke jaringan yang sama

### UI tidak muncul dengan benar
- Jalankan `flutter clean`
- Jalankan `flutter pub get`
- Restart aplikasi

### Error saat build
- Pastikan Flutter SDK sudah terinstall dengan benar
- Jalankan `flutter doctor` untuk cek masalah

## Pengembangan Lebih Lanjut

Fitur yang bisa ditambahkan:
- [ ] Authentication & Authorization
- [ ] Riwayat booking
- [ ] Rating & Review PO
- [ ] Notifikasi push
- [ ] Payment gateway integration
- [ ] Chat dengan PO
- [ ] Real-time tracking
- [ ] Multiple language support

## License

MIT License

## Kontak

Jika ada pertanyaan atau masalah, silakan buat issue di repository ini.
