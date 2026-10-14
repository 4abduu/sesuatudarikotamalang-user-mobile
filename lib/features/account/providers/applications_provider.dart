import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/creator_application_model.dart';

class ApplicationsProvider extends ChangeNotifier {
  List<CreatorApplicationModel> _apps = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CreatorApplicationModel> get applications => List.unmodifiable(_apps);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await fetchMyApplications();
  }

  /// Ambil pengajuan kreator milik pengguna saat ini (GET /api/artisans/applications/mine)
  Future<void> fetchMyApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/artisans/applications/mine');
      if (res != null && res['applications'] != null) {
        final list = (res['applications'] as List<dynamic>)
            .map((e) => CreatorApplicationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _apps = list;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajukan menjadi kreator (POST /api/artisans/apply)
  Future<CreatorApplicationModel> apply({
    required String applicantName,
    required String contact,
    required String brandName,
    required String description,
    String? categoryId,
    String? sampleFileUrl,
  }) async {
    final body = <String, dynamic>{
      'applicantName': applicantName,
      'contact': contact,
      'brandName': brandName,
      'description': description,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (sampleFileUrl != null && sampleFileUrl.isNotEmpty) 'sampleFileUrl': sampleFileUrl,
    };

    final res = await ApiClient.post('/artisans/apply', body: body);
    if (res != null && res['application'] != null) {
      final newApp = CreatorApplicationModel.fromJson(res['application'] as Map<String, dynamic>);
      _apps.insert(0, newApp);
      notifyListeners();
      return newApp;
    }
    throw ApiException(500, 'Gagal mengirim pengajuan kreator.');
  }

  void addApplication(CreatorApplicationModel app) {
    _apps.insert(0, app);
    notifyListeners();
  }

  CreatorApplicationModel? latestForUser(String userId) {
    final userApps = _apps.where((a) => a.userId == userId || userId.isEmpty).toList();
    if (userApps.isEmpty) return null;
    userApps.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return userApps.first;
  }

  /// Updates the status of an existing application locally
  Future<void> updateStatus(String id, ApplicationStatus status, {String? rejectReason}) async {
    final idx = _apps.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final a = _apps[idx];
    _apps[idx] = CreatorApplicationModel(
      id: a.id,
      userId: a.userId,
      applicantName: a.applicantName,
      contact: a.contact,
      email: a.email,
      brandName: a.brandName,
      description: a.description,
      category: a.category,
      submittedAt: a.submittedAt,
      status: status,
      rejectReason: status == ApplicationStatus.rejected ? (rejectReason ?? a.rejectReason) : null,
    );
    notifyListeners();
  }
}
