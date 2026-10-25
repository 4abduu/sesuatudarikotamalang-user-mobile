import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_search_decoration.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_card.dart';
import '../../../features/creators/widgets/creator_card.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/search_provider.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    context.read<SearchProvider>().search(query);
  }

  void _clear() {
    _controller.clear();
    context.read<SearchProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final q = _controller.text.trim();
    final hasQuery = q.isNotEmpty;
    final creators = searchProvider.creators;
    final products = searchProvider.products;

    return AppScaffold(
      title: 'Pencarian',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchBar(
              controller: _controller,
              onChanged: _onQueryChanged,
              onClear: _clear,
            ),
            const SizedBox(height: 12),
            if (searchProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!hasQuery)
              const _SearchPrompt()
            else if (creators.isEmpty && products.isEmpty)
              _EmptyResults(query: q)
            else ...[
              if (creators.isNotEmpty) ...[
                _SectionHeader(title: 'Kreator', count: creators.length),
                const SizedBox(height: 8),
                ...creators.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CreatorCard(
                      creator: c,
                      onTap: () => context.push('/kreator/${c.id}'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (products.isNotEmpty) ...[
                _SectionHeader(title: 'Produk', count: products.length),
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
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: appSearchTextStyle.copyWith(fontSize: 14),
      decoration: appSearchDecoration('Cari produk, motif, atau nama kreator...').copyWith(
        suffixIcon: controller.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: AppColors.primary),
                  ),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.manage_search, size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Mulai mencari', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Ketik nama produk, motif khas, atau nama artisan favoritmu.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Tidak ada hasil untuk "$query"',
      description: 'Coba kata kunci lain atau periksa ejaanmu.',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
