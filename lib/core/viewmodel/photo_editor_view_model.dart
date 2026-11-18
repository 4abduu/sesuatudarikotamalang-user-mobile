import 'package:flutter/foundation.dart';
import '../../data/models/photo_item.dart';
import '../../data/services/upload_service.dart';
import '../../data/services/photo_picker_service.dart';
import '../network/api_exception.dart';
import '../utils/photo_rules.dart';

export '../../data/models/photo_item.dart';

typedef PhotoPicker = Future<PickedPhotos> Function({required int maxCount});

class PhotoEditorViewModel extends ChangeNotifier {
  PhotoEditorViewModel(
      {required UploadService uploadService,
      List<PhotoItem> items = const [],
      this.maxPhotos = 10,
      PhotoPicker? pickMany})
      : _uploadService = uploadService,
        _pickMany = pickMany ?? PhotoPickerService().pickMany {
    _items = normalizePhotoOrder(items.take(maxPhotos).toList());
    _initialItems = List.of(_items);
  }

  final UploadService _uploadService;
  final PhotoPicker _pickMany;
  final int maxPhotos;
  late List<PhotoItem> _items;
  late List<PhotoItem> _initialItems;
  Set<String> _rejectedKeys = {};
  bool _disposed = false;
  bool _picking = false;
  Future<PhotoSyncResult>? _syncing;
  List<PhotoItem> get items => List.unmodifiable(_items);
  Set<String> get rejectedKeys => Set.unmodifiable(_rejectedKeys);
  bool get dirty => !photoListsEqual(_items, _initialItems);
  bool get isSyncing => _syncing != null;

  void setItems(List<PhotoItem> value) {
    if (_disposed) return;
    _items = normalizePhotoOrder(value.take(maxPhotos).toList());
    _rejectedKeys.removeWhere((key) => !_items.any((item) => item.key == key));
    _notify();
  }

  void setInitialItems(List<PhotoItem> value) {
    if (_disposed) return;
    _initialItems = normalizePhotoOrder(value.take(maxPhotos).toList());
    _items = List.of(_initialItems);
    _rejectedKeys.clear();
    _notify();
  }

  void reset() => setItems(List.of(_initialItems));

  Future<String?> add() async {
    if (_disposed || _picking || items.length >= maxPhotos) return null;
    _picking = true;
    try {
      final result = await _pickMany(maxCount: maxPhotos - items.length);
      if (!_disposed && result.accepted.isNotEmpty) {
        setItems([...items, ...result.accepted.map(PhotoItem.picked)]);
      }
      return result.summary;
    } finally {
      _picking = false;
    }
  }

  void remove(PhotoItem item) {
    setItems(items.where((i) => i.key != item.key).toList());
  }

  void shift(PhotoItem item, int delta) {
    final list = List<PhotoItem>.of(items);
    final from = list.indexWhere((i) => i.key == item.key);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return;
    if (list[to].isLinked != item.isLinked) return;
    final moved = list.removeAt(from);
    list.insert(to, moved);
    setItems(list);
  }

  void move(String fromKey, String toKey) {
    final list = List<PhotoItem>.of(items);
    final from = list.indexWhere((i) => i.key == fromKey);
    final to = list.indexWhere((i) => i.key == toKey);
    if (from < 0 || to < 0 || from == to) return;
    if (list[from].isLinked != list[to].isLinked) return;
    final moved = list.removeAt(from);
    list.insert(to, moved);
    setItems(list);
  }

  void makeMain(PhotoItem item) {
    if (item.isLinked) return;
    final list = items.where((i) => i.key != item.key).toList();
    list.insert(0, item);
    setItems(list);
  }

  void setVariant(PhotoItem item, Map<String, String> combination) {
    setItems(normalizePhotoOrder(
      items
          .map((i) => i.key == item.key ? i.withVariant(combination) : i)
          .toList(),
    ));
  }

  void clearVariant(PhotoItem item) {
    setItems(normalizePhotoOrder(
      items.map((i) => i.key == item.key ? i.withoutVariant() : i).toList(),
    ));
  }

  /// Indeks moderasi dihitung hanya terhadap berkas baru pada snapshot unggah.
  void markRejectedIndexes(Iterable<int> indexes, {List<PhotoItem>? snapshot}) {
    final fresh = (snapshot ?? items).where((item) => item.isNew).toList();
    _rejectedKeys = {
      for (final index in indexes)
        if (index >= 0 &&
            index < fresh.length &&
            _items.any((p) => p.key == fresh[index].key))
          fresh[index].key,
    };
    _notify();
  }

  Future<PhotoSyncResult> sync() {
    final running = _syncing;
    if (running != null) return running;
    final snapshot = List<PhotoItem>.of(items);
    final future = _performSync(snapshot);
    _syncing = future;
    _notify();
    return future;
  }

  Future<PhotoSyncResult> _performSync(List<PhotoItem> snapshot) async {
    try {
      return await _syncItems(snapshot, _uploadService);
    } on ApiException catch (e) {
      if (e.code == 'IMAGE_REJECTED') {
        markRejectedIndexes(e.rejectedIndexes, snapshot: snapshot);
      }
      rethrow;
    } finally {
      _syncing = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

Future<PhotoSyncResult> _syncItems(
    List<PhotoItem> items, UploadService uploadService) async {
  final fresh = items.where((i) => i.file != null).map((i) => i.file!).toList();
  final uploaded =
      fresh.isEmpty ? <String>[] : await uploadService.uploadMany(fresh);
  var cursor = 0;
  final images = <String>[];
  final variants = <Map<String, dynamic>>[];
  for (final item in items) {
    final url = item.file != null ? uploaded[cursor++] : item.url!;
    images.add(url);
    if (item.isLinked) {
      variants.add({
        'url': url,
        'combination': item.variantCombination!.entries
            .map((e) => {'option': e.key, 'value': e.value})
            .toList(),
      });
    }
  }
  return PhotoSyncResult(images, variants, uploaded);
}
