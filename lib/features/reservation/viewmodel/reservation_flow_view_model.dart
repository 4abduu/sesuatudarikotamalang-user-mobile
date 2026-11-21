import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_only.dart';
import '../../../data/models/pickup_slot.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/slot_repository.dart';
import '../../../data/repositories/catalog_repositories.dart';
import 'pickup_calendar_view_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../product_detail/viewmodel/variant_selection_view_model.dart';

enum ReservationStep { schedule, payment, result }
enum PaymentMethod { midtrans, cod }
enum ReservationSubmitResult { midtrans, cod, slotRejected, failed }

class ReservationFlowViewModel extends ChangeNotifier {
  /// Jendela pemesanan: hari ini sampai 14 hari ke depan (sama dengan batas backend).
  static const int maxAdvanceDays = 14;

  final String productId;
  final ProductRepository _products;
  final OrderRepository _orders;
  final SlotRepository _slotRepository;
  ProductModel? _product;
  ProductModel get product => _product!;
  bool get hasProduct => _product != null;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _actionError;
  String? get actionError => _actionError;
  VariantSelectionViewModel? _variantProvider;
  VariantSelectionViewModel get variantProvider => _variantProvider!;
  late final PickupCalendarViewModel calendar;
  int _productRequestId = 0;
  ReservationStep _step = ReservationStep.schedule;
  DateTime? _selectedDate;
  String? _selectedSlot;
  PaymentMethod? _paymentMethod;
  bool _paid = false;
  bool _processing = false;
  OrderModel? _createdOrder;

  List<PickupSlot> _slots = const [];
  int _leadMinutes = 30; // diperbarui dari respons GET /slots (leadMinutes)
  bool _slotsLoading = false;
  String? _slotsError;
  int _slotsRequestId = 0;
  bool _disposed = false;

  ReservationFlowViewModel(this.productId, {
    required ProductRepository products,
    required OrderRepository orders,
    required SlotRepository slots,
  }) : _products = products, _orders = orders, _slotRepository = slots {
    _selectedDate = dateOnly(DateTime.now());
    calendar = PickupCalendarViewModel(slots);
  }

