import 'package:flutter_test/flutter_test.dart';
import 'package:sesuatu_darikota_malang/data/models/product_model.dart';
import 'package:sesuatu_darikota_malang/data/models/order_model.dart';
import 'package:sesuatu_darikota_malang/data/models/user_model.dart';
import 'package:sesuatu_darikota_malang/data/models/creator_model.dart';

void main() {
  test('produk minimal memiliki default katalog', () {
    final product = ProductModel.fromJson({'id': 'p', 'name': 'Karya', 'price': 25000});
    expect(product.id, 'p');
    expect(product.price, 25000);
    expect(product.images, isEmpty);
    expect(product.hasVariants, isFalse);
  });

  test('pesanan membaca item dan status backend', () {
    final order = OrderModel.fromJson({
      'id': 'o', 'status': 'lunas', 'totalAmount': 25000,
      'items': [{'product': {'id': 'p', 'name': 'Karya'}, 'variant': {'combination': ['S', 'Merah']}}],
    });
    expect(order.status, OrderStatus.lunas);
    expect(order.productId, 'p');
    expect(order.variantLabel, 'S, Merah');
    expect(order.total, 25000);
  });

  test('pengguna tanpa role memakai buyer', () {
    final user = UserModel.fromJson({'id': 'u', 'email': 'u@example.test'});
    expect(user.role, Role.buyer);
    expect(user.toJson()['role'], 'buyer');
  });

  test('kreator memakai brand dan nilai default', () {
    final creator = CreatorModel.fromJson({'id': 'c', 'brandName': 'Karya Malang'});
    expect(creator.name, 'Karya Malang');
    expect(creator.handle, 'karyamalang');
    expect(creator.city, 'Malang');
    expect(creator.status, 'aktif');
  });
}
