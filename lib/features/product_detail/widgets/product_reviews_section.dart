import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../account/providers/reviews_provider.dart';

class ProductReviewsSection extends StatefulWidget {
  final ProductModel product;
  const ProductReviewsSection({super.key, required this.product});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final reviews = await context.read<ReviewsProvider>().fetchProductReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.product.rating.toStringAsFixed(1), style: AppTextStyles.h1),
        const SizedBox(width: 8),
        RatingStars(value: widget.product.rating, size: 16),
        const SizedBox(width: 8),
        Text('${widget.product.reviewCount} ulasan', style: AppTextStyles.caption),
      ]),
      const SizedBox(height: 12),
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        )
      else if (_reviews.isEmpty)
        Text('Belum ada ulasan untuk produk ini.', style: AppTextStyles.bodyMuted)
      else
        ..._reviews.map((r) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.format_quote, size: 16, color: AppColors.border),
              Text(r.comment, style: AppTextStyles.body),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: AppTextStyles.label),
                    Text('${r.city} · ${r.date.length >= 10 ? r.date.substring(0, 10) : r.date}', style: AppTextStyles.caption),
                  ],
                ),
                RatingStars(value: r.rating.toDouble(), size: 12),
              ]),
            ]),
          ),
        )),
    ]);
  }
}
