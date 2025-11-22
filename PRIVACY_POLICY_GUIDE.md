# Panduan Privacy Policy & Data Safety untuk Google Play Store

## ✅ File yang Sudah Dibuat

1. **PRIVACY_POLICY.md** - Versi Markdown untuk dokumentasi
2. **privacy_policy.html** - Versi HTML untuk di-host online

## 📝 Langkah Selanjutnya

### Langkah 1: Edit Kontak Informasi

Buka file `privacy_policy.html` dan ganti bagian berikut dengan info Anda:

```html
<!-- Cari bagian "Contact Us" dan ganti: -->
<li><strong>Email:</strong> your-email@example.com</li>
<li><strong>Phone:</strong> +62 xxx-xxxx-xxxx</li>
<li><strong>Address:</strong> [Your Business Address]</li>
```

Ganti dengan:
- Email: Email resmi Anda (contoh: support@travelbooking.com)
- Phone: Nomor WhatsApp/HP Anda
- Address: Alamat kantor/domisili Anda

### Langkah 2: Host Privacy Policy Online (Pilih salah satu)

#### Opsi A: GitHub Pages (Gratis & Mudah) ⭐ RECOMMENDED

1. Buka https://github.com
2. Login dengan akun GitHub Anda
3. Klik "New Repository"
   - Nama: `privacy-policy`
   - Public
   - Centang "Add a README file"
4. Klik "Create repository"
5. Upload file `privacy_policy.html`:
   - Klik "Add file" → "Upload files"
   - Drag & drop `privacy_policy.html`
   - Commit changes
6. Aktifkan GitHub Pages:
   - Settings → Pages
   - Source: Deploy from a branch
   - Branch: main → / (root)
   - Save
7. URL Privacy Policy Anda:
   ```
   https://[username-github].github.io/privacy-policy/privacy_policy.html
   ```

#### Opsi B: Vercel (Gratis)

1. Buka https://vercel.com
2. Login dengan GitHub
3. Import repository privacy-policy
4. Deploy
5. URL: `https://privacy-policy-[random].vercel.app`

#### Opsi C: Railway (Jika sudah pakai Railway untuk backend)

1. Buat folder `public` di project backend
2. Copy `privacy_policy.html` ke `public/`
3. Deploy
4. URL: `https://[your-app].railway.app/privacy_policy.html`

### Langkah 3: Isi Data Safety Form di Google Play Console

Setelah punya URL Privacy Policy, login ke Play Console dan isi:

#### Data Safety Section

**1. Does your app collect or share any of the required user data types?**
- ✅ Yes

**2. Is all of the user data collected by your app encrypted in transit?**
- ✅ Yes

**3. Do you provide a way for users to request that their data is deleted?**
- ✅ Yes (via email contact)

**4. Data types collected:**

**Personal info:**
- ☑ Name (Required for booking)
- ☑ Email address (For confirmation & account)
- ☑ Phone number (For contact)

**Financial info:**
- ☑ Purchase history (Booking records)
- ⚠️ JANGAN centang "Payment info" karena tidak simpan kartu kredit

**App activity:**
- ☑ App interactions (Booking activity)

**5. For each data type, specify:**

**Name:**
- Collected: Yes
- Shared: No
- Ephemeral: No
- Required: Yes
- Purpose: App functionality (Booking identification)

**Email:**
- Collected: Yes
- Shared: No
- Ephemeral: No
- Required: Yes
- Purpose: App functionality (Booking confirmation)

**Phone:**
- Collected: Yes
- Shared: No
- Ephemeral: No
- Required: Yes
- Purpose: App functionality (Contact for booking)

**Purchase history:**
- Collected: Yes
- Shared: No
- Ephemeral: No
- Required: No (Optional: bisa lihat riwayat atau tidak)
- Purpose: App functionality (Booking management)

**6. Privacy Policy URL:**
Paste URL dari GitHub Pages/Vercel Anda:
```
https://[username].github.io/privacy-policy/privacy_policy.html
```

## ✅ Checklist Sebelum Submit

- [ ] Privacy Policy URL sudah online dan bisa diakses
- [ ] Kontak info sudah diganti (email, phone, address)
- [ ] Data Safety form sudah diisi lengkap
- [ ] Semua jawaban konsisten dengan Privacy Policy
- [ ] Test URL Privacy Policy di browser (buka linknya)

## 📌 Catatan Penting

1. **URL Privacy Policy WAJIB:**
   - Bisa diakses public
   - Tidak perlu login
   - Tidak boleh 404 error

2. **Data Safety vs Privacy Policy:**
   - Harus konsisten
   - Jangan bilang "collect" di Data Safety tapi tidak disebutkan di Privacy Policy

3. **Update di Masa Depan:**
   - Jika ada perubahan, update Privacy Policy
   - Update juga Data Safety form
   - Ganti tanggal "Last updated"

## 🎯 Setelah Privacy Policy Selesai

Selanjutnya Anda perlu:
1. ✅ Privacy Policy (DONE - tinggal host)
2. ⏳ Build APK/AAB dengan signing (Next step)
3. ⏳ Screenshot aplikasi (2-8 buah)
4. ⏳ Icon aplikasi (512x512px)
5. ⏳ Feature graphic (1024x500px - optional tapi recommended)

---

**Butuh bantuan?**
Jika ada pertanyaan tentang Privacy Policy atau Data Safety form, tanya saja!
