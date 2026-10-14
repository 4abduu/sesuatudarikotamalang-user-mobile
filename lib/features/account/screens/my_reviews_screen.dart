import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../features/account/providers/reviews_provider.dart';
import '../../../shared/app_scaffold.dart';

import '../../../data/models/product_model.dart';
import '../../../features/catalog/providers/products_provider.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsProvider>().fetchMyReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>();
    final products = context.watch<ProductsProvider>();
    final mine = reviews.reviews;

    return AppScaffold(
      title: 'Ulasan Saya',
      body: RefreshIndicator(
        onRefresh: () => reviews.fetchMyReviews(),
        child: reviews.isLoading && mine.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : mine.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Belum ada ulasan dari kamu.')),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: mine.length,
                    itemBuilder: (_, i) {
                      final r = mine[i];
                      final prod = products.products.cast<ProductModel?>().firstWhere(
                        (p) => p?.id == r.productId,
                        orElse: () => null,
                      );
                      final displayName = r.productName ?? prod?.name ?? 'Produk DariKota Malang';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              RatingStars(value: r.rating.toDouble(), size: 14),
                              const SizedBox(height: 8),
                              Text(r.comment, style: AppTextStyles.body),
                              const SizedBox(height: 4),
                              Text(r.date, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
