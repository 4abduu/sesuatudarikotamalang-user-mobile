import '../models/notification_model.dart';

final List<NotificationModel> dummyNotifications = [
  const NotificationModel(id: 'n1', type: NotificationType.creator, title: 'Pengajuan konsinyasi diterima!', body: 'Karya kamu sudah lolos kurasi dan tayang di katalog. Selamat!', date: '1 jam lalu', read: false),
  const NotificationModel(id: 'n2', type: NotificationType.review, title: 'Produkmu mendapat review baru', body: 'Kartika memberi bintang 5 untuk Postcard Jendela Kayutangan.', date: '5 jam lalu', read: false),
  const NotificationModel(id: 'n3', type: NotificationType.order, title: 'Reservasi pickup menunggu', body: 'Pesanan #SDK-0241 menunggu konfirmasi pembayaran.', date: 'kemarin', read: true),
  const NotificationModel(id: 'n4', type: NotificationType.system, title: 'Selamat datang, kreator!', body: 'Akun kreator kamu sudah aktif. Yuk lengkapi profil dan tambahkan produk pertamamu.', date: '2 hari lalu', read: true),
  const NotificationModel(id: 'n5', type: NotificationType.order, title: 'Pesananmu sudah diambil', body: 'Pesanan #SDK-0238 sudah diambil di toko.', date: '3 hari lalu', read: true),
];
