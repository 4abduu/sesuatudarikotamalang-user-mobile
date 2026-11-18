import 'package:flutter/material.dart';
import '../../../core/routing/back_navigation.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/infinite_scroll.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/review_card.dart';
import '../../../data/models/review_model.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/product_reviews_view_model.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;

  const ProductReviewsScreen({super.key, required this.productId});

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  int? _selectedRating; // null = Semua

  @override
  void initState() {
    super.initState();
    setupInfiniteScroll(
      controller: _scrollController,
      onLoadMore: _loadMore,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialLoad();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await context.read<ProductReviewsViewModel>().load(rating: _selectedRating);
  }

  Future<void> _refresh() async {
    await context.read<ProductReviewsViewModel>().load(rating: _selectedRating);
  }

  Future<void> _loadMore() async {
    final viewModel = context.read<ProductReviewsViewModel>();
    if (viewModel.isLoading || viewModel.isLoadingMore || !viewModel.hasMore) return;
    await viewModel.loadMore();
  }

  void _onFilterChanged(int? rating) {
    if (_selectedRating == rating) return;
    setState(() {
      _selectedRating = rating;
    });
    _initialLoad();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProductReviewsViewModel>();
    final reviews = viewModel.reviews;
    final summary = viewModel.summary;
    return AppScaffold(
      title: 'Semua Ulasan',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.popOrParent(),
      ),
      body: viewModel.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null && summary == null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (summary != null) _buildSummaryHeader(summary),
                              const SizedBox(height: 16),
                              if (summary != null) _buildFilterChips(summary),
                            ],
                          ),
                        ),
                      ),
                      if (viewModel.isLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (viewModel.errorMessage != null)
                        SliverToBoxAdapter(child: _buildErrorBanner())
                      else if (reviews.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == reviews.length) {
                                  return LoadMoreFooter(
                                    isLoading: viewModel.isLoadingMore,
                                    hasMore: viewModel.hasMore,
                                    isEmpty: reviews.isEmpty,
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ReviewCard(review: reviews[index]),
                                );
                              },
                              childCount: reviews.length + 1,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryHeader(ProductReviewsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kolom kiri: Nilai rata-rata & bintang
          SizedBox(
            width: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.avgRating > 0 ? summary.avgRating.toStringAsFixed(1) : '0',
                  style: AppTextStyles.h1.copyWith(fontSize: 36, height: 1.1),
                ),
                const SizedBox(height: 6),
                RatingStars(value: summary.avgRating, size: 14),
                const SizedBox(height: 6),
                Text(
                  '${summary.reviewCount} ulasan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 90, color: AppColors.border),
          const SizedBox(width: 12),
          // Kolom kanan: Distribusi bintang 5..1
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = summary.breakdown[star] ?? 0;
                final ratio = summary.reviewCount > 0 ? count / summary.reviewCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: AppColors.border.withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ProductReviewsSummary summary) {
    final chips = <Widget>[];

    // Chip "Semua"
    chips.add(_buildFilterChip(
      label: 'Semua (${summary.reviewCount})',
      isSelected: _selectedRating == null,
      isDisabled: false,
      onTap: () => _onFilterChanged(null),
    ));

    // Chip Bintang 5..1
    for (final star in [5, 4, 3, 2, 1]) {
      final count = summary.breakdown[star] ?? 0;
      final isDisabled = count == 0;
      final isSelected = _selectedRating == star;

      chips.add(_buildFilterChip(
        label: '$star ★ ($count)',
        isSelected: isSelected,
        isDisabled: isDisabled,
        onTap: isDisabled ? null : () => _onFilterChanged(star),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback? onTap,
  }) {
    Color bg;
    Color border;
    Color textColor;

    if (isDisabled) {
      bg = AppColors.border.withValues(alpha: 0.2);
      border = AppColors.border.withValues(alpha: 0.4);
      textColor = AppColors.muted;
    } else if (isSelected) {
      bg = AppColors.primary;
      border = AppColors.primary;
      textColor = Colors.white;
    } else {
      bg = AppColors.surface;
      border = AppColors.border;
      textColor = AppColors.foreground;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: textColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final text = _selectedRating != null
        ? 'Belum ada ulasan bintang $_selectedRating'
        : 'Belum ada ulasan untuk produk ini.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(text, style: AppTextStyles.bodyMuted),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Text(
            context.read<ProductReviewsViewModel>().errorMessage ?? 'Terjadi kesalahan.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _initialLoad,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.read<ProductReviewsViewModel>().errorMessage ?? 'Terjadi kesalahan.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _initialLoad,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
