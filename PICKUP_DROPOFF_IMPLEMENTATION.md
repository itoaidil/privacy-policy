# Implementasi Fitur Pickup/Drop-off dengan Koordinat dan Validasi Radius

## Ringkasan
Fitur ini menambahkan kemampuan untuk menyimpan koordinat titik jemput dan antar ke database, dengan validasi bahwa titik tersebut harus berada dalam radius 50 km dari pusat kota yang dipilih.

## Komponen yang Diubah

### 1. Database Schema
**File**: `migrations/add_pickup_dropoff_coordinates.sql`
- Menambahkan 6 kolom baru ke tabel `bookings`:
  - `pickup_lat` (DECIMAL 10,8) - Latitude titik jemput
  - `pickup_lng` (DECIMAL 11,8) - Longitude titik jemput
  - `pickup_address` (TEXT) - Alamat lengkap titik jemput
  - `dropoff_lat` (DECIMAL 10,8) - Latitude titik antar
  - `dropoff_lng` (DECIMAL 11,8) - Longitude titik antar
  - `dropoff_address` (TEXT) - Alamat lengkap titik antar
- Menambahkan 2 index untuk optimasi query:
  - `idx_bookings_pickup` pada (pickup_lat, pickup_lng)
  - `idx_bookings_dropoff` pada (dropoff_lat, dropoff_lng)

**Status**: ✅ Migrasi berhasil dijalankan

### 2. Frontend (Flutter)

#### 2.1 Map Picker Screen
**File**: `lib/screens/map_picker_screen.dart`
- **Fitur Autocomplete**: Menggunakan `TypeAheadField` dengan Nominatim API
- **Validasi Radius**: 
  - Menyimpan koordinat pusat kota saat pencarian pertama kali
  - Menggunakan Haversine formula untuk menghitung jarak
  - Radius maksimal: 50 km
  - Mencegah pemilihan titik di luar radius
- **Dependencies**: 
  - `dart:math` (untuk cos, sin, sqrt, atan2, pi)
  - `flutter_typeahead` untuk autocomplete
  - `flutter_map` untuk menampilkan peta
  - `http` untuk API calls ke Nominatim

#### 2.2 Home Screen
**File**: `lib/screens/home_screen.dart`
- Mengirim 4 parameter baru ke `PODetailScreen`:
  - `pickupCoord` (Map<String, double>?) - {'lat': ..., 'lng': ...}
  - `pickupAddress` (String?)
  - `dropoffCoord` (Map<String, double>?)
  - `dropoffAddress` (String?)
- Kedua titik navigasi diupdate (pencarian awal dan dari list)

#### 2.3 PO Detail Screen
**File**: `lib/screens/po_detail_screen.dart`
- Menerima 4 parameter koordinat dari `HomeScreen`
- Meneruskan parameter ke `SeatSelectionScreen`

#### 2.4 Seat Selection Screen
**File**: `lib/screens/seat_selection_screen.dart`
- Menerima 4 parameter koordinat dari `PODetailScreen`
- Meneruskan parameter ke `PaymentScreen`

#### 2.5 Payment Screen
**File**: `lib/screens/payment_screen.dart`
- Menerima 4 parameter koordinat dari `SeatSelectionScreen`
- Mengirim koordinat ke API saat membuat booking

#### 2.6 API Service
**File**: `lib/services/api_service.dart`
- Method `createCustomerBooking` diupdate dengan 6 parameter baru:
  - `pickupLat` (double?)
  - `pickupLng` (double?)
  - `pickupAddress` (String?)
  - `dropoffLat` (double?)
  - `dropoffLng` (double?)
  - `dropoffAddress` (String?)

### 3. Backend (Node.js/Express)

#### 3.1 Customer Routes
**File**: `routes/customerRoutes.js`
- Endpoint `POST /customer/booking` diupdate
- Menerima 6 field baru dari request body
- INSERT query mencakup semua kolom koordinat

#### 3.2 Student Routes
**File**: `routes/studentRoutes.js`
- Endpoint `POST /bookings` diupdate (sudah dilakukan sebelumnya)
- Sama seperti customer routes

