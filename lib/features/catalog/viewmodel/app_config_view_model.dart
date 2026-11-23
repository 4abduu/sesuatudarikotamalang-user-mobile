import 'package:flutter/foundation.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/olshop_model.dart';
import '../../../data/repositories/catalog_repositories.dart';
import '../../../core/app_version.dart';

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
  bool _updateRequired = false;
  String? _updateMessage;
  String? _minimumVersion;
  String _supportEmail = 'help.sesuatudarikotamalang@gmail.com';
  List<CategoryModel> get categories => _categories;
  String get whatsappAdminNumber => _whatsappAdminNumber;
  String? get contactEmail => _contactEmail;
  String? get aboutDescription => _aboutDescription;
  Map<OlshopPlatform, String?> get olshopStores => _olshopStores;
  bool get settingsOk => _settingsOk;
  bool get settingsDone => _settingsDone;
  bool get updateRequired => _updateRequired;
  String? get updateMessage => _updateMessage;
  String? get minimumVersion => _minimumVersion;
  String get supportEmail => _supportEmail;

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
      final update = s['appUpdate'];
      if (update is! Map) {
        _updateRequired = true;
        _updateMessage = 'Server belum diperbarui untuk mendukung versi aplikasi ini. Hubungi developer agar backend segera diperbarui.';
      } else {
        final updateMap = Map<String, dynamic>.from(update);
        _minimumVersion = _clean(updateMap['minimumVersion']);
        _supportEmail = _clean(updateMap['supportEmail']) ?? _supportEmail;
        final minimum = _minimumVersion;
        if (minimum != null && _compareVersions(AppVersion.current, minimum) < 0) {
          _updateRequired = true;
          _updateMessage = 'Versi aplikasi ini sudah tidak didukung. Silakan update aplikasi atau hubungi developer.';
        } else {
          _updateRequired = false;
          _updateMessage = null;
        }
      }
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

  int _compareVersions(String left, String right) {
    List<int> parts(String value) => value
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final a = parts(left);
    final b = parts(right);
    for (var i = 0; i < 3; i++) {
      final comparison = (a.length > i ? a[i] : 0).compareTo(b.length > i ? b[i] : 0);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  String? _clean(Object? value) {
    if (value is! String) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}
