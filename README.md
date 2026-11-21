# Sesuatu DariKota Malang — Flutter (Customer & Creator)

Flutter app yang mereplikasi customer storefront dari versi Next.js.
**Tidak ada admin** — admin hanya di web.

## Menjalankan aplikasi

```bash
cd user_mobile
flutter pub get

# Lokal dengan backend Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

# Lokal dengan backend perangkat fisik/LAN
flutter run --dart-define=API_BASE_URL=http://ALAMAT_IP_KOMPUTER:4000
```

Jika tidak memberikan `API_BASE_URL`, aplikasi memakai backend production:
`https://api.sesuatudarikotamalang.my.id`.

## Build APK release

```bash
cd user_mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.sesuatudarikotamalang.my.id
```

APK hasil build berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

APK dapat dipasang dengan drag-and-drop ke LDPlayer atau memakai:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Build release demo saat ini memakai signing debug. Untuk publikasi ke Play Store,
buat release keystore sendiri dan daftarkan SHA-1 release di Google Cloud Console.

## Konfigurasi Google Sign-In

Untuk mengambil SHA-1 signing debug Android:

```bash
cd android
gradlew.bat signingReport
```

Gunakan package name dan SHA-1 yang dihasilkan untuk OAuth Android di Google Cloud
Console. OAuth Web Client ID tetap dikonfigurasi di aplikasi dan backend.

## Demo Login

Di halaman login ada 2 tombol demo:
- **Pembeli** — Maya Anggraini (buyer, bisa beli + beri ulasan)
- **Kreator** — Dini Aulia (creator, + akses dashboard kreator)

## Struktur

```
lib/
  core/         # theme, constants, routing, utils, widgets generik
  data/         # models + dummy data (12 produk, 6 kreator, 8 kategori)
  features/     # auth, home, catalog, product_detail, creators, reservation,
                # creator_application, creator_dashboard, notifications, account
  shared/       # app_scaffold + bottom_nav_bar
```

## Fitur

- Guest browse-only (katalog, detail produk, profil kreator)
- AuthGate modal (bottom sheet) untuk aksi butuh login
- Sistem varian 2D (Motif × Ukuran) dengan chip selector
- Reservasi 3-step (jadwal → bayar → tiket QR)
- Check-at-submit: stok dicek di tombol "Pesan Sekarang"
- Dua siklus: Midtrans (Lunas permanen) vs Cash/QRIS (hold 2 jam)
- Status order: Menunggu Bayar / Lunas / Selesai / Dibatalkan / Kedaluwarsa / Lewat Batas Pengambilan
- Akun: riwayat pesanan, detail tiket QR, beri ulasan, status pengajuan kreator, pengaturan (ganti nama/foto/email-OTP/password)
- Dashboard kreator (khusus role creator)
- Bottom nav 5 tab: Beranda, Katalog, Kreator, Notif, Akun
```