## Alur Data

```
HomeScreen
  ├─> User pilih kota asal/tujuan
  ├─> User tap ikon map untuk pilih titik jemput
  │    └─> MapPickerScreen
  │         ├─> Tampilkan peta dengan center di kota
  │         ├─> Simpan koordinat pusat kota (_cityCenter)
  │         ├─> User ketik/pilih lokasi dengan autocomplete (Nominatim)
  │         ├─> User tap pada peta untuk pilih titik
  │         └─> Validasi: jarak <= 50km dari pusat kota
  │              └─> Return {lat, lng} + address string
  │
  ├─> User tap ikon map untuk pilih titik antar
  │    └─> (proses sama seperti di atas)
  │
  ├─> User pilih PO dari list
  └─> Navigator.push ke PODetailScreen dengan:
       - pickupCoord: Map<String, double>?
       - pickupAddress: String?
       - dropoffCoord: Map<String, double>?
       - dropoffAddress: String?

PODetailScreen
  └─> Navigator.push ke SeatSelectionScreen
       (meneruskan 4 parameter koordinat)

SeatSelectionScreen
  └─> Navigator.push ke PaymentScreen
       (meneruskan 4 parameter koordinat)

PaymentScreen
  └─> ApiService.createCustomerBooking()
       - Mengirim semua data booking + 6 field koordinat

ApiService
  └─> HTTP POST ke /customer/booking
       Body: {
         customer_id, travel_id, selected_seats,
         payment_method, total_price,
         pickup_location, dropoff_location,
         pickup_lat, pickup_lng, pickup_address,
         dropoff_lat, dropoff_lng, dropoff_address
       }

Backend (Node.js)
  └─> routes/customerRoutes.js
       └─> POST /booking
            ├─> Validasi input
            ├─> Begin transaction
            ├─> Check seat availability
            ├─> INSERT INTO bookings dengan 6 kolom koordinat
            ├─> INSERT INTO booking_seats
            ├─> Commit transaction
            └─> Return booking_id

Database (MySQL)
  └─> Tabel bookings sekarang menyimpan:
       - pickup_lat, pickup_lng, pickup_address
       - dropoff_lat, dropoff_lng, dropoff_address
```

## Validasi Radius (Haversine Formula)

```dart
double _calculateDistance(ll.LatLng point1, ll.LatLng point2) {
  const double earthRadius = 6371; // km
  
  final lat1 = point1.latitude * pi / 180;
  final lat2 = point2.latitude * pi / 180;
  final dLat = (point2.latitude - point1.latitude) * pi / 180;
  final dLon = (point2.longitude - point1.longitude) * pi / 180;

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}
```

Formula ini menghitung jarak "great circle" antara dua titik di permukaan bumi dengan akurat.

## Konfigurasi Radius
- **Radius maksimal**: 50 km
- **Lokasi**: `lib/screens/map_picker_screen.dart`
- **Constant**: `_maxRadiusKm = 50.0`
- Dapat disesuaikan dengan mengganti nilai constant

## API Eksternal yang Digunakan

### Nominatim (OpenStreetMap)
- **Base URL**: https://nominatim.openstreetmap.org
- **Endpoints**:
  - `/search` - Forward geocoding (text → koordinat)
  - `/reverse` - Reverse geocoding (koordinat → text)
- **Headers**: User-Agent diperlukan
- **Rate Limit**: 1 request/detik (untuk penggunaan gratis)
- **Tidak memerlukan API key**

## Testing

### End-to-End Flow
1. Buka HomeScreen
2. Pilih kota asal dan tujuan
3. Tap ikon map di samping kota asal
4. Ketik lokasi di search box (autocomplete muncul)
5. Pilih lokasi dari suggestions atau tap di peta
6. Pastikan titik berada dalam radius 50km (jika tidak, akan muncul dialog error)
7. Ulangi untuk titik antar
8. Pilih PO dari list
9. Pilih kursi
10. Lanjut ke pembayaran
11. Selesaikan booking
12. Check database: `SELECT * FROM bookings WHERE id = [booking_id]`
13. Verifikasi kolom pickup_lat, pickup_lng, pickup_address, dropoff_lat, dropoff_lng, dropoff_address terisi

