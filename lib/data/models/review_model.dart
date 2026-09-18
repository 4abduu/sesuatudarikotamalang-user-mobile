class ReviewModel {
  final String id;
  final String? productId; // null = store review
  final String author;
  final String city;
  final int rating;
  final String comment;
  final String date;
  const ReviewModel({
    required this.id, this.productId, required this.author, required this.city,
    required this.rating, required this.comment, required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      productId: json['productId'] as String?,
      author: json['author'] as String,
      city: json['city'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'author': author,
      'city': city,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }
}
