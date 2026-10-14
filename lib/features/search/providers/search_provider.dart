import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';

class SearchProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CreatorModel> _creators = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<CreatorModel> get creators => _creators;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Global Search (GET /api/search?q=)
  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      _products = [];
      _creators = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/search', queryParameters: {'q': q});
      if (res != null) {
        final prods = (res['products'] as List<dynamic>?)
                ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final crts = (res['creators'] as List<dynamic>?)
                ?.map((e) => CreatorModel.fromJson(e as Map<String, dynamic>))
                .where((c) => c.status == 'aktif')
                .toList() ??
            [];

        _products = prods;
        _creators = crts;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _products = [];
    _creators = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