### Query untuk Verifikasi
```sql
SELECT 
  id, 
  booking_code,
  pickup_lat, 
  pickup_lng, 
  pickup_address,
  dropoff_lat, 
  dropoff_lng, 
  dropoff_address
FROM bookings
WHERE id = [BOOKING_ID];
```

## Troubleshooting

### Koordinat tidak tersimpan di database
- Pastikan migrasi sudah dijalankan: `node migrations/run_pickup_dropoff_migration.js`
- Check kolom ada di tabel: `SHOW COLUMNS FROM bookings LIKE '%pickup%';`
- Check log server: apakah ada error saat INSERT?

### Validasi radius tidak bekerja
- Pastikan `_cityCenter` terisi saat search pertama kali
- Check console log untuk debug jarak yang dihitung
- Pastikan import `dart:math` dengan fungsi cos, sin, sqrt, atan2, pi

### Autocomplete tidak muncul
- Check koneksi internet
- Check console untuk error dari Nominatim API
- Pastikan User-Agent header dikirim dalam request
- Rate limit: maksimal 1 request/detik

## Keamanan & Performa

1. **Database Indexes**: Ditambahkan index pada pickup_lat/lng dan dropoff_lat/lng untuk optimasi query geospasial
2. **Nullable Columns**: Semua kolom koordinat bersifat optional (NULL allowed) untuk backward compatibility
3. **Transaction**: Semua INSERT menggunakan transaction untuk data integrity
4. **Validation**: Radius validation di client-side (Flutter) sebelum submit
5. **Data Types**: DECIMAL untuk koordinat (presisi tinggi), TEXT untuk alamat

## Pengembangan Selanjutnya

1. **Geofencing**: Tambah polygon/area yang lebih spesifik selain radius circular
2. **Routing**: Integkan dengan routing API untuk estimasi waktu tempuh
3. **Maps Provider**: Tambah opsi Google Maps sebagai alternatif OpenStreetMap
4. **Saved Locations**: Simpan lokasi favorit user untuk quick access
5. **Admin Dashboard**: Tampilan peta untuk melihat semua pickup/dropoff points
6. **Driver App**: Navigasi otomatis ke titik jemput berdasarkan koordinat

## Dependencies Baru

### Flutter
```yaml
dependencies:
  flutter_typeahead: ^4.8.0  # Autocomplete field
```

### Node.js
Tidak ada dependency baru, menggunakan library existing (mysql, express)

## Dokumentasi API

### POST /customer/booking
**Request Body**:
```json
{
  "customer_id": 1,
  "travel_id": 123,
  "selected_seats": [1, 2],
  "payment_method": "bca",
  "total_price": 200000,
  "pickup_location": "Jakarta",
  "dropoff_location": "Bandung",
  "pickup_lat": -6.2088,
  "pickup_lng": 106.8456,
  "pickup_address": "Jl. Sudirman No. 1, Jakarta Pusat",
  "dropoff_lat": -6.9175,
  "dropoff_lng": 107.6191,
  "dropoff_address": "Jl. Asia Afrika No. 8, Bandung"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": "Booking berhasil dibuat",
  "data": {
    "booking_id": 456,
    "customer_id": 1,
    "travel_id": 123,
    "selected_seats": [1, 2],
    "num_passengers": 2,
    "total_price": 200000,
    "payment_method": "bca",
    "status": "pending"
  }
}
```

## Kesimpulan

Implementasi lengkap dari validasi radius hingga penyimpanan koordinat ke database telah selesai. Fitur ini memberikan:
- ✅ User experience yang lebih baik dengan autocomplete
- ✅ Validasi otomatis untuk memastikan titik jemput/antar dalam area layanan
- ✅ Data koordinat tersimpan di database untuk analisis dan tracking
- ✅ Backward compatible (kolom optional, tidak break existing bookings)
- ✅ No build errors, siap untuk testing dan deployment

**Status**: ✅ Selesai dan siap digunakan
