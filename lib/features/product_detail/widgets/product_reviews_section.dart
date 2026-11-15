import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/review_card.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../account/providers/reviews_provider.dart';

class ProductReviewsSection extends StatefulWidget {
  final ProductModel product;
  const ProductReviewsSection({super.key, required this.product});

  /// Jumlah maksimal ulasan yang ditampilkan di preview halaman detail produk
  static const int kReviewPreviewCount = 3;

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
    final reviews = await context.read<ReviewsProvider>().fetchProductReviews(
      widget.product.id,
      limit: ProductReviewsSection.kReviewPreviewCount,
    );
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.product.reviewCount;
    final displayReviews = _reviews.take(ProductReviewsSection.kReviewPreviewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.product.rating.toStringAsFixed(1), style: AppTextStyles.h1),
            const SizedBox(width: 8),
            RatingStars(value: widget.product.rating, size: 16),
            const SizedBox(width: 8),
            Text('$totalCount ulasan', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (displayReviews.isEmpty)
          Text('Belum ada ulasan untuk produk ini.', style: AppTextStyles.bodyMuted)
        else ...[
          ...displayReviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ReviewCard(review: r),
          )),
          if (totalCount > ProductReviewsSection.kReviewPreviewCount) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => context.push('${RouteNames.productDetail}/${widget.product.id}/ulasan'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat semua ulasan ($totalCount)',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
