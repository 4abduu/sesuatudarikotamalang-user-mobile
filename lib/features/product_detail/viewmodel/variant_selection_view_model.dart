import 'package:flutter/foundation.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_model.dart';
import '../../../core/utils/stock_helper.dart';

class VariantSelectionViewModel extends ChangeNotifier {
  final ProductModel product;
  final List<String?> _selected;

  VariantSelectionViewModel(this.product)
    : _selected = _defaultSelection(product);

  List<String?> get selected => List.unmodifiable(_selected);

  static List<String?> _defaultSelection(ProductModel p) {
    if (!p.hasVariants) return [];
    // Detail produk dimulai tanpa varian aktif. Pengguna harus memilih
    // varian sendiri; foto utama tetap tampil sampai ada pilihan varian.
    return List<String?>.filled(p.variantOptions.length, null);
  }

  static bool _isAvailable(ProductModel p, int axis, String value, List<String?> cur) {
    return p.variants.any((v) => v.options[axis] == value && cur.asMap().entries.every((e) => e.key == axis || e.value == null || v.options[e.key] == e.value));
  }

  bool isValueAvailable(int axis, String value) => _isAvailable(product, axis, value, _selected);

  void selectOption(int axis, String value) {
    if (_selected[axis] == value) {
      _selected[axis] = null;
      notifyListeners();
      return;
    }
    _selected[axis] = value;
    notifyListeners();
  }

  void restoreSelection(List<String?> values) {
    if (!product.hasVariants) return;
    for (var i = 0; i < _selected.length; i++) {
      _selected[i] = i < values.length ? values[i] : null;
    }
    notifyListeners();
  }

  /// Sinkronkan selector saat pembeli memilih foto yang sudah ditautkan ke
  /// satu nilai atau kombinasi varian.
  void selectImageCombination(List<Map<String, String>> combination) {
    if (!product.hasVariants || combination.isEmpty) return;
    final next = List<String?>.of(_selected);
    for (final part in combination) {
      final axis = product.variantOptions.indexWhere((option) => option.name == part['option']);
      final value = part['value'];
      if (axis >= 0 && value != null && product.variantOptions[axis].values.contains(value)) {
        next[axis] = value;
      }
    }
    for (var axis = 0; axis < product.variantOptions.length; axis++) {
      if (next[axis] != null && _isAvailable(product, axis, next[axis]!, next)) continue;
      next[axis] = null;
      for (final value in product.variantOptions[axis].values) {
        if (_isAvailable(product, axis, value, next)) {
          next[axis] = value;
          break;
        }
      }
    }
    var changed = false;
    for (var i = 0; i < next.length; i++) {
      if (_selected[i] != next[i]) changed = true;
      _selected[i] = next[i];
    }
    if (changed) notifyListeners();
  }

  VariantModel? get matchedVariant {
    if (!product.hasVariants) return product.variants.isNotEmpty ? product.variants.first : null;
    if (_selected.any((s) => s == null)) return null;
    return product.variants.cast<VariantModel?>().firstWhere(
      (v) => v!.options.asMap().entries.every((e) => e.value == _selected[e.key]),
      orElse: () => null,
    );
  }

  String get variantLabel {
    if (!product.hasVariants) return 'Standar';
    final v = matchedVariant;
    if (v == null) return '—';
    return product.variantOptions.asMap().entries.map((e) => '${e.value.name}: ${v.options[e.key]}').join(', ');
  }

  /// Effective stock dari backend (atau dihitung jika offline)
  int effectiveStockForMatched(List<OrderModel> orders) {
    final v = matchedVariant;
    if (v == null) return 0;
    if (v.effectiveStock >= 0) {
      return v.effectiveStock;
    }
    final original = v.stock;
    final reserved = reservedCount(orders, product.id, variantLabel);
    return effectiveStock(original, reserved);
  }
}
