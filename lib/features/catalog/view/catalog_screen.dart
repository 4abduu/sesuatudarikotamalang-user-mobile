import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/infinite_scroll.dart';
import '../../../core/widgets/app_search_decoration.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/catalog_view_model.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/sort_dropdown.dart';
import '../../../core/widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String? _category;
  SortOption _sort = SortOption.rekomendasi;
  bool _initializedFromUrl = false;

  @override
  void initState() {
    super.initState();
    setupInfiniteScroll(
      controller: _scrollController,
      onLoadMore: () => context.read<CatalogViewModel>().loadMoreCatalog(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CatalogViewModel>();
      p.fetchCategories();
      _fetchCurrentCatalog(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromUrl) {
      _initializedFromUrl = true;
      final q = GoRouterState.of(context).uri.queryParameters['kategori'];
      if (q != null && q.isNotEmpty) {
        _category = q;
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _serverSort(SortOption s) {
    switch (s) {
      case SortOption.rekomendasi:
        return 'rekomendasi';
      case SortOption.termurah:
        return 'termurah';
      case SortOption.termahal:
        return 'termahal';
      case SortOption.terlaris:
        return 'terlaris';
      case SortOption.terbaru:
        return null;
    }
  }

  void _fetchCurrentCatalog({bool reset = true}) {
    if (reset && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    context.read<CatalogViewModel>().fetchCatalog(
      categoryId: _category,
      search: _searchController.text.trim(),
      sort: _serverSort(_sort),
      reset: reset,
    );
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchCurrentCatalog(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<CatalogViewModel>();
    final catalogList = productsProvider.catalogProducts;
    final total = productsProvider.catalogTotal;

    return AppScaffold(
      title: 'Katalog',
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchCurrentCatalog(reset: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: appSearchTextStyle,
                      decoration: appSearchDecoration('Cari dalam katalog...'),
                    ),
                    const SizedBox(height: 12),
                    CategoryFilterChips(
                      selected: _category,
                      onSelected: (v) {
                        setState(() => _category = v);
                        _fetchCurrentCatalog(reset: true);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menampilkan $total produk',
                          style: AppTextStyles.caption,
                        ),
                        Row(
                          children: [
                            Text('Urut: ', style: AppTextStyles.caption),
                            SortDropdown(
                              value: _sort,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _sort = v);
                                  _fetchCurrentCatalog(reset: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (productsProvider.isCatalogLoading && catalogList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (catalogList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Tidak ada produk yang cocok.'),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final product = catalogList[i];
                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
                        onTap: () => context.pushNamed(
                          'productDetail',
                          pathParameters: {'id': product.id},
                        ),
                      );
                    },
                    childCount: catalogList.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: LoadMoreFooter(
                    isLoading: productsProvider.isCatalogLoadingMore,
                    hasMore: productsProvider.catalogHasMore,
                    isEmpty: catalogList.isEmpty,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}