import 'package:flutter_test/flutter_test.dart';
import 'package:sesuatu_darikota_malang/data/models/image_variant_link.dart';
import 'package:sesuatu_darikota_malang/features/product_detail/utils/gallery_target.dart';

void main() {
  const links = [
    ImageVariantLink(url: 'b', option: 'Motif', value: 'Sulur'),
    ImageVariantLink(url: 'c', option: 'Motif', value: 'Ubin'),
    ImageVariantLink(url: 'd', option: 'Warna', value: 'Merah'),
  ];

  group('galleryOrder', () {
    test('foto tanpa tautan lebih dulu, urutan relatif terjaga', () {
      expect(galleryOrder(['b', 'a', 'c', 'e'], links), ['a', 'e', 'b', 'c']);
    });

    test('tanpa tautan: urutan asli', () {
      expect(galleryOrder(['x', 'y'], const []), ['x', 'y']);
    });
  });

  group('changedAxisBetween', () {
    test('mengembalikan indeks terendah yang berubah', () {
      expect(changedAxisBetween(['Ubin', 'Merah'], ['Sulur', 'Biru']), 0);
      expect(changedAxisBetween(['Ubin', 'Merah'], ['Ubin', 'Biru']), 1);
    });

    test('null bila tidak ada perubahan', () {
      expect(changedAxisBetween(['Ubin'], ['Ubin']), isNull);
    });
  });

  group('galleryTargetIndex', () {
    const ordered = ['a', 'b', 'c', 'd'];
    const names = ['Motif', 'Warna'];

    test('pindah ke foto pertama yang tertaut ke nilai terpilih', () {
      expect(
        galleryTargetIndex(
          images: ordered,
          links: links,
          optionNames: names,
          selected: ['Sulur', 'Merah'],
          changedAxis: 0,
        ),
        1,
      );
    });

    test('hanya opsi yang diubah yang menentukan', () {
      expect(
        galleryTargetIndex(
          images: ordered,
          links: links,
          optionNames: names,
          selected: ['Sulur', 'Merah'],
          changedAxis: 1,
        ),
        3,
      );
    });

    test('tidak pindah bila nilai tidak punya foto tertaut', () {
      expect(
        galleryTargetIndex(
          images: ordered,
          links: links,
          optionNames: names,
          selected: ['Polos', 'Merah'],
          changedAxis: 0,
        ),
        isNull,
      );
    });

    test('null bila tidak ada opsi yang diubah atau nilai kosong', () {
      expect(
        galleryTargetIndex(
          images: ordered,
          links: links,
          optionNames: names,
          selected: ['Sulur', 'Merah'],
          changedAxis: null,
        ),
        isNull,
      );
      expect(
        galleryTargetIndex(
          images: ordered,
          links: links,
          optionNames: names,
          selected: [null, 'Merah'],
          changedAxis: 0,
        ),
        isNull,
      );
    });
  });
}
