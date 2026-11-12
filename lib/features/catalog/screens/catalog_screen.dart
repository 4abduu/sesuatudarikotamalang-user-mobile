import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/infinite_scroll.dart';
import '../../../core/widgets/app_search_decoration.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/products_provider.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/product_grid_view.dart';

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
  SortOption _sort = SortOption.terbaru;

  @override
  void initState() {
    super.initState();
    setupInfiniteScroll(
      controller: _scrollController,
      onLoadMore: () => context.read<ProductsProvider>().loadMoreCatalog(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductsProvider>();
      p.fetchCategories();
      _fetchCurrentCatalog(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['kategori'];
    if (q != null && _category == null) {
      _category = q;
      _fetchCurrentCatalog(reset: true);
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
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    context.read<ProductsProvider>().fetchCatalog(
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
    final productsProvider = context.watch<ProductsProvider>();
    final catalogList = productsProvider.catalogProducts;
    final total = productsProvider.catalogTotal;

    return AppScaffold(
      title: 'Katalog',
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchCurrentCatalog(reset: true);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
              if (productsProvider.isCatalogLoading && catalogList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                ProductGridView(products: catalogList),
                LoadMoreFooter(
                  isLoading: productsProvider.isCatalogLoadingMore,
                  hasMore: productsProvider.catalogHasMore,
                  isEmpty: catalogList.isEmpty,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
