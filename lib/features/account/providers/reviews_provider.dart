import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/review_model.dart';
import '../../../data/dummy/dummy_reviews.dart';

class ReviewsProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  static const _key = 'sdkm-user-reviews';

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _reviews = list.map((j) => ReviewModel.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _reviews = List.from(dummyReviews);
      }
    } catch (_) { _reviews = List.from(dummyReviews); }
    notifyListeners();
  }

  Future<void> addReview(ReviewModel review) async {
    _reviews = [review, ..._reviews];
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_reviews.map((r) => {'id': r.id, 'productId': r.productId, 'author': r.author, 'city': r.city, 'rating': r.rating, 'comment': r.comment, 'date': r.date}).toList()));
  }

  List<ReviewModel> reviewsForProduct(String productId) =>
    _reviews.where((r) => r.productId == productId).toList();

  List<ReviewModel> reviewsByUser(String userName) =>
    _reviews.where((r) => r.author == userName).toList();
}
