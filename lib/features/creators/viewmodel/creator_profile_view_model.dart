import 'package:flutter/foundation.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class CreatorProfileViewModel extends ChangeNotifier {
  CreatorProfileViewModel({required ArtisanRepository repository})
      : _repository = repository;

  final ArtisanRepository _repository;
  CreatorModel? _creator;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  CreatorModel? get creator => _creator;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String creatorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getArtisan(creatorId);
      _creator = result.artisan;
      _products = result.products;
    } catch (error) {
      _errorMessage = error.toString();
      _creator = null;
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
