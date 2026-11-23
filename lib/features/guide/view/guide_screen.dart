import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feature_tour.dart';
import '../../../shared/app_scaffold.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  bool _creator = false;
  final _roleKey = GlobalKey();
  final _firstTopicKey = GlobalKey();
  final _tourKey = GlobalKey();

  static const _buyerTopics = <_GuideTopic>[
    _GuideTopic('Memulai aplikasi', 'Akun dan akses dasar', 'Buat akun agar pesanan, pembayaran, dan ulasan tersimpan.', ['Buka Akun lalu pilih Daftar jika belum memiliki akun.', 'Login memakai email dan password, atau gunakan Google.', 'Jika lupa password, buka Lupa Password dan ikuti OTP dari email.']),
    _GuideTopic('Menjelajahi produk', 'Cari karya yang kamu suka', 'Gunakan katalog untuk melihat karya artisan Kayutangan Heritage.', ['Buka Katalog dari navigasi bawah.', 'Pilih kategori atau gunakan pencarian untuk mempersempit hasil.', 'Buka kartu produk untuk melihat foto, cerita, kreator, varian, harga, dan stok.']),
    _GuideTopic('Memilih varian', 'Pastikan pilihan sesuai sebelum memesan', 'Produk dengan lebih dari satu opsi menampilkan kombinasi seperti S / Hitam.', ['Pilih satu nilai pada setiap opsi, misalnya ukuran dan warna.', 'Periksa badge varian pada foto dan ringkasan pilihan.', 'Jika stok kombinasi habis, pilih kombinasi lain yang masih tersedia.']),
    _GuideTopic('Keranjang dan pilihan belanja', 'Pilih produk sebelum checkout', 'Keranjang menyimpan kombinasi produk dan varian secara terpisah, seperti motif Hitam ukuran M.', ['Tekan Keranjang pada detail produk lalu pilih varian dan jumlah dari panel bawah.', 'Buka ikon keranjang di navbar untuk melihat foto, varian, jumlah, dan stok terbaru.', 'Gunakan checkbox untuk memilih produk yang ingin di-checkout; jumlah baris keranjang ditampilkan pada badge.', 'Geser kartu ke kiri untuk menghapus item. Subtotal dan tombol checkout berada di bagian bawah halaman.']),
    _GuideTopic('Membuat pesanan', 'Dari produk sampai checkout', 'Pesanan dibuat setelah produk, varian, jadwal, dan metode pembayaran dipilih.', ['Tekan Pesan pada detail produk.', 'Pilih jumlah, varian, dan tanggal atau slot pickup.', 'Periksa ringkasan pesanan sebelum menekan Bayar.']),
    _GuideTopic('Checkout beberapa produk', 'Pesan beberapa varian sekaligus', 'Produk dan varian berbeda dapat masuk dalam satu pesanan pickup.', ['Pilih beberapa baris produk di halaman Keranjang.', 'Tekan Checkout dan pilih tanggal, slot pickup, serta metode pembayaran.', 'Backend memeriksa stok semua item lagi saat pesanan dibuat.', 'Jika salah satu item habis, periksa pesan yang tampil lalu ubah pilihan atau jumlahnya.']),
    _GuideTopic('Pembayaran Midtrans', 'QRIS dan metode pembayaran lain', 'Pembayaran diproses oleh Midtrans dan status akhirnya dikonfirmasi backend.', ['Pilih Midtrans lalu selesaikan pembayaran di halaman Snap.', 'Jika halaman pembayaran tertutup, buka detail pesanan dan tekan Bayar Lagi.', 'Pesanan tetap menggunakan transaksi yang sama selama belum kedaluwarsa.', 'Jangan membuat pesanan baru hanya karena halaman pembayaran tertutup.']),
    _GuideTopic('Status pesanan', 'Pahami perjalanan pesanan', 'Status membantu mengetahui apakah pesanan masih menunggu pembayaran, diproses, atau siap diambil.', ['Buka Akun > Pesanan untuk melihat daftar pesanan.', 'Buka salah satu pesanan untuk melihat status, detail varian, pembayaran, dan jadwal pickup.', 'Jika pembayaran sudah dilakukan tetapi status belum berubah, tunggu sinkronisasi lalu refresh.']),
    _GuideTopic('Pickup dan tiket QR', 'Ambil pesanan di toko', 'Tiket QR digunakan saat pesanan diambil dan diverifikasi oleh toko.', ['Datang sesuai jadwal pickup yang dipilih.', 'Buka detail pesanan dan tampilkan QR kepada admin toko.', 'Pastikan pesanan sudah berstatus dapat diambil sebelum datang.']),
    _GuideTopic('Ulasan dan cerita', 'Bagikan pengalamanmu', 'Ulasan membantu pembeli lain dan kreator memahami pengalaman setelah transaksi.', ['Buka pesanan yang sudah selesai.', 'Pilih Beri Ulasan lalu isi rating dan komentar.', 'Ulasan hanya dibuat untuk pesanan yang memenuhi status yang ditentukan aplikasi.']),
    _GuideTopic('Notifikasi', 'Lihat informasi terbaru', 'Notifikasi memberi tahu perubahan pesanan, produk, stok, dan pengajuan.', ['Buka ikon notifikasi dari navigasi aplikasi.', 'Badge menunjukkan jumlah notifikasi yang belum dibaca.', 'Ketuk notifikasi untuk membacanya, atau gunakan opsi hapus sesuai kebutuhan.']),
    _GuideTopic('Marketplace', 'Beli melalui toko eksternal', 'Link Shopee, Tokopedia, dan TikTok Shop dibuka di aplikasi marketplace atau browser eksternal.', ['Buka detail produk yang memiliki link marketplace.', 'Tekan Beli di Marketplace lalu pilih platform yang diinginkan.', 'Pastikan aplikasi marketplace sudah terpasang jika ingin membukanya langsung.']),
    _GuideTopic('Akun dan keamanan', 'Kelola data akun dengan aman', 'Data akun digunakan untuk login, komunikasi, dan riwayat transaksi.', ['Buka Akun > Pengaturan untuk mengubah nama atau foto profil.', 'Gunakan email aktif karena OTP dan pemulihan akun dikirim ke sana.', 'Jangan membagikan OTP atau password kepada siapa pun.']),
    _GuideTopic('Pembaruan aplikasi', 'Jaga aplikasi tetap kompatibel', 'Versi lama dapat dihentikan jika server membutuhkan fitur baru.', ['Jika muncul layar Aplikasi perlu diperbarui, gunakan APK terbaru dari developer.', 'Jika belum tersedia, tekan Hubungi developer atau kirim email ke help.sesuatudarikotamalang@gmail.com.', 'Jangan menghapus aplikasi sebelum memastikan akun dan akses login masih tersedia.']),
    _GuideTopic('Menjadi kreator', 'Mulai menitipkan karya', 'Kreator dapat mengajukan brand untuk menampilkan produk di katalog.', ['Buka menu Daftar Kreator dari Akun.', 'Isi data brand, kontak, deskripsi, dan foto yang diminta.', 'Pantau status pengajuan dari Akun > Status Pengajuan.']),
  ];

  static const _creatorTopics = <_GuideTopic>[
    _GuideTopic('Memulai sebagai kreator', 'Siapkan toko dan profilmu', 'Profil toko adalah identitas yang dilihat pembeli di halaman kreator.', ['Buka Dashboard Kreator dari Akun.', 'Lengkapi nama brand, deskripsi, foto profil, dan informasi toko.', 'Simpan perubahan lalu buka profil publik untuk memastikan tampilannya benar.']),
    _GuideTopic('Menambah produk', 'Masukkan karya dengan lengkap', 'Informasi yang jelas membuat produk lebih mudah dipahami dan disetujui.', ['Buka Produk Saya lalu tekan Tambah Produk.', 'Isi nama, deskripsi, kategori, harga, dan foto.', 'Tulis informasi yang sesuai kondisi produk; jangan memasukkan data yang tidak benar.', 'Simpan produk untuk dikirim ke proses persetujuan.']),
    _GuideTopic('Foto dan tautan varian', 'Cocokkan foto dengan pilihan produk', 'Foto yang dikaitkan ke varian akan mengikuti urutan nilai varian di katalog.', ['Unggah semua foto produk terlebih dahulu.', 'Pilih foto lalu kaitkan dengan motif, ukuran, warna, atau kombinasi yang sesuai.', 'Jika nilai varian diurutkan ulang, galeri akan mengikuti urutan tersebut.', 'Gunakan foto yang jelas dan pastikan isi file sesuai format gambarnya.']),
    _GuideTopic('Varian dan stok', 'Kelola stok setiap kombinasi', 'Aplikasi membuat kombinasi otomatis dari opsi yang kamu masukkan.', ['Buat opsi seperti Ukuran dan Warna.', 'Isi nilainya, misalnya S, M, L dan Merah, Hitam.', 'Aplikasi membuat kombinasi S / Merah, S / Hitam, M / Merah, dan seterusnya.', 'Klik angka stok pada baris kombinasi untuk menambah atau mengurangi stok.', 'Pastikan stok setiap kombinasi sesuai barang fisik yang tersedia.']),
    _GuideTopic('Membuat cerita dengan AI', 'Dapatkan draf cerita produk', 'AI hanya membantu membuat draf; kreator tetap wajib memeriksa isinya.', ['Isi bahan, motif, proses pembuatan, inspirasi, dan konteks lokal.', 'Tekan Bantu dengan AI pada bagian cerita produk.', 'Baca ulang draf dan ubah bagian yang tidak sesuai fakta.', 'Simpan cerita setelah bahasanya dan informasinya sudah benar.']),
    _GuideTopic('Mengelola produk', 'Pantau status dan perubahan produk', 'Produk dapat memiliki status menunggu, disetujui, ditolak, atau ditarik.', ['Buka Produk Saya untuk melihat status setiap produk.', 'Jika ditolak, baca catatan admin lalu perbaiki bagian yang diminta.', 'Produk yang sudah memiliki struktur varian dapat mengunci struktur tersebut; stok tetap dapat dikelola.', 'Tarik produk jika sudah tidak dijual atau stoknya tidak tersedia.']),
    _GuideTopic('Mengelola pesanan', 'Ikuti pesanan dari pembeli', 'Status pesanan membantu toko menyiapkan dan menyerahkan pesanan tepat waktu.', ['Buka Dashboard Kreator > Pesanan.', 'Periksa produk, varian, jumlah, pembayaran, dan jadwal pickup.', 'Siapkan barang sesuai kombinasi varian yang dipesan.', 'Serahkan pesanan setelah QR dan statusnya diverifikasi admin toko.']),
    _GuideTopic('Laporan dan bagi hasil', 'Pahami hasil penjualanmu', 'Laporan membantu memantau performa produk dan pendapatan kreator.', ['Buka Laporan Kreator dari dashboard.', 'Pilih periode yang ingin diperiksa.', 'Gunakan data produk terjual dan nilai penjualan untuk mengevaluasi katalog.', 'Persentase bagi hasil mengikuti pengaturan yang berlaku di platform.']),
    _GuideTopic('Keamanan akun', 'Lindungi akses dashboard kreator', 'Akun kreator memiliki akses ke data produk, stok, dan pesanan.', ['Gunakan password yang kuat dan unik.', 'Jangan bagikan OTP atau token login.', 'Logout jika memakai perangkat bersama.', 'Hubungi admin jika menemukan aktivitas atau perubahan yang tidak kamu lakukan.']),
  ];

  @override
  Widget build(BuildContext context) {
    final topics = _creator ? _creatorTopics : _buyerTopics;
    return AppScaffold(
      title: 'Panduan Penggunaan',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pilih panduan sesuai peranmu', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text('Buka topik untuk melihat langkah-langkah penggunaan aplikasi.', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _RoleButton(key: _roleKey, label: 'Pengguna', icon: Icons.shopping_bag_outlined, selected: !_creator, onTap: () => setState(() => _creator = false))),
            const SizedBox(width: 10),
            Expanded(child: _RoleButton(label: 'Kreator', icon: Icons.storefront_outlined, selected: _creator, onTap: () => setState(() => _creator = true))),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: _tourKey,
              onPressed: () => showFeatureTour(context, [
                FeatureTourStep(target: _roleKey, title: 'Pilih peran', description: 'Pilih Pengguna atau Kreator agar panduan yang tampil sesuai kebutuhanmu.'),
                FeatureTourStep(target: _firstTopicKey, title: 'Buka topik', description: 'Tekan salah satu topik untuk melihat langkah penggunaan fitur secara bertahap.'),
                FeatureTourStep(target: _tourKey, title: 'Ulangi kapan saja', description: 'Tur ini bisa dibuka lagi dari halaman Panduan Penggunaan.'),
              ]),
              icon: const Icon(Icons.tour_outlined),
              label: const Text('Mulai tur singkat'),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppShadows.soft),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.mustard),
              const SizedBox(width: 10),
              Expanded(child: Text(_creator ? 'Tips: buat struktur varian dulu, lalu isi stok setiap kombinasi.' : 'Tips: jika keluar dari Midtrans, buka detail pesanan dan tekan Bayar Lagi selama pesanan belum kedaluwarsa.', style: AppTextStyles.body.copyWith(height: 1.45))),
            ]),
          ),
          const SizedBox(height: 14),
          ...topics.asMap().entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            key: entry.key == 0 ? _firstTopicKey : null,
            child: ExpansionTile(
              leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
              title: Text(entry.value.title, style: AppTextStyles.label),
              subtitle: Text(entry.value.subtitle, style: AppTextStyles.caption),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              children: [
                Align(alignment: Alignment.centerLeft, child: Text(entry.value.intro, style: AppTextStyles.body.copyWith(height: 1.4))),
                const SizedBox(height: 8),
                for (var i = 0; i < entry.value.steps.length; i++)
                  ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: CircleAvatar(radius: 11, backgroundColor: AppColors.surfaceAlt, child: Text('${i + 1}', style: AppTextStyles.caption)), title: Text(entry.value.steps[i], style: AppTextStyles.body)),
              ],
            ),
          )),
        ]),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({super.key, required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.onPrimary : AppColors.primary,
        backgroundColor: selected ? AppColors.primary : AppColors.surface,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _GuideTopic {
  final String title;
  final String subtitle;
  final String intro;
  final List<String> steps;

  const _GuideTopic(this.title, this.subtitle, this.intro, this.steps);
}
