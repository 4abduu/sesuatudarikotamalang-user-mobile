class VariantModel {
  final String id;
  final String productId;
  final List<String> options; // matching combination
  final int stock;
  final int effectiveStock;

  const VariantModel({
    this.id = '',
    this.productId = '',
    required this.options,
    required this.stock,
    this.effectiveStock = 0,
  });

  factory VariantModel.fromJson(Map<String, dynamic> j) {
    final combo = (j['combination'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return VariantModel(
      id: j['id'] ?? '',
      productId: j['productId'] ?? '',
      options: combo,
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      effectiveStock: (j['effectiveStock'] as num?)?.toInt() ?? ((j['stock'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'combination': options,
    'stock': stock,
    'effectiveStock': effectiveStock,
  };
}
