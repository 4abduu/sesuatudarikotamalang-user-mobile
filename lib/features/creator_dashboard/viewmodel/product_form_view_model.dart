import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/olshop_validator.dart';
import '../../../core/utils/variant_combinations.dart';
import '../../../core/viewmodel/photo_editor_view_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_option_model.dart';
import '../../../data/models/olshop_model.dart';
import '../../../data/repositories/catalog_repositories.dart';
import '../../../data/services/upload_service.dart';

class ProductFormViewModel extends ChangeNotifier {
  ProductFormViewModel({required ProductRepository repository, required UploadService upload,
    required this.photos, this.productId = '', this.replaceOf = ''})
      : _repository = repository, _upload = upload {
    photos.addListener(_notify);
  }
  final ProductRepository _repository;
  final UploadService _upload;
  final PhotoEditorViewModel photos;
  final String productId;
  final String replaceOf;
  ProductModel? _initial;
  bool _disposed = false;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _errorCode;
  String _name = '', _description = '', _shortDescription = '', _price = '';
  String? _category;
  bool _limited = false;
  List<VariantOptionModel> _options = [];
  Map<String, int> _stocks = {};
  Map<String, int> _initialStocks = {};
  Map<String, String> _variantIds = {};
  Map<OlshopPlatform, OlshopSetting> _olshop = {};
  Map<OlshopPlatform, String?> _olshopErrors = {};

  bool get isEdit => productId.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isReady => _initialized;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  String get name => _name;
  String get description => _description;
  String get shortDescription => _shortDescription;
  String get price => _price;
  String? get category => _category;
  bool get limited => _limited;
  List<VariantOptionModel> get options => List.unmodifiable(_options);
  Map<String, int> get stocks => Map.unmodifiable(_stocks);
  Map<OlshopPlatform, OlshopSetting> get olshop => Map.unmodifiable(_olshop);
  Map<OlshopPlatform, String?> get olshopErrors => Map.unmodifiable(_olshopErrors);
  bool get isPhotosDirty => photos.dirty;
  List<VariantChoice>? get variantChoices {
    final valid = _options.where((o) => o.name.trim().isNotEmpty && o.values.isNotEmpty);
    return valid.isEmpty ? null : valid.map((o) => VariantChoice(o.name.trim(), List.of(o.values))).toList();
  }

