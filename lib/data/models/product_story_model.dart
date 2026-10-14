class ProductStoryModel {
  final String id;
  final String productId;
  final String title;
  final String body; // atau content
  final String? process;
  final String? coverImageUrl;
  final List<String> processImages;

  const ProductStoryModel({
    this.id = '',
    this.productId = '',
    required this.title,
    required this.body,
    this.process,
    this.coverImageUrl,
    this.processImages = const [],
  });

  factory ProductStoryModel.fromJson(Map<String, dynamic> j) {
    return ProductStoryModel(
      id: j['id'] ?? '',
      productId: j['productId'] ?? '',
      title: j['title'] ?? '',
      body: j['body'] ?? j['content'] ?? '',
      process: j['process'],
      coverImageUrl: j['coverImageUrl'],
      processImages: (j['processImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'title': title,
    'content': body,
    if (process != null) 'process': process,
    if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    'processImages': processImages,
  };
}
