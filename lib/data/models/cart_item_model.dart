class CartItemModel {
  final String id, productId, variantId, productName, variantLabel, status;
  final int quantity, maxQuantity, effectiveStock, unitPrice, lineTotal;
  final String? image;
  final List<String> options;
  CartItemModel({required this.id, required this.productId, required this.variantId, required this.productName, required this.variantLabel, required this.status, required this.quantity, required this.maxQuantity, required this.effectiveStock, required this.unitPrice, required this.lineTotal, this.image, this.options = const []});

  factory CartItemModel.fromJson(Map<String, dynamic> j) {
    final product = (j['product'] as Map?)?.cast<String, dynamic>() ?? {};
    final variant = (j['variant'] as Map?)?.cast<String, dynamic>() ?? {};
    final combo = (variant['combination'] as List?)?.map((e) => '$e').toList() ?? const <String>[];
    return CartItemModel(
      id: '${j['id'] ?? ''}', productId: '${j['productId'] ?? ''}', variantId: '${j['variantId'] ?? ''}',
      productName: '${product['name'] ?? 'Produk'}', variantLabel: combo.isEmpty ? 'Varian default' : combo.join(' / '),
      status: '${j['status'] ?? 'ok'}', quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      maxQuantity: (j['maxQuantity'] as num?)?.toInt() ?? 0, effectiveStock: (j['effectiveStock'] as num?)?.toInt() ?? 0,
      unitPrice: (j['unitPrice'] as num?)?.toInt() ?? 0, lineTotal: (j['lineTotal'] as num?)?.toInt() ?? 0,
      image: product['image']?.toString(),
      options: combo,
    );
  }
}
