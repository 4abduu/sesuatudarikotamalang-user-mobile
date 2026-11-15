class ReviewModel {
  final String id;
  final String? productId; // null = store review
  final String? orderItemId;
  final String author;
  final String city;
  final int rating;
  final String comment;
  final String date;
  final String status;
  final String? avatarUrl;
  final String? productName;

  const ReviewModel({
    required this.id,
    this.productId,
    this.orderItemId,
    required this.author,
    required this.city,
    required this.rating,
    required this.comment,
    required this.date,
    this.status = 'tampil',
    this.avatarUrl,
    this.productName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final product = json['product'] as Map<String, dynamic>?;

    final authorName = user?['name'] as String? ?? (json['author'] as String? ?? 'Pembeli');
    final avatar = user?['avatarUrl'] as String? ?? json['avatarUrl'] as String?;
    final prodName = product?['name'] as String? ?? json['productName'] as String?;

    return ReviewModel(
      id: (json['id'] ?? '').toString(),
      productId: json['productId'] as String?,
      orderItemId: json['orderItemId'] as String?,
      author: authorName,
      city: json['city'] as String? ?? 'Malang',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      date: (json['createdAt'] ?? json['date'] ?? '').toString(),
      status: json['status'] as String? ?? 'tampil',
      avatarUrl: avatar,
      productName: prodName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'orderItemId': orderItemId,
      'author': author,
      'city': city,
      'rating': rating,
      'comment': comment,
      'date': date,
      'status': status,
      'avatarUrl': avatarUrl,
      'productName': productName,
    };
  }
}

class ProductReviewsSummary {
  final double avgRating;
  final int reviewCount;
  final Map<int, int> breakdown;

  const ProductReviewsSummary({
    required this.avgRating,
    required this.reviewCount,
    required this.breakdown,
  });

  factory ProductReviewsSummary.fromJson(Map<String, dynamic> json) {
    final bd = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdownMap = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      breakdownMap[i] = (bd[i.toString()] as num?)?.toInt() ?? 0;
    }
    return ProductReviewsSummary(
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      breakdown: breakdownMap,
    );
  }
}

class ProductReviewsResult {
  final List<ReviewModel> reviews;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final ProductReviewsSummary summary;

  const ProductReviewsResult({
    required this.reviews,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.summary,
  });

  factory ProductReviewsResult.fromJson(Map<String, dynamic> json) {
    final list = (json['reviews'] as List<dynamic>? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pag = json['pagination'] as Map<String, dynamic>? ?? {};
    final sum = json['summary'] as Map<String, dynamic>? ?? {};
    return ProductReviewsResult(
      reviews: list,
      page: (pag['page'] as num?)?.toInt() ?? 1,
      limit: (pag['limit'] as num?)?.toInt() ?? 10,
      total: (pag['total'] as num?)?.toInt() ?? list.length,
      totalPages: (pag['totalPages'] as num?)?.toInt() ?? 1,
      summary: ProductReviewsSummary.fromJson(sum),
    );
  }
}
