class VariantOptionModel {
  final String id;
  final String productId;
  final String name; // e.g. "Motif"
  final List<String> values; // e.g. ["Ubin", "Sulur"]
  final int sortOrder;

  const VariantOptionModel({
    this.id = '',
    this.productId = '',
    required this.name,
    required this.values,
    this.sortOrder = 0,
  });

  factory VariantOptionModel.fromJson(Map<String, dynamic> j) {
    return VariantOptionModel(
      id: j['id'] ?? '',
      productId: j['productId'] ?? '',
      name: j['name'] ?? '',
      values: (j['values'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'name': name,
    'values': values,
    'sortOrder': sortOrder,
  };
}
