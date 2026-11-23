import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/repositories/cart_repository.dart';

class CartViewModel extends ChangeNotifier {
  CartViewModel(this.repository);
  final CartRepository repository;
  List<CartItemModel> items = const [];
  Map<String, dynamic> summary = const {};
  bool loading = false, saving = false;
  String? error;

  Future<void> refresh() async { loading = true; error = null; notifyListeners(); try { final result = await repository.get(); items = result.items; summary = result.summary; } on ApiException catch (e) { error = e.message; } catch (_) { error = 'Gagal memuat keranjang.'; } finally { loading = false; notifyListeners(); } }
  Future<void> add(String productId, String? variantId) async { saving = true; notifyListeners(); try { final result = await repository.add(productId: productId, variantId: variantId); items = result.items; summary = result.summary; } on ApiException catch (e) { error = e.message; } finally { saving = false; notifyListeners(); } }
  Future<void> updateQuantity(CartItemModel item, int quantity) async { final result = await repository.update(item.id, quantity); items = result.items; summary = result.summary; notifyListeners(); }
  Future<void> remove(String id) async { final result = await repository.remove(id); items = result.items; summary = result.summary; notifyListeners(); }
}