  Future<void> load() async {
    final id = ++_productRequestId;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final loaded = await _products.getProduct(productId);
      if (_disposed || id != _productRequestId) return;
      _variantProvider?.dispose();
      _product = loaded;
      _variantProvider = VariantSelectionViewModel(loaded)..addListener(_safeNotify);
      await loadSlots();
    } catch (e) {
      if (_disposed || id != _productRequestId) return;
      _errorMessage = e.toString();
    } finally {
      if (!_disposed && id == _productRequestId) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  ReservationStep get step => _step;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  PaymentMethod? get paymentMethod => _paymentMethod;
  bool get paid => _paid;
  bool get processing => _processing;
  OrderModel? get createdOrder => _createdOrder;

  List<PickupSlot> get slots => _slots;
  /// Jeda minimal (menit) sebelum jam slot ketika pemesanan ditutup; dari backend.
  int get leadMinutes => _leadMinutes;
  bool get slotsLoading => _slotsLoading;
  String? get slotsError => _slotsError;

  DateTime get firstDate => dateOnly(DateTime.now());
  DateTime get lastDate => firstDate.add(const Duration(days: maxAdvanceDays));

  PickupSlot? get _selectedSlotInfo {
    for (final s in _slots) {
      if (s.time == _selectedSlot) return s;
    }
    return null;
  }

  /// Slot dipilih dan (menurut data backend terbaru) masih bisa dipesan.
  bool get canContinue =>
      _selectedDate != null && _selectedSlot != null && (_selectedSlotInfo?.bookable ?? false);

  /// True bila slot sudah dimuat dan tidak ada satu pun yang bisa dipesan di tanggal terpilih.
  bool get noBookableSlot => !_slotsLoading && _slotsError == null && _slots.isNotEmpty && !_slots.any((s) => s.bookable);

  /// Format tanggal kalender lokal YYYY-MM-DD (bukan toIso8601String, agar tidak bergeser zona).
  static String dateToApi(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void setCreatedOrder(OrderModel order) {
    _createdOrder = order;
    _safeNotify();
  }

  /// Muat ketersediaan slot dari backend untuk tanggal terpilih.
  Future<void> loadSlots() async {
    final date = _selectedDate;
    if (date == null) return;
    final requestId = ++_slotsRequestId;
    _slotsLoading = true;
    _slotsError = null;
    _safeNotify();
    try {
      final result = await _slotRepository.getSlots(date, leadMinutes: _leadMinutes);
      if (_disposed || requestId != _slotsRequestId) return;
      _leadMinutes = result.leadMinutes;
      _slots = result.slots;
      // Slot terpilih yang sekarang tidak bisa dipesan harus dilepas.
      if (_selectedSlot != null && !(_selectedSlotInfo?.bookable ?? false)) {
        _selectedSlot = null;
      }
    } on ApiException catch (e) {
      if (requestId != _slotsRequestId) return;
      _slots = const [];
      _selectedSlot = null;
      _slotsError = e.message;
    } catch (_) {
      if (requestId != _slotsRequestId) return;
      _slots = const [];
      _selectedSlot = null;
      _slotsError = 'Gagal memuat slot pickup. Periksa koneksi lalu coba lagi.';
    } finally {
      if (requestId == _slotsRequestId) {
        _slotsLoading = false;
        _safeNotify();
      }
    }
  }

  void setDate(DateTime d) {
    _selectedDate = dateOnly(d);
    _selectedSlot = null; // slot milik tanggal sebelumnya tidak berlaku
    loadSlots();
  }

  void setSlot(String s) {
    final info = _slots.where((x) => x.time == s);
    if (info.isEmpty || !info.first.bookable) return;
    _selectedSlot = s;
    _safeNotify();
  }

  void setPaymentMethod(PaymentMethod m) { _paymentMethod = m; _safeNotify(); }

  void nextStep() {
    if (_step == ReservationStep.schedule) {
      _step = ReservationStep.payment;
    } else if (_step == ReservationStep.payment) {
      _step = ReservationStep.result;
    }
    _safeNotify();
  }

  void prevStep() {
    if (_step == ReservationStep.payment) {
      _step = ReservationStep.schedule;
    }
    _safeNotify();
  }

  /// Dipakai saat backend menolak slot (SLOT_FULL / SLOT_PASSED): kembali ke langkah jadwal
  /// dengan tanggal yang sama, lepas slot, lalu muat ulang ketersediaan terbaru.
  void backToSchedule() {
    _step = ReservationStep.schedule;
    _selectedSlot = null;
    _processing = false;
    loadSlots();
  }

  /// Check-at-submit: pemeriksaan ringan di klien sebelum memanggil backend.
  ///
  /// Backend tetap sumber kebenaran stok (effectiveStock dihitung server dan dicek ulang
  /// di dalam transaksi pembuatan order); stok tidak dihitung ulang di mobile.
  /// Mengembalikan null bila lolos, atau pesan error.
  String? checkAtSubmit() {
    final v = variantProvider.matchedVariant;
    if (product.hasVariants && v == null) return 'Pilih varian dulu';
    if (v == null) return 'Stok tidak tersedia';
    if (v.effectiveStock <= 0) {
      return 'Maaf, stok kombinasi ini baru saja habis. Silakan pilih varian lain.';
    }
    return null;
  }

  Future<ReservationSubmitResult> submit() async {
    if (_processing || _disposed) return ReservationSubmitResult.failed;
    _actionError = checkAtSubmit();
    if (_actionError != null) {
      if (_actionError!.contains('habis')) restart();
      _safeNotify();
      return ReservationSubmitResult.failed;
    }
    if (_selectedDate == null || _selectedSlot == null || _paymentMethod == null) {
      return ReservationSubmitResult.failed;
    }
    final method = _paymentMethod!;
    _processing = true;
    _safeNotify();
    try {
      final variant = variantProvider.matchedVariant;
      final created = await _orders.create(
        productId: product.id,
        variantId: product.hasVariants ? variant?.id : null,
        pickupDate: _selectedDate!, pickupSlot: _selectedSlot!,
        paymentMethod: method.name,
      );
      if (_disposed) return ReservationSubmitResult.failed;
      _createdOrder = created;
      return method == PaymentMethod.midtrans
          ? ReservationSubmitResult.midtrans : ReservationSubmitResult.cod;
    } on ApiException catch (e) {
      if (_disposed) return ReservationSubmitResult.failed;
      _actionError = e.message;
      if (e.code == 'PRODUCT_UNAVAILABLE') {
        restart();
      } else if (const {'SLOT_FULL', 'SLOT_PASSED', 'SLOT_UNAVAILABLE', 'PICKUP_DATE_CLOSED'}.contains(e.code)) {
        backToSchedule();
        return ReservationSubmitResult.slotRejected;
      } else if (e.status == 409) {
        restart();
      }
      return ReservationSubmitResult.failed;
    } catch (e) {
      _actionError = 'Terjadi kesalahan: ${e.toString()}';
      return ReservationSubmitResult.failed;
    } finally {
      _processing = false;
      _safeNotify();
    }
  }

  void setProcessing(bool v) { _processing = v; _safeNotify(); }
  void setPaid() { _paid = true; _safeNotify(); }

  Future<bool> checkOrderPaid(String orderId) async {
    try {
      final o = await _orders.getOrder(orderId);
      if (o.status == OrderStatus.lunas || o.status == OrderStatus.selesai) {
        _paid = true;
        _createdOrder = o;
        _safeNotify();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void restart() {
    _step = ReservationStep.schedule;
    _paid = false;
    _processing = false;
    _selectedDate = dateOnly(DateTime.now());
    _selectedSlot = null;
    _paymentMethod = null;
    loadSlots();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_slotsRequestId;
    ++_productRequestId;
    _variantProvider?.dispose();
    calendar.dispose();
    super.dispose();
  }
}