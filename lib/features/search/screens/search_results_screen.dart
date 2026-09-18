import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/search_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../features/creators/widgets/creator_card.dart';
import '../../../shared/app_scaffold.dart';

/// Global search screen pushed from the brand app bar's search icon.
///
/// Combines creator + product results into one scrollable view, using the
/// shared [matchesCreatorQuery] / [productMatchesGlobalSearch] helpers so the
/// matching rules stay in sync with the local search boxes on `/katalog` and
/// `/kreator`.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final v = _controller.text;
      if (v != _query) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final hasQuery = q.isNotEmpty;
    final List<CreatorModel> creators = hasQuery
        ? dummyCreators.where((c) => matchesCreatorQuery(c, q)).toList()
        : const <CreatorModel>[];
    final List<ProductModel> products = hasQuery
        ? dummyProducts.where((p) => productMatchesGlobalSearch(p, q)).toList()
        : const <ProductModel>[];
    final hasResults = hasQuery && (creators.isNotEmpty || products.isNotEmpty);

    return AppScaffold(
      title: 'Pencarian',
      showBottomNav: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari produk atau kreator...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.muted),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clear,
                        tooltip: 'Hapus',
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: !hasQuery
                ? const SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.search,
                      title: 'Mulai mencari',
                      description: 'Ketik kata kunci untuk mencari produk atau kreator.',
                    ),
                  )
                : hasResults
                    ? _resultsView(creators, products)
                    : SingleChildScrollView(
                        child: EmptyState(
                          icon: Icons.sentiment_dissatisfied,
                          title: 'Tidak ada hasil',
                          description: 'Tidak ada produk atau kreator yang cocok dengan \'$q\'.',
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _resultsView(List<CreatorModel> creators, List<ProductModel> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creators.isNotEmpty) ...[
            _sectionHeader('Kreator', creators.length),
            const SizedBox(height: 8),
            ...creators.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CreatorCard(
                    creator: c,
                    onTap: () => context.push('/kreator/${c.id}'),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (products.isNotEmpty) ...[
            _sectionHeader('Produk', products.length),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(
                product: products[i],
                onTap: () => context.push('/produk/${products[i].id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.h3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.baloo2(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
