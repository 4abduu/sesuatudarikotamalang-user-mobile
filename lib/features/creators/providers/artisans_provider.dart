import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';

class ArtisansProvider extends ChangeNotifier {
  List<CreatorModel> _artisans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CreatorModel> get artisans => _artisans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await fetchArtisans();
  }

  /// Ambil daftar kreator aktif (GET /api/artisans)
  Future<void> fetchArtisans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/artisans');
      if (res != null && res['artisans'] != null) {
        final list = (res['artisans'] as List<dynamic>)
            .map((e) => CreatorModel.fromJson(e as Map<String, dynamic>))
            .where((a) => a.status == 'aktif')
            .toList();
        _artisans = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil detail profil kreator + produknya (GET /api/artisans/:id)
  Future<Map<String, dynamic>?> getArtisanDetail(String id) async {
    try {
      final res = await ApiClient.get('/artisans/$id');
      if (res != null && res['artisan'] != null) {
        final creator = CreatorModel.fromJson(res['artisan'] as Map<String, dynamic>);
        final rawProducts = (res['artisan']?['products'] as List<dynamic>?) ??
            (res['products'] as List<dynamic>?);
        final products = rawProducts
                ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        // Update list cache
        final idx = _artisans.indexWhere((a) => a.id == id);
        if (idx != -1) {
          _artisans[idx] = creator;
          notifyListeners();
        }

        return {
          'artisan': creator,
          'products': products,
        };
      }
    } catch (_) {}

    // Fallback dari cache list lokal
    final match = _artisans.where((a) => a.id == id).toList();
    if (match.isNotEmpty) {
      return {
        'artisan': match.first,
        'products': <ProductModel>[],
      };
    }
    return null;
  }
}
