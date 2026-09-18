import 'package:flutter/material.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/variant_model.dart';
import '../../../core/utils/stock_helper.dart';

class VariantSelectionProvider extends ChangeNotifier {
  final ProductModel product;
  final List<String?> _selected;

  VariantSelectionProvider(this.product)
    : _selected = _defaultSelection(product);

  List<String?> get selected => List.unmodifiable(_selected);

  static List<String?> _defaultSelection(ProductModel p) {
    if (!p.hasVariants) return [];
    final sel = List<String?>.filled(p.variantOptions.length, null);
    for (var i = 0; i < p.variantOptions.length; i++) {
      for (final v in p.variantOptions[i].values) {
        if (_isAvailable(p, i, v, sel)) { sel[i] = v; break; }
      }
    }
    return sel;
  }

  static bool _isAvailable(ProductModel p, int axis, String value, List<String?> cur) {
    return p.variants.any((v) => v.options[axis] == value && cur.asMap().entries.every((e) => e.key == axis || e.value == null || v.options[e.key] == e.value));
  }

  bool isValueAvailable(int axis, String value) => _isAvailable(product, axis, value, _selected);

  void selectOption(int axis, String value) {
    _selected[axis] = value;
    for (var i = axis + 1; i < product.variantOptions.length; i++) {
      _selected[i] = null;
      for (final v in product.variantOptions[i].values) {
        if (_isAvailable(product, i, v, _selected)) { _selected[i] = v; break; }
      }
    }
    notifyListeners();
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

  /// Effective stock for the currently matched variant, accounting for
  /// already-reserved units (paid Lunas/Selesai + active MenungguBayar
  /// holds that haven't expired). Returns 0 if no variant is matched
  /// or the variant has no stock entry.
  ///
  /// For non-variant products, treats the variantLabel as 'Standar'.
  int effectiveStockForMatched(List<OrderModel> orders) {
    final v = matchedVariant;
    if (v == null) return 0;
    final original = v.stock;
    final reserved = reservedCount(orders, product.id, variantLabel);
    return effectiveStock(original, reserved);
  }
}
