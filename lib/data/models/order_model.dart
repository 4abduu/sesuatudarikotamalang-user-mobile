enum OrderStatus {
  menungguBayar, lunas, selesai, dibatalkan, kedaluwarsa, lewatBatas,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.menungguBayar: return 'Menunggu Bayar';
      case OrderStatus.lunas: return 'Lunas';
      case OrderStatus.selesai: return 'Selesai';
      case OrderStatus.dibatalkan: return 'Dibatalkan';
      case OrderStatus.kedaluwarsa: return 'Kedaluwarsa';
      case OrderStatus.lewatBatas: return 'Lewat Batas Pengambilan';
    }
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String productId;
  final String productName;
  final String variantLabel;
  final String pickupDate;
  final String pickupSlot;
  final String paymentMethod; // "Midtrans" | "Cash/QRIS"
  final OrderStatus status;
  final int total;
  final String createdAt;
  final bool reviewed;
  final String? holdExpiresAt;
  final int holdExtendedMinutes;
  final String? pickupDeadline;

  const OrderModel({
    required this.id, required this.orderNumber, required this.userId,
    required this.productId, required this.productName, required this.variantLabel,
    required this.pickupDate, required this.pickupSlot, required this.paymentMethod,
    required this.status, required this.total, required this.createdAt,
    this.reviewed = false, this.holdExpiresAt, this.holdExtendedMinutes = 0,
    this.pickupDeadline,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'], orderNumber: j['orderNumber'], userId: j['userId'],
    productId: j['productId'], productName: j['productName'], variantLabel: j['variantLabel'],
    pickupDate: j['pickupDate'], pickupSlot: j['pickupSlot'], paymentMethod: j['paymentMethod'],
    status: _statusFromStr(j['status']), total: j['total'], createdAt: j['createdAt'],
    reviewed: j['reviewed'] ?? false, holdExpiresAt: j['holdExpiresAt'],
    holdExtendedMinutes: j['holdExtendedMinutes'] ?? 0, pickupDeadline: j['pickupDeadline'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'orderNumber': orderNumber, 'userId': userId, 'productId': productId,
    'productName': productName, 'variantLabel': variantLabel, 'pickupDate': pickupDate,
    'pickupSlot': pickupSlot, 'paymentMethod': paymentMethod,
    'status': _statusToStr(status), 'total': total, 'createdAt': createdAt,
    'reviewed': reviewed, 'holdExpiresAt': holdExpiresAt,
    'holdExtendedMinutes': holdExtendedMinutes, 'pickupDeadline': pickupDeadline,
  };

  OrderModel copyWith({
    OrderStatus? status, bool? reviewed, String? holdExpiresAt, int? holdExtendedMinutes,
  }) => OrderModel(
    id: id, orderNumber: orderNumber, userId: userId, productId: productId,
    productName: productName, variantLabel: variantLabel, pickupDate: pickupDate,
    pickupSlot: pickupSlot, paymentMethod: paymentMethod, status: status ?? this.status,
    total: total, createdAt: createdAt, reviewed: reviewed ?? this.reviewed,
    holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
    holdExtendedMinutes: holdExtendedMinutes ?? this.holdExtendedMinutes,
    pickupDeadline: pickupDeadline,
  );

  static OrderStatus _statusFromStr(String s) {
    return OrderStatus.values.firstWhere(
      (e) => _statusToStr(e) == s,
      orElse: () => OrderStatus.menungguBayar,
    );
  }
  static String _statusToStr(OrderStatus s) {
    switch (s) {
      case OrderStatus.menungguBayar: return 'Menunggu Bayar';
      case OrderStatus.lunas: return 'Lunas';
      case OrderStatus.selesai: return 'Selesai';
      case OrderStatus.dibatalkan: return 'Dibatalkan';
      case OrderStatus.kedaluwarsa: return 'Kedaluwarsa';
      case OrderStatus.lewatBatas: return 'Lewat Batas Pengambilan';
    }
  }
}
