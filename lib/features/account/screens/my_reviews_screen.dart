import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/account/providers/reviews_provider.dart';
import '../../../shared/app_scaffold.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reviews = context.watch<ReviewsProvider>();
    final mine = reviews.reviewsByUser(auth.user?.name ?? '');
    return AppScaffold(
      title: 'Ulasan Saya',
      body: mine.isEmpty
        ? const Center(child: Text('Belum ada ulasan dari kamu.'))
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: mine.length, itemBuilder: (_, i) {
            final r = mine[i];
            final p = dummyProducts.firstWhere((p) => p.id == r.productId, orElse: () => dummyProducts.first);
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: AppTextStyles.h3),
              const SizedBox(height: 4),
              RatingStars(value: r.rating.toDouble(), size: 14),
              const SizedBox(height: 8),
              Text(r.comment, style: AppTextStyles.body),
              const SizedBox(height: 4),
              Text(r.date, style: AppTextStyles.caption),
            ])));
          }),
    );
  }
}