  Future<void> init() async {
    if (_initialized || _isLoading || _disposed) return;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      if (isEdit) {
        // Endpoint milik kreator juga memuat produk belum disetujui/terkunci.
        final products = await _repository.getMine();
        if (_disposed) return;
        final matches = products.where((p) => p.id == productId);
        if (matches.isEmpty) throw ApiException(404, 'Produk tidak ditemukan');
        final p = _initial = matches.first;
        _name = p.name;
        _description = p.description;
        _shortDescription = p.shortDesc;
        _price = p.price.toString();
        _category = p.categoryId;
        _limited = p.isLimited;
        _options = List.of(p.variantOptions);
        _stocks = {for (final v in p.variants) v.options.join(' / '): v.effectiveStock};
        _initialStocks = Map.of(_stocks);
        _variantIds = {for (final v in p.variants) v.options.join(' / '): v.id};
        _olshop = Map.of(p.olshop);
        photos.setInitialItems(photoItemsFromServer(p.images, p.imageVariants));
      }
      _initialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void setName(String value) { if (!_isSaving) _name = value; }
  void setDescription(String value) { if (!_isSaving) _description = value; }
  void setShortDescription(String value) { if (!_isSaving) _shortDescription = value; }
  void setPrice(String value) { if (!_isSaving) _price = value; }
  void setCategory(String? value) { if (_isSaving) return; _category = value; _notify(); }
  void setLimited(bool value) { if (_isSaving) return; _limited = value; _notify(); }
  void setOlshop(Map<OlshopPlatform, OlshopSetting> value) {
    if (_isSaving) return;
    _olshop = Map.of(value); _olshopErrors = {}; _notify();
  }

  /// Struktur varian edit terkunci, walaupun pemanggil bukan widget.
  bool setVariants(List<VariantOptionModel> options, Map<String, int> stocks) {
    if (_isSaving) return false;
    if (!isEdit) {
      _options = options.map((o) => VariantOptionModel(name: o.name, values: List.of(o.values))).toList();
      _stocks = Map.of(stocks);
    } else {
      _stocks = {for (final key in _variantIds.keys) key: stocks[key] ?? _stocks[key] ?? 0};
    }
    var pruned = false;
    final updated = photos.items.map((item) {
      final combination = item.variantCombination;
      if (combination == null || combination.isEmpty) {
        return item;
      }
      if (combination.entries.every((entry) => _options.any((o) =>
          o.name.trim() == entry.key && o.values.contains(entry.value)))) {
        return item;
      }
      pruned = true;
      return item.withoutVariant();
    }).toList();
    if (pruned) photos.setItems(updated);
    _notify();
    return pruned;
  }

  bool _validate() {
    if (_name.trim().isEmpty || _description.trim().isEmpty || _category == null || _price.trim().isEmpty) {
      _errorMessage = 'Lengkapi nama, deskripsi, kategori, dan harga';
    } else if (int.tryParse(_price.trim()) == null || int.parse(_price.trim()) < 0) {
      _errorMessage = 'Harga harus berupa angka positif';
    } else if (photos.items.isEmpty) {
      _errorMessage = 'Produk harus punya minimal satu foto';
    } else {
      _olshopErrors = {};
      for (final p in OlshopPlatform.values) {
        final setting = _olshop[p];
        if (setting != null && setting.mode == OlshopMode.khusus) {
          final error = validateOlshopUrl(p, setting.url);
          if (error != null) _olshopErrors[p] = error;
        }
      }
      if (_olshopErrors.isNotEmpty) _errorMessage = 'Periksa link marketplace yang ditandai merah';
    }
    return _errorMessage == null;
  }

  Map<String, dynamic> _payload(PhotoSyncResult? sync) {
    final initial = _initial;
    final valid = _options.where((o) => o.name.trim().isNotEmpty && o.values.isNotEmpty).toList();
    final changedStocks = <Map<String, dynamic>>[
      for (final c in variantCombinations(valid))
        if (_variantIds[c.join(' / ')]?.isNotEmpty == true && _stocks[c.join(' / ')] != _initialStocks[c.join(' / ')])
          {'id': _variantIds[c.join(' / ')]!, 'stock': _stocks[c.join(' / ')] ?? 0},
    ];
    return {
      if (!isEdit || _name.trim() != initial!.name) 'name': _name.trim(),
      if (!isEdit || _category != initial!.categoryId) 'categoryId': _category,
      if (!isEdit || int.parse(_price.trim()) != initial!.price) 'price': int.parse(_price.trim()),
      if (!isEdit || _description.trim() != initial!.description) 'description': _description.trim(),
      if (!isEdit || _shortDescription.trim() != initial!.shortDesc) 'shortDescription': _shortDescription.trim(),
      if (!isEdit || _limited != initial!.isLimited) 'isLimited': _limited,
      if (sync != null) 'images': sync.images,
      if (sync != null && (isEdit || sync.imageVariants.isNotEmpty)) 'imageVariants': sync.imageVariants,
      if (!olshopSettingsEqual(_olshop, initial?.olshop ?? {})) 'olshop': olshopPayload(_olshop),
      if (!isEdit && valid.isEmpty) 'stock': 10,
      if (!isEdit && valid.isNotEmpty) 'variantOptions': [for (final o in valid) {'name': o.name.trim(), 'values': o.values}],
      if (!isEdit && valid.isNotEmpty) 'variantStocks': [for (final c in variantCombinations(valid)) {'combination': c, 'stock': _stocks[c.join(' / ')] ?? 0}],
      if (isEdit && changedStocks.isNotEmpty) 'variantStocks': changedStocks,
      if (!isEdit && replaceOf.isNotEmpty) 'replacesProductId': replaceOf,
    };
  }

  Future<bool> submit() async {
    if (_disposed || _isSaving || !_initialized) return false;
    _errorMessage = null; _errorCode = null;
    if (!_validate()) { _notify(); return false; }
    _isSaving = true;
    _notify();
    PhotoSyncResult? sync;
    try {
      if (!isEdit || photos.dirty) {
        try {
          sync = await photos.sync();
        } on ApiException catch (e) {
          _errorCode = e.code;
          _errorMessage = switch (e.code) {
            'IMAGE_REJECTED' => 'Ada foto yang tidak pantas. Hapus foto bertanda merah lalu coba lagi.',
            'MODERATION_UNAVAILABLE' => 'Pemeriksaan foto sedang tidak tersedia. Coba lagi nanti.',
            _ => 'Foto gagal diunggah: ${e.message}',
          };
          return false;
        } catch (e) {
          _errorMessage = 'Foto gagal diunggah: $e';
          return false;
        }
      }
      if (_disposed) {
        if (sync != null) await _rollback(sync);
        return false;
      }
      final body = _payload(sync);
      if (isEdit) {
        await _repository.update(productId, body);
      } else {
        await _repository.create(body);
      }
      // Foto baru sudah dimiliki produk; jangan dihapus setelah request sukses.
      return true;
    } on ApiException catch (e) {
      if (sync != null) await _rollback(sync);
      _errorCode = e.code;
      _errorMessage = e.message.isNotEmpty ? e.message : e.code == 'PRODUCT_LOCKED'
          ? 'Produk ini terkunci dan tidak dapat diubah lagi.' : 'Gagal menyimpan produk';
      return false;
    } catch (e) {
      if (sync != null) await _rollback(sync);
      _errorMessage = 'Gagal menyimpan produk: $e';
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  Future<void> deleteUploaded(List<String> urls) => _upload.deleteUrls(urls);

  Future<void> _rollback(PhotoSyncResult sync) async {
    if (sync.newlyUploaded.isEmpty) return;
    try { await _upload.deleteUrls(sync.newlyUploaded); } catch (_) { /* Pertahankan galat penyimpanan. */ }
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() {
    _disposed = true;
    photos.removeListener(_notify);
    photos.dispose();
    super.dispose();
  }
}
