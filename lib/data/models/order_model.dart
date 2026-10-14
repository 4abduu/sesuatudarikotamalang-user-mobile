enum OrderStatus {
  menungguBayar,
  lunas,
  selesai,
  dibatalkan,
  kedaluwarsa,
  lewatBatas,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.menungguBayar:
        return 'Menunggu Bayar';
      case OrderStatus.lunas:
        return 'Lunas';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.dibatalkan:
        return 'Dibatalkan';
      case OrderStatus.kedaluwarsa:
        return 'Kedaluwarsa';
      case OrderStatus.lewatBatas:
        return 'Lewat Batas Pengambilan';
    }
  }

  String get backendString {
    switch (this) {
      case OrderStatus.menungguBayar:
        return 'menunggu_bayar';
      case OrderStatus.lunas:
        return 'lunas';
      case OrderStatus.selesai:
        return 'selesai';
      case OrderStatus.dibatalkan:
        return 'dibatalkan';
      case OrderStatus.kedaluwarsa:
        return 'kedaluwarsa';
      case OrderStatus.lewatBatas:
        return 'lewat_batas_pengambilan';
    }
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String variantLabel;
  final int price;
  final int quantity;

  const OrderItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.price,
    this.quantity = 1,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) {
    final prod = j['product'] as Map<String, dynamic>?;
    final variant = j['variant'] as Map<String, dynamic>?;

    String vLabel = 'Standar';
    if (variant != null && variant['combination'] != null) {
      final combo = (variant['combination'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (combo.isNotEmpty) {
        vLabel = combo.join(', ');
      }
    }

    return OrderItemModel(
      id: j['id'] ?? '',
      productId: j['productId'] ?? (prod?['id'] ?? ''),
      variantId: j['variantId'],
      productName: prod?['name'] ?? (j['productName'] ?? 'Karya Artisan'),
      variantLabel: j['variantLabel'] ?? vLabel,
      price: (j['priceSnapshot'] as num?)?.toInt() ?? ((j['price'] as num?)?.toInt() ?? 0),
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'variantId': variantId,
    'productName': productName,
    'variantLabel': variantLabel,
    'priceSnapshot': price,
    'quantity': quantity,
  };
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String productId;
  final String productName;
  final String variantLabel;
  final String? variantId;
  final String pickupDate;
  final String pickupSlot;
  final String paymentMethod; // "midtrans" | "cod"
  final OrderStatus status;
  final int total;
  final String createdAt;
  final bool reviewed;
  final String? holdExpiresAt;
  final int holdExtendedMinutes;
  final String? pickupDeadline;
  final List<OrderItemModel> items;
  final Map<String, dynamic>? snap;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.variantLabel,
    this.variantId,
    required this.pickupDate,
    required this.pickupSlot,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.createdAt,
    this.reviewed = false,
    this.holdExpiresAt,
    this.holdExtendedMinutes = 0,
    this.pickupDeadline,
    this.items = const [],
    this.snap,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['items'] as List<dynamic>?)
            ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    String pId = j['productId'] ?? '';
    String pName = j['productName'] ?? '';
    String vLabel = j['variantLabel'] ?? '';
    String? vId = j['variantId'];

    if (rawItems.isNotEmpty) {
      pId = rawItems.first.productId;
      pName = rawItems.first.productName;
      vLabel = rawItems.first.variantLabel;
      vId = rawItems.first.variantId;
    }

    return OrderModel(
      id: j['id'] ?? '',
      orderNumber: j['orderNumber'] ?? '',
      userId: j['userId'] ?? '',
      productId: pId,
      productName: pName,
      variantLabel: vLabel,
      variantId: vId,
      pickupDate: j['pickupDate']?.toString().substring(0, 10) ?? '',
      pickupSlot: j['pickupSlot'] ?? '',
      paymentMethod: (j['paymentMethod'] ?? '').toString().toLowerCase(),
      status: _statusFromStr(j['status'] ?? ''),
      total: (j['totalAmount'] as num?)?.toInt() ?? ((j['total'] as num?)?.toInt() ?? 0),
      createdAt: j['createdAt']?.toString().substring(0, 10) ?? '',
      reviewed: j['reviewed'] ?? false,
      holdExpiresAt: j['holdExpiresAt'],
      holdExtendedMinutes: (j['holdExtendedMinutes'] as num?)?.toInt() ?? 0,
      pickupDeadline: j['pickupDeadline'],
      items: rawItems,
      snap: j['snap'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'userId': userId,
    'productId': productId,
    'productName': productName,
    'variantLabel': variantLabel,
    if (variantId != null) 'variantId': variantId,
    'pickupDate': pickupDate,
    'pickupSlot': pickupSlot,
    'paymentMethod': paymentMethod,
    'status': status.backendString,
    'totalAmount': total,
    'createdAt': createdAt,
    'reviewed': reviewed,
    'holdExpiresAt': holdExpiresAt,
    'holdExtendedMinutes': holdExtendedMinutes,
    'pickupDeadline': pickupDeadline,
    'items': items.map((e) => e.toJson()).toList(),
    if (snap != null) 'snap': snap,
  };

  OrderModel copyWith({
    OrderStatus? status,
    bool? reviewed,
    String? holdExpiresAt,
    int? holdExtendedMinutes,
    Map<String, dynamic>? snap,
  }) =>
      OrderModel(
        id: id,
        orderNumber: orderNumber,
        userId: userId,
        productId: productId,
        productName: productName,
        variantLabel: variantLabel,
        variantId: variantId,
        pickupDate: pickupDate,
        pickupSlot: pickupSlot,
        paymentMethod: paymentMethod,
        status: status ?? this.status,
        total: total,
        createdAt: createdAt,
        reviewed: reviewed ?? this.reviewed,
        holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
        holdExtendedMinutes: holdExtendedMinutes ?? this.holdExtendedMinutes,
        pickupDeadline: pickupDeadline,
        items: items,
        snap: snap ?? this.snap,
      );

  static OrderStatus _statusFromStr(String s) {
    final lower = s.toLowerCase();
    switch (lower) {
      case 'lunas':
        return OrderStatus.lunas;
      case 'selesai':
        return OrderStatus.selesai;
      case 'dibatalkan':
        return OrderStatus.dibatalkan;
      case 'kedaluwarsa':
        return OrderStatus.kedaluwarsa;
      case 'lewat_batas_pengambilan':
      case 'lewat batas pengambilan':
        return OrderStatus.lewatBatas;
      case 'menunggu_bayar':
      case 'menunggu bayar':
      default:
        return OrderStatus.menungguBayar;
    }
  }
}
