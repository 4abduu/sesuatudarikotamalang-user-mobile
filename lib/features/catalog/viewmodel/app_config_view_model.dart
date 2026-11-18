import 'package:flutter/foundation.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/olshop_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class AppConfigViewModel extends ChangeNotifier {
  AppConfigViewModel({required CategoryRepository categories, required SettingsRepository settings})
      : _categoriesRepo = categories,
        _settingsRepo = settings;
  final CategoryRepository _categoriesRepo;
  final SettingsRepository _settingsRepo;
  List<CategoryModel> _categories = [];
  String _whatsappAdminNumber = '6281234567890';
  String? _contactEmail;
  String? _aboutDescription;
  Map<OlshopPlatform, String?> _olshopStores = {};
  bool _settingsOk = false;
  bool _settingsDone = false;
  List<CategoryModel> get categories => _categories;
  String get whatsappAdminNumber => _whatsappAdminNumber;
  String? get contactEmail => _contactEmail;
  String? get aboutDescription => _aboutDescription;
  Map<OlshopPlatform, String?> get olshopStores => _olshopStores;
  bool get settingsOk => _settingsOk;
  bool get settingsDone => _settingsDone;

  Future<void> init() async {
    await Future.wait([fetchCategories(), fetchSettings()]);
  }

  Future<void> fetchCategories() async {
    try { _categories = await _categoriesRepo.getCategories(); } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchSettings() async {
    try {
      final s = await _settingsRepo.getPublicSettings();
      final wa = s['whatsappAdminNumber'];
      if (wa is String && wa.isNotEmpty) _whatsappAdminNumber = wa.replaceAll(RegExp(r'[^0-9]'), '');
      _contactEmail = _clean(s['contactEmail']);
      _aboutDescription = _clean(s['aboutDescription']);
      final stores = s['olshopStores'];
      if (stores is Map<String, dynamic>) _olshopStores = {for (final p in OlshopPlatform.values) p: _clean(stores[p.id])};
      _settingsOk = true;
    } catch (_) {}
    _settingsDone = true;
    notifyListeners();
  }

  String? _clean(Object? value) {
    if (value is! String) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}
