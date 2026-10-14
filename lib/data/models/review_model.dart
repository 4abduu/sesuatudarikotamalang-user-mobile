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
