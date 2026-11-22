import 'package:go_router/go_router.dart';
import '../../../core/utils/infinite_scroll.dart';
import '../../../core/widgets/load_more_footer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rating_stars.dart';
import '../viewmodel/my_reviews_view_model.dart';
import '../../../shared/app_scaffold.dart';


class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    setupInfiniteScroll(
      controller: _scrollController,
      onLoadMore: () => context.read<MyReviewsViewModel>().loadMore(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyReviewsViewModel>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<MyReviewsViewModel>();
    final mine = reviews.reviews;

    return AppScaffold(
      title: 'Ulasan Saya',
      body: RefreshIndicator(
        onRefresh: () => reviews.load(),
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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: mine.length + 1,
                    itemBuilder: (_, i) {
                      if (i == mine.length) {
                        return LoadMoreFooter(
                          isLoading: reviews.isLoadingMore,
                          hasMore: reviews.hasMore,
                          isEmpty: mine.isEmpty,
                        );
                      }
                      final r = mine[i];
                      final displayName = r.productName ?? 'Produk DariKota Malang';

                      final hasProduct = r.productId != null && r.productId!.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: hasProduct
                              ? () => context.push(
                                    '/produk/${r.productId}/ulasan?reviewId=${Uri.encodeComponent(r.id)}',
                                  )
                              : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(displayName, style: AppTextStyles.h3.copyWith(height: 1.2)),
                                    ),
                                    if (hasProduct) ...[
                                      const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                RatingStars(value: r.rating.toDouble(), size: 14),
                                const SizedBox(height: 8),
                                Text(r.comment, style: AppTextStyles.body.copyWith(height: 1.375)),
                                const SizedBox(height: 4),
                                Text(r.date, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
