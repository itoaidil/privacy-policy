# Testing Flow Guide - Login sampai Bayar

## 🎯 Tujuan Testing
Menguji flow lengkap dari login hingga pembayaran Midtrans

---

## ✅ Persiapan

### 1. Build APK Sudah Selesai
File APK: `build/app/outputs/flutter-apk/app-release.apk`

### 2. Install ke HP Android
```bash
# Transfer via USB atau adb
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 3. Pastikan HP Terhubung Internet
- WiFi atau Data Seluler aktif
- Test buka browser, akses https://google.com

---

## 📝 Test Credentials

### Opsi 1: Gunakan Akun Existing
- **Email:** `a@gmail.com`
- **Password:** `123456`

### Opsi 2: Daftar Akun Baru
1. Klik "Daftar Akun Baru"
2. Isi form:
   - Nama Lengkap: (nama Anda)
   - Email: (email valid)
   - No HP: (nomor HP valid)
   - Password: minimal 6 karakter
3. Klik "Daftar"
4. Login dengan akun baru

---

## 🚀 Testing Flow Lengkap

### **STEP 1: Login** ✅
1. Buka aplikasi
2. Masukkan email & password
3. Klik "Masuk"
4. **Expected:** Masuk ke Dashboard
5. **If Error:** 
   - Tunggu 30-60 detik (server Railway lambat)
   - Cek koneksi internet
   - Lihat error message yang muncul

---

### **STEP 2: Cari Travel** 🔍
1. Di Dashboard, pilih:
   - **Dari:** Jakarta
   - **Ke:** Bandung
   - **Tanggal:** (pilih tanggal hari ini atau besok)
2. Klik "Cari Travel"
3. **Expected:** Muncul list PO/Travel yang tersedia
4. **If Error:** Tidak ada jadwal → pilih tanggal lain

---

### **STEP 3: Pilih Travel & Jadwal** 🚌
1. Pilih salah satu PO dari list
2. **Expected:** Muncul detail PO & jadwal keberangkatan
3. Pilih salah satu jadwal
4. Klik "Pilih Jadwal"

---

### **STEP 4: Pilih Kursi** 💺
1. Muncul tampilan kursi bus
2. Pilih kursi yang tersedia (warna hijau)
3. **Kursi yang sudah dipesan** akan berwarna merah/grey (tidak bisa dipilih)
4. Klik kursi → akan berubah warna (selected)
5. Bisa pilih multiple kursi
6. Klik "Lanjutkan" atau "Next"

---

### **STEP 5: Isi Data Penumpang** 👤
1. Isi form:
   - Nama penumpang
   - No HP
   - Email
   - Titik Jemput (optional)
   - Titik Antar (optional)
2. Klik "Lanjutkan"

---

### **STEP 6: Review & Konfirmasi** ✓
1. Review data booking:
   - Rute perjalanan
   - Jadwal
   - Kursi yang dipilih
   - Total harga
2. Pilih metode pembayaran: **Midtrans**
3. Klik "Booking Sekarang"
4. **Expected:** Booking berhasil dibuat
5. **If Error:** 
   - Kursi sudah dipesan orang lain → pilih kursi lain
   - Timeout → tunggu & coba lagi

---

### **STEP 7: Pembayaran Midtrans** 💳

#### 7.1 Redirect ke Midtrans
1. Setelah booking berhasil, otomatis redirect ke **Midtrans Payment Page**
2. **Expected:** Muncul halaman pembayaran Midtrans dengan:
   - Order ID
   - Total pembayaran
   - Metode pembayaran tersedia

#### 7.2 Pilih Metode Pembayaran
Midtrans menyediakan berbagai metode:
- **Kartu Kredit/Debit**
- **Bank Transfer** (BCA, Mandiri, BNI, BRI, Permata)
- **E-Wallet** (GoPay, ShopeePay, QRIS)
- **Alfamart/Indomaret**

#### 7.3 Testing dengan Sandbox (Test Mode)
Karena ini masih development, gunakan **test credentials**:

##### Test Credit Card:
```
Card Number: 4811 1111 1111 1114
CVV: 123
Exp Date: 01/25
OTP/3DS: 112233
```

##### Test Bank Transfer:
- Pilih bank (misal: BCA)
- Akan muncul nomor Virtual Account
- Gunakan simulator bank di Midtrans dashboard

##### Test GoPay:
- Pilih GoPay
- Scan QR code dengan GoPay Simulator

#### 7.4 Selesaikan Pembayaran
1. Ikuti instruksi pembayaran
2. Dalam test mode, pembayaran akan langsung berhasil
3. **Expected:** Redirect kembali ke aplikasi
4. Status booking berubah: **Pending → Paid**

---

### **STEP 8: Cek Riwayat Booking** 📋
1. Kembali ke Dashboard
2. Buka menu "Riwayat Booking" / "Profile"
3. **Expected:** Muncul list booking yang sudah dibuat
4. Status pembayaran: **Paid** (jika sudah bayar)

---

## ⚠️ Troubleshooting

### Error: "Koneksi timeout"
**Penyebab:** Server Railway lambat (10-60 detik)
**Solusi:** 
- Tunggu lebih lama
- Coba lagi
- Pastikan koneksi internet stabil

### Error: "Kursi sudah dipesan"
**Penyebab:** Orang lain pesan kursi yang sama
**Solusi:** Pilih kursi lain yang tersedia

### Error: "Gagal terhubung ke server"
**Penyebab:** Koneksi internet bermasalah
**Solusi:**
- Cek koneksi WiFi/Data
- Coba matikan & hidupkan lagi
- Test buka browser

### Error: "Login gagal" / "Email atau password salah"
**Penyebab:** Credentials salah atau akun belum terdaftar
**Solusi:**
- Cek email & password
- Atau daftar akun baru

### Payment Page Tidak Muncul
**Penyebab:** Midtrans integration belum setup
**Solusi:**
- Cek Midtrans configuration di backend
- Cek environment variables Railway

---

## 📊 Expected Results

### ✅ Success Flow:
1. ✓ Login berhasil
2. ✓ Bisa cari travel
3. ✓ Bisa pilih jadwal & kursi
4. ✓ Booking berhasil dibuat
5. ✓ Redirect ke Midtrans
6. ✓ Pembayaran berhasil
7. ✓ Status booking terupdate
8. ✓ Muncul di riwayat booking

### ⏱️ Performance Expected:
- Login: 5-15 detik (Railway cold start)
- Search: 3-10 detik
- Booking: 5-15 detik
- Payment redirect: 2-5 detik

---

## 🐛 Report Issues

Jika menemukan masalah, catat:
1. **Step berapa** error terjadi
2. **Error message** yang muncul
3. **Screenshot** (jika perlu)
4. **Waktu** error (untuk cek log)

---

## 📞 Support

Jika butuh bantuan:
- Cek `LOGIN_TROUBLESHOOTING.md` untuk masalah login
- Cek log di Railway dashboard untuk backend issues
- Check Midtrans dashboard untuk payment issues

---

**Good Luck Testing! 🚀**

Last Updated: 2025-11-20
