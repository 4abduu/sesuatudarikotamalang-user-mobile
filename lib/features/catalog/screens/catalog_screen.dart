import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/search_helper.dart';
import '../../../core/widgets/app_search_decoration.dart';
import '../../../shared/app_scaffold.dart';
import '../../../data/models/product_model.dart';
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
  String? _category;
  String _search = '';
  SortOption _sort = SortOption.terbaru;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductsProvider>();
      p.fetchCategories();
      p.fetchProducts(categoryId: _category);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['kategori'];
    if (q != null && _category == null) {
      setState(() => _category = q);
      context.read<ProductsProvider>().fetchProducts(categoryId: q);
    }
  }

  List<ProductModel> _filterAndSort(List<ProductModel> products) {
    var list = products.where((p) {
      if (_category == null || _category!.isEmpty) return true;
      return p.categoryId == _category;
    }).toList();

    list = list.where((p) => matchesProductQuery(p, _search)).toList();

    switch (_sort) {
      case SortOption.terbaru:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.termurah:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.termahal:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.terlaris:
        list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final allProducts = productsProvider.products;
    final filtered = _filterAndSort(allProducts);

    return AppScaffold(
      title: 'Katalog',
      body: RefreshIndicator(
        onRefresh: () => productsProvider.fetchProducts(categoryId: _category),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // px-4 pt-4 pb-6
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) => setState(() => _search = v),
                style: appSearchTextStyle,
                decoration: appSearchDecoration('Cari dalam katalog...'),
              ),
              const SizedBox(height: 12),
              CategoryFilterChips(
                selected: _category,
                onSelected: (v) {
                  setState(() => _category = v);
                  // Refresh atau fetch sesuai kategori
                  productsProvider.fetchProducts(categoryId: v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Menampilkan ${filtered.length} produk', style: AppTextStyles.caption),
                  Row(
                    children: [
                      Text('Urut: ', style: AppTextStyles.caption),
                      SortDropdown(
                        value: _sort,
                        onChanged: (v) => setState(() => _sort = v ?? SortOption.terbaru),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (productsProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ProductGridView(products: filtered),
            ],
          ),
        ),
      ),
    );
  }
}
