import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';

class SearchProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<CreatorModel> _creators = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  int _searchRequestId = 0;

  List<ProductModel> get products => _products;
  List<CreatorModel> get creators => _creators;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Global Search (GET /api/search?q=) dengan debounce 400ms sesuai panduan
  void search(String query) {
    _debounceTimer?.cancel();

    final q = query.trim();
    if (q.isEmpty) {
      clear();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Debounce 400 ms (rentang 300-500 ms sesuai Bagian 3.1 panduan)
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final currentRequestId = ++_searchRequestId;

      try {
        final res = await ApiClient.get('/search', queryParameters: {'q': q});
        // Abaikan hasil jika ada request pencarian baru yang masuk setelah ini
        if (currentRequestId != _searchRequestId) return;

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
        if (currentRequestId == _searchRequestId) {
          _errorMessage = e.toString();
        }
      } finally {
        if (currentRequestId == _searchRequestId) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    _searchRequestId++;
    _products = [];
    _creators = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
