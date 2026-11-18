import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/order_status_helper.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

class OrderDetailViewModel extends ChangeNotifier {
  OrderDetailViewModel(this.orderId, {required OrderRepository repository}) : _repository = repository;
  final String orderId;
  final OrderRepository _repository;
  OrderModel? _order;
  OrderModel? get order => _order;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isProcessingAction = false;
  bool get isProcessingAction => _isProcessingAction;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _actionError;
  String? get actionError => _actionError;
  bool _disposed = false;
  int _requestId = 0;
  Timer? _timer;
  Timer? _paymentTimer;
  Completer<void>? _paymentDelay;
  bool _polling = false;
  String? _completedOrderNumber;
  String? get completedOrderNumber => _completedOrderNumber;

  Future<void> load({bool silent = false}) async {
    if (_disposed) return;
    final id = ++_requestId;
    if (!silent) _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final loaded = await _repository.getOrder(orderId);
      if (_disposed || id != _requestId) return;
      _order = loaded;
    } catch (e) {
      if (_disposed || id != _requestId) return;
      _errorMessage = e.toString();
    } finally {
      if (!_disposed && id == _requestId) { _isLoading = false; _notify(); }
    }
  }

  /// Status terminal: pesanan tidak akan berubah lagi.
  static const _terminalStatuses = {
    OrderStatus.selesai,
    OrderStatus.dibatalkan,
    OrderStatus.kedaluwarsa,
  };

  Future<void> init() async {
    await load();
    _startPollingIfNeeded();
  }

  void _startPollingIfNeeded() {
    if (_disposed || _order == null) return;
    final status = effectiveStatus(_order!);
    if (_terminalStatuses.contains(status)) {
      _timer?.cancel();
      return;
    }
    // Status non-terminal (menungguBayar, lunas, lewatBatas) → poll tiap 5 detik
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_disposed || _polling || _isProcessingAction) return;
    _polling = true;
    await load(silent: true);
    _polling = false;
    if (_disposed || _errorMessage != null || _order == null) return;
    final status = effectiveStatus(_order!);
    if (status == OrderStatus.selesai) {
      _timer?.cancel();
      _completedOrderNumber = _order!.orderNumber;
      _notify();
    } else if (_terminalStatuses.contains(status)) {
      _timer?.cancel();
      _notify();
    }
  }

  Future<bool> cancel() async {
    if (_disposed || _isProcessingAction) return false;
    _isProcessingAction = true;
    _actionError = null;
    ++_requestId;
    _notify();
    try {
      final updated = await _repository.cancel(orderId);
      if (_disposed) return false;
      if (updated != null) _order = updated;
      return true;
    } catch (e) {
      _actionError = 'Gagal membatalkan: $e';
      return false;
    } finally { _isProcessingAction = false; _notify(); }
  }

  Future<String?> payAgain() async {
    if (_disposed || _isProcessingAction) return null;
    _isProcessingAction = true;
    _actionError = null;
    _notify();
    try {
      Map<String, dynamic>? snap = _order?.snap;
      var url = snap?['redirect_url'] as String?;
      if (url == null || url.isEmpty) {
        try {
          snap = await _repository.pay(orderId);
        } on ApiException catch (e) {
          if ((e.status == 409 || e.code == 'PAYMENT_ALREADY_CREATED') && _order?.snap != null) {
            snap = _order!.snap;
          } else { rethrow; }
        }
        if (_disposed) return null;
        if (snap != null) _order = _order?.copyWith(snap: snap);
        url = snap?['redirect_url'] as String?;
      }
      if (url == null || url.isEmpty) throw 'Gagal mendapatkan tautan pembayaran.';
      return url;
    } catch (e) {
      _actionError = 'Pembayaran: $e';
      return null;
    } finally { _isProcessingAction = false; _notify(); }
  }

  Future<bool> checkPayment() async {
    if (_disposed || _isProcessingAction) return false;
    _isProcessingAction = true;
    _notify();
    var confirmed = false;
    try {
      for (var i = 0; i < 10; i++) {
        final delay = Completer<void>();
        _paymentDelay = delay;
        _paymentTimer = Timer(const Duration(seconds: 3), delay.complete);
        await delay.future;
        if (_disposed) return false;
        await load(silent: true);
        if (_errorMessage == null && _order?.status == OrderStatus.lunas) { confirmed = true; break; }
      }
      if (!_disposed) await load();
      return confirmed;
    } finally { _isProcessingAction = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() {
    _disposed = true; ++_requestId;
    _timer?.cancel(); _paymentTimer?.cancel();
    if (_paymentDelay != null && !_paymentDelay!.isCompleted) _paymentDelay!.complete();
    super.dispose();
  }
}
