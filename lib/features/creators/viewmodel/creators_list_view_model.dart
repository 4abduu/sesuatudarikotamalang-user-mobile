import 'package:flutter/foundation.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class CreatorsListViewModel extends ChangeNotifier {
  CreatorsListViewModel({required ArtisanRepository repository})
      : _repository = repository;

  final ArtisanRepository _repository;
  List<CreatorModel> _creators = [];
  CreatorModel? _officialStore;
  bool _isLoading = false;
  String? _errorMessage;

  List<CreatorModel> get creators => _creators;
  CreatorModel? get officialStore => _officialStore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getArtisans();
      _creators = result.artisans;
      _officialStore = result.officialStore;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
