import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/search_helper.dart';
import '../../../shared/app_scaffold.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../data/models/product_model.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['kategori'];
    if (q != null && _category == null) setState(() => _category = q);
  }

  List<ProductModel> get _filtered {
    var list = dummyProducts.where((p) => _category == null || p.categoryId == _category).toList();
    list = list.where((p) => matchesProductQuery(p, _search)).toList();
    switch (_sort) {
      case SortOption.terbaru: list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case SortOption.termurah: list.sort((a, b) => a.price.compareTo(b.price)); break;
      case SortOption.termahal: list.sort((a, b) => b.price.compareTo(a.price)); break;
      case SortOption.terlaris: list.sort((a, b) => b.soldCount.compareTo(a.soldCount)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Katalog',
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            hintText: 'Cari dalam katalog...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 12),
        CategoryFilterChips(selected: _category, onSelected: (v) => setState(() => _category = v)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Menampilkan ${_filtered.length} produk', style: AppTextStyles.caption),
          Row(children: [const Text('Urut: ', style: TextStyle(fontSize: 12)), SortDropdown(value: _sort, onChanged: (v) => setState(() => _sort = v ?? SortOption.terbaru))]),
        ]),
        const SizedBox(height: 12),
        ProductGridView(products: _filtered),
      ])),
    );
  }
}
