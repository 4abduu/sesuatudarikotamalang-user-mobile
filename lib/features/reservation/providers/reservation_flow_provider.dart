import 'package:flutter/material.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../product_detail/providers/variant_selection_provider.dart';
import '../../../core/utils/stock_helper.dart';

enum ReservationStep { schedule, payment, result }
enum PaymentMethod { midtrans, cod }

class ReservationFlowProvider extends ChangeNotifier {
  final ProductModel product;
  late final VariantSelectionProvider variantProvider;
  ReservationStep _step = ReservationStep.schedule;
  DateTime? _selectedDate;
  String? _selectedSlot;
  PaymentMethod? _paymentMethod;
  bool _paid = false;
  bool _processing = false;

  ReservationFlowProvider(this.productId) : product = dummyProducts.firstWhere((p) => p.id == productId, orElse: () => dummyProducts.first) {
    variantProvider = VariantSelectionProvider(product);
  }

  final String productId;
  ReservationStep get step => _step;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  PaymentMethod? get paymentMethod => _paymentMethod;
  bool get paid => _paid;
  bool get processing => _processing;

  bool get canContinue => _selectedDate != null && _selectedSlot != null;

  void setDate(DateTime d) { _selectedDate = d; notifyListeners(); }
  void setSlot(String s) { _selectedSlot = s; notifyListeners(); }
  void setPaymentMethod(PaymentMethod m) { _paymentMethod = m; notifyListeners(); }
  void nextStep() { if (_step == ReservationStep.schedule) {
    _step = ReservationStep.payment;
  } else if (_step == ReservationStep.payment) {
    _step = ReservationStep.result;
  }
    notifyListeners();
  }
  void prevStep() {
    if (_step == ReservationStep.payment) {
      _step = ReservationStep.schedule;
    }
    notifyListeners();
  }

  /// Check-at-submit: validates stock at final "Pesan Sekarang".
  ///
  /// Pass the current user's [orders] so effective stock (original
  /// stock minus reserved units from paid orders + active holds)
  /// is checked, not just the raw stored stock.
  /// Returns null on success, error message on failure.
  String? checkAtSubmit({List<OrderModel> orders = const []}) {
    final v = variantProvider.matchedVariant;
    if (product.hasVariants && v == null) return 'Pilih varian dulu';
    if (v == null) return 'Stok tidak tersedia';
    final reserved = reservedCount(orders, product.id, variantProvider.variantLabel);
    final eff = effectiveStock(v.stock, reserved);
    if (eff <= 0) {
      return 'Maaf, stok kombinasi ini baru saja habis. Silakan pilih varian lain.';
    }
    return null;
  }

  void setProcessing(bool v) { _processing = v; notifyListeners(); }
  void setPaid() { _paid = true; notifyListeners(); }

  void restart() { _step = ReservationStep.schedule; _paid = false; _processing = false; _selectedDate = null; _selectedSlot = null; _paymentMethod = null; notifyListeners(); }
}
