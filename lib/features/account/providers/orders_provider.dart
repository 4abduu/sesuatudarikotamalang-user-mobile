import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  static const _key = 'sdkm-user-orders';

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> ordersForUser(String userId) =>
    _orders.where((o) => o.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _orders = list.map((j) => OrderModel.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _seed();
      }
    } catch (_) { _seed(); }
    notifyListeners();
  }

  void _seed() {
    final now = DateTime.now();
    _orders = [
      OrderModel(id: 'uo-seed-1', orderNumber: 'SDK-0231', userId: 'u-buyer', productId: 'pin-enamel-apel-malang', productName: 'Pin Enamel Apel Malang', variantLabel: 'Warna: Terakota', pickupDate: now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10), pickupSlot: '15:00', paymentMethod: 'Midtrans', status: OrderStatus.selesai, total: 35000, createdAt: now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10), reviewed: true, pickupDeadline: now.subtract(const Duration(days: 1)).toIso8601String()),
      OrderModel(id: 'uo-seed-2', orderNumber: 'SDK-0238', userId: 'u-buyer', productId: 'postcard-jendela-kayutangan', productName: 'Postcard Jendela Kayutangan', variantLabel: 'Motif: Jendela', pickupDate: now.toIso8601String().substring(0, 10), pickupSlot: '10:00', paymentMethod: 'Cash/QRIS', status: OrderStatus.menungguBayar, total: 12000, createdAt: now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10), holdExpiresAt: now.add(const Duration(hours: 2)).toIso8601String(), holdExtendedMinutes: 0),
      OrderModel(id: 'uo-seed-3', orderNumber: 'SDK-0210', userId: 'u-creator', productId: 'gantungan-kayu-daun', productName: 'Gantungan Kunci Kayu Daun', variantLabel: 'Motif: Daun Jati', pickupDate: now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10), pickupSlot: '11:00', paymentMethod: 'Midtrans', status: OrderStatus.selesai, total: 28000, createdAt: now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10), reviewed: false, pickupDeadline: now.add(const Duration(days: 12)).toIso8601String()),
    ];
  }

  Future<void> addOrder(OrderModel order) async {
    _orders = [order, ..._orders];
    notifyListeners();
    await _persist();
  }

  Future<void> setStatus(String id, OrderStatus status) async {
    _orders = _orders.map((o) => o.id == id ? o.copyWith(status: status) : o).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> markReviewed(String id) async {
    _orders = _orders.map((o) => o.id == id ? o.copyWith(reviewed: true) : o).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_orders.map((o) => o.toJson()).toList()));
  }

  String makeOrderNumber() {
    return 'SDK-${DateTime.now().millisecondsSinceEpoch % 10000 + 1000}';
  }
}
