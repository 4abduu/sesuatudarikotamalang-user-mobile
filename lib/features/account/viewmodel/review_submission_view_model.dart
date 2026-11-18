import 'package:flutter/foundation.dart';
import '../../../data/repositories/catalog_repositories.dart';

class ReviewSubmissionViewModel extends ChangeNotifier {
  ReviewSubmissionViewModel({required ReviewRepository repository}) : _repository = repository;
  final ReviewRepository _repository;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> submit({String? orderItemId, required int rating, required String comment}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.submit(orderItemId: orderItemId, rating: rating, comment: comment);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
