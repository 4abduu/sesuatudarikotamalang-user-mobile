# Sesuatu DariKota Malang — Mobile

> **Release v1.0.0** · Flutter · Android · Customer & Creator

Aplikasi mobile untuk pembeli dan kreator. Dashboard admin berada di aplikasi
web terpisah; aplikasi ini tidak menyediakan role admin.

## Daftar isi

- [Fitur](#fitur)
- [Menjalankan lokal](#menjalankan-lokal)
- [Menjalankan di emulator Android](#menjalankan-di-emulator-android)
- [Build APK release](#build-apk-release)
- [Konfigurasi Google Sign-In](#konfigurasi-google-sign-in)
- [Testing](#testing)
- [Struktur project](#struktur-project)
- [Nama dan branding aplikasi](#nama-dan-branding-aplikasi)

## Fitur

### Pembeli

- Browse katalog dan detail produk.
- Pilih kombinasi varian dan melihat foto yang terkait.
- Reservasi, pembayaran Midtrans, Cash/QRIS, dan resume pembayaran.
- Tiket QR, riwayat order, ulasan, notifikasi, OTP, dan pengaturan akun.
- Login email/password dan Google Sign-In.

### Kreator

- Pengajuan menjadi kreator.
- Dashboard kreator dan pengelolaan produk.
- Opsi varian, foto yang ditautkan ke varian, dan stok per kombinasi.
- Bantuan AI untuk membuat draft cerita produk.
- Panduan penggunaan dan coach mark pada fitur penting.

### UX dan keamanan

- Foto yang ditolak moderasi atau signature backend ditandai border merah.
- Badge detail produk menampilkan label varian, misalnya \`XL / Hitam\`.
- Foto galeri mengikuti urutan opsi varian.
- Upload profil memakai crop berbentuk lingkaran.
- API production dapat langsung dipakai melalui \`API_BASE_URL\`.

## Menjalankan lokal

### Prasyarat

- Flutter SDK sesuai constraint project.
- Android Studio dan Android SDK.
- Emulator Android aktif atau perangkat Android dengan USB debugging.
- Backend lokal atau URL production.

### Instalasi

\`\`\`bash
flutter pub get
\`\`\`

Jika tidak memberikan \`API_BASE_URL\`, aplikasi memakai backend production:

\`\`\`text
https://api.sesuatudarikotamalang.my.id
\`\`\`

## Menjalankan di emulator Android

Cek device:

\`\`\`bash
flutter devices
\`\`\`

Jalankan pada emulator Android Studio, bukan Chrome atau Edge:

\`\`\`bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://api.sesuatudarikotamalang.my.id
\`\`\`

Untuk backend lokal dari emulator Android, gunakan \`10.0.2.2\`:

\`\`\`bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:4000
\`\`\`

\`localhost\` dari emulator menunjuk ke emulator itu sendiri, bukan komputer
developer.

## Build APK release

\`\`\`bash
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.sesuatudarikotamalang.my.id
\`\`\`

Output:

\`\`\`text
build/app/outputs/flutter-apk/app-release.apk
\`\`\`

Instal ke emulator/perangkat:

\`\`\`bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
\`\`\`

Build demo saat ini memakai signing debug. Untuk Play Store, buat release
keystore sendiri dan daftarkan SHA-1 release di Google Cloud Console.

## Konfigurasi Google Sign-In

Ambil SHA-1 signing debug Android:

\`\`\`bash
cd android
gradlew.bat signingReport
\`\`\`

Gunakan package name dan SHA-1 tersebut pada OAuth Android di Google Cloud
Console. OAuth Web Client ID tetap dikonfigurasi pada aplikasi dan backend.

## Testing

Static analysis dan test suite:

\`\`\`bash
flutter analyze
flutter test
\`\`\`

Quality check release:

\`\`\`bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.sesuatudarikotamalang.my.id
\`\`\`

Smoke test minimum:

1. Buka katalog sebagai guest.
2. Login email/password dan Google.
3. Buka detail produk, pilih varian, lalu cek foto dan badge.
4. Buat order sandbox Midtrans dan uji resume pembayaran.
5. Uji OTP, lupa password, ganti email, dan ganti password.
6. Login sebagai kreator, buka panduan, tambah produk, ubah stok, dan upload foto.
7. Uji perangkat kecil untuk memastikan badge, tombol, dan form tidak terpotong.

## Struktur project

\`\`\`text
lib/
├── core/          # config, routing, theme, helper, dan widget umum
├── data/          # model, repository, API service
├── domain/        # use case dan validasi
├── features/      # auth, home, katalog, produk, order, akun, kreator, guide
└── shared/        # scaffold dan bottom navigation
assets/
└── images/        # logo, kategori, dan aset aplikasi
android/
└── app/           # konfigurasi Android dan launcher icon
\`\`\`

## Nama dan branding aplikasi

Nama aplikasi: **Sesuatu DariKota Malang**.

Launcher icon menggunakan logo crop brand lokal, bukan ikon default Flutter.
Nama teknis folder/repository boleh tetap \`user_mobile\`; nama yang terlihat oleh
pengguna ditentukan pada konfigurasi Android dan metadata aplikasi.

## Release v1.0.0

Rilis pertama untuk demo akademik dan pengujian end-to-end customer serta
creator. Sebelum publikasi, gunakan release keystore, naikkan version code,
verifikasi Google OAuth release SHA-1, dan uji pembayaran sandbox secara
menyeluruh.
