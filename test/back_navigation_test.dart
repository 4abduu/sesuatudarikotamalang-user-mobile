import 'package:flutter_test/flutter_test.dart';
import 'package:sesuatu_darikota_malang/core/routing/back_navigation.dart';

void main() {
  group('parentLocationOf', () {
    test('detail kreator kembali ke daftar kreator', () {
      expect(parentLocationOf('/kreator/abc'), '/kreator');
    });

    test('detail produk dan ulasan memiliki induk berurutan', () {
      expect(parentLocationOf('/produk/p1'), '/katalog');
      expect(parentLocationOf('/produk/p1/ulasan'), '/produk/p1');
    });

    test('reservasi kembali ke produk dan konfirmasi ke pesanan', () {
      expect(parentLocationOf('/reservasi/p1'), '/produk/p1');
      expect(parentLocationOf('/reservasi/konfirmasi'), '/akun/pesanan');
    });

    test('halaman akun', () {
      expect(parentLocationOf('/akun/pesanan/o1'), '/akun/pesanan');
      expect(parentLocationOf('/akun/pesanan'), '/akun');
      expect(parentLocationOf('/akun/pengaturan'), '/akun');
      expect(parentLocationOf('/akun/ulasan/write'), '/akun');
    });

    test('dashboard kreator', () {
      expect(parentLocationOf('/dashboard-kreator'), '/akun');
      expect(parentLocationOf('/dashboard-kreator/my-products'), '/dashboard-kreator');
      expect(parentLocationOf('/dashboard-kreator/laporan/2026-10'), '/dashboard-kreator/laporan');
    });

    test('lokasi lain kembali ke beranda', () {
      expect(parentLocationOf('/login'), '/');
      expect(parentLocationOf('/'), '/');
    });
  });

  test('isTopLevelPath hanya menerima tab utama', () {
    for (final path in ['/', '/katalog', '/kreator', '/akun']) {
      expect(isTopLevelPath(path), isTrue, reason: path);
    }
    for (final path in ['/kreator/abc', '/produk/p1', '/akun/pesanan', '/login']) {
      expect(isTopLevelPath(path), isFalse, reason: path);
    }
  });
}
