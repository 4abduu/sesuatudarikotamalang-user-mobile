import '../../core/network/api_service.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'catalog_repositories.dart';
import 'package:flutter/foundation.dart';

class CartSnapshot {
  final List<CartItemModel> items;
  final Map<String, dynamic> summary;
  CartSnapshot(this.items, this.summary);
}

class CartRepository extends ChangeNotifier {
  CartRepository(this._api);
  final ApiService _api;
  int lineCount = 0;
  String? _userId;
  void syncUser(String? id) {
    if (_userId == id) return;
    _userId = id;
    lineCount = 0;
    notifyListeners();
    if (id != null) get().catchError((Object _) => CartSnapshot([], {}));
  }
  Future<ProductModel> getProduct(String id) => ProductRepository(_api).getProduct(id);

  CartSnapshot _parse(dynamic value) {
    final map = (value as Map?)?.cast<String, dynamic>() ?? {};
    final items = ((map['items'] as List?) ?? []).map((e) => CartItemModel.fromJson((e as Map).cast<String, dynamic>())).toList();
    return CartSnapshot(items, (map['summary'] as Map?)?.cast<String, dynamic>() ?? {});
  }
  Future<CartSnapshot> get() async {
    final user = _userId;
    final result = _parse(await _api.get('/cart'));
    if (user == _userId) { lineCount = result.items.length; notifyListeners(); }
    return result;
  }
  Future<CartSnapshot> add({required String productId, String? variantId, int quantity = 1}) async {
    final result = await _api.post('/cart/items', body: {'productId': productId, if (variantId != null) 'variantId': variantId, 'quantity': quantity});
    lineCount = (result['summary']['lineCount'] as num).toInt();
    notifyListeners();
    return CartSnapshot([], Map<String, dynamic>.from(result['summary']));
  }
  Future<CartSnapshot> update(String id, int quantity) async { await _api.patch('/cart/items/$id', body: {'quantity': quantity}); return get(); }
  Future<CartSnapshot> remove(String id) async { await _api.delete('/cart/items/$id'); return get(); }
  Future<CartSnapshot> clear() async { await _api.delete('/cart'); return get(); }
}
