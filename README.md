# Sesuatu DariKota Malang — Flutter (Customer & Creator)

Flutter app yang mereplikasi customer storefront dari versi Next.js.
**Tidak ada admin** — admin hanya di web.

## Cara Run

```bash
cd mobile
flutter pub get
flutter run
```

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
