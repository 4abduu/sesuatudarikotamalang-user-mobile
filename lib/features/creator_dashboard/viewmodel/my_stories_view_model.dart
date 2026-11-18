import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/story_repository.dart';

class MyStoriesViewModel extends ChangeNotifier {
  MyStoriesViewModel({required StoryRepository repository}) : _repository = repository;
  final StoryRepository _repository;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  int _requestId = 0;
  List<ProductModel> get myProducts => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_disposed) return;
    final id = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final products = await _repository.getMine();
      if (!_disposed && id == _requestId) _products = products;
    } catch (e) {
      if (!_disposed && id == _requestId) _errorMessage = e.toString();
    } finally {
      if (!_disposed && id == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  @override
  void dispose() { _disposed = true; _requestId++; super.dispose(); }
}
