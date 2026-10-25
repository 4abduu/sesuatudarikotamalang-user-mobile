import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../product_detail/providers/variant_selection_provider.dart';

enum ReservationStep { schedule, payment, result }
enum PaymentMethod { midtrans, cod }

/// Satu slot pickup dari GET /api/slots?date=YYYY-MM-DD.
/// Backend adalah sumber kebenaran: [isPast], [isClosed], dan [bookable] dihitung di server (WIB).
/// [isPast]: jam mulai sudah lewat. [isClosed]: pemesanan sudah ditutup (jam mulai lewat ATAU sudah
/// masuk jeda minimal sebelum jam mulai, default 30 menit).
class PickupSlot {
  final String time;
  final int capacity;
  final int booked;
  final int available;
  final bool isPast;
  final bool isClosed;
  final bool bookable;

  const PickupSlot({
    required this.time,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.isPast,
    required this.isClosed,
    required this.bookable,
  });

  factory PickupSlot.fromJson(
    Map<String, dynamic> j, {
    DateTime? selectedDate,
    int leadMinutes = 30,
  }) {
    final available = (j['available'] as num?)?.toInt() ?? 0;
    final timeStr = (j['time'] ?? '').toString();

    // Normalnya status slot datang dari backend (`isPast`, `isClosed`, `bookable`).
    // Blok fallback di bawah HANYA dipakai bila server belum mengirim `isPast` (backend lama) dan
    // boleh dihapus setelah backend baru ter-deploy: jam perangkat bukan sumber kebenaran.
    bool isPast = j['isPast'] == true;
    bool isClosed = j['isClosed'] is bool ? j['isClosed'] as bool : isPast;
    if (j['isPast'] == null && selectedDate != null && timeStr.isNotEmpty) {
      final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
      final dateWib = selectedDate.toUtc().add(const Duration(hours: 7));
      final isToday = nowWib.year == dateWib.year && nowWib.month == dateWib.month && nowWib.day == dateWib.day;
      if (isToday) {
        final parts = timeStr.split(':');
        if (parts.isNotEmpty) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final slotMinutes = hour * 60 + minute;
          final nowMinutes = nowWib.hour * 60 + nowWib.minute;
          if (slotMinutes <= nowMinutes) {
            isPast = true;
          }
          // Sudah masuk jeda minimal sebelum jam mulai: pemesanan ditutup.
          if (slotMinutes - leadMinutes <= nowMinutes) {
            isClosed = true;
          }
        }
      }
    }
    if (isPast) isClosed = true; // lewat selalu berarti ditutup

    return PickupSlot(
      time: timeStr,
      capacity: (j['capacity'] as num?)?.toInt() ?? 0,
      booked: (j['booked'] as num?)?.toInt() ?? 0,
      available: available,
      isPast: isPast,
      isClosed: isClosed,
      // Pakai field backend; fallback bila server lama belum mengirim `bookable`.
      bookable: j['bookable'] is bool ? j['bookable'] as bool : (!isClosed && available > 0),
    );
  }
}

class ReservationFlowProvider extends ChangeNotifier {
  /// Jendela pemesanan: hari ini sampai 14 hari ke depan (sama dengan batas backend).
  static const int maxAdvanceDays = 14;

  final ProductModel product;
  late final VariantSelectionProvider variantProvider;
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

  ReservationFlowProvider(this.product) {
    variantProvider = VariantSelectionProvider(product);
    // Tanggal awal hanya default tampilan (hari ini), bukan aturan pemesanan.
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    loadSlots();
  }

  String get productId => product.id;
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

  DateTime get firstDate => DateUtils.dateOnly(DateTime.now());
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
      final res = await ApiClient.get('/slots', queryParameters: {'date': dateToApi(date)});
      if (requestId != _slotsRequestId) return; // respons usang (tanggal sudah berganti)
      final list = (res is Map && res['slots'] is List) ? res['slots'] as List : <dynamic>[];
      if (res is Map && res['leadMinutes'] is num) {
        _leadMinutes = (res['leadMinutes'] as num).toInt();
      }
      _slots = list
          .whereType<Map>()
          .map((e) => PickupSlot.fromJson(Map<String, dynamic>.from(e), selectedDate: date, leadMinutes: _leadMinutes))
          .toList();
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
    _selectedDate = DateUtils.dateOnly(d);
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
  /// di dalam transaksi pembuatan order). Parameter [orders] dipertahankan agar pemanggil
  /// lama tetap kompatibel, tetapi tidak dipakai lagi: stok tidak dihitung ulang di mobile.
  /// Mengembalikan null bila lolos, atau pesan error.
  String? checkAtSubmit({List<OrderModel> orders = const []}) {
    final v = variantProvider.matchedVariant;
    if (product.hasVariants && v == null) return 'Pilih varian dulu';
    if (v == null) return 'Stok tidak tersedia';
    if (v.effectiveStock <= 0) {
      return 'Maaf, stok kombinasi ini baru saja habis. Silakan pilih varian lain.';
    }
    return null;
  }

  void setProcessing(bool v) { _processing = v; _safeNotify(); }
  void setPaid() { _paid = true; _safeNotify(); }

  void restart() {
    _step = ReservationStep.schedule;
    _paid = false;
    _processing = false;
    _selectedDate = DateUtils.dateOnly(DateTime.now());
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
    super.dispose();
  }
}