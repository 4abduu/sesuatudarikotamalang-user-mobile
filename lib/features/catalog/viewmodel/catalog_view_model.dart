import 'package:flutter/foundation.dart';
import '../../../core/viewmodel/paged_state.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repositories.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel({required ProductRepository products, required CategoryRepository categories})
      : _productsRepository = products,
        _categoriesRepository = categories;

  final ProductRepository _productsRepository;
  final CategoryRepository _categoriesRepository;
  final PagedState<ProductModel> _page = PagedState<ProductModel>(limit: 12);
  List<CategoryModel> _categories = [];
  String? _activeCategory;
  String? _activeSearch;
  String? _activeSort;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get catalogProducts => _page.items;
  int get catalogTotal => _page.total;
  bool get catalogHasMore => _page.hasMore;
  bool get isCatalogLoading => _page.isLoading;
  bool get isCatalogLoadingMore => _page.isLoadingMore;
  String? get errorMessage => _page.error;

  Future<void> fetchCategories() async {
    try {
      _categories = await _categoriesRepository.getCategories();
      notifyListeners();
    } catch (_) {
      // Katalog tetap dapat menampilkan produk jika kategori gagal dimuat.
    }
  }

  Future<void> fetchCatalog({String? categoryId, String? search, String? sort, bool reset = true}) async {
    _activeCategory = categoryId;
    _activeSearch = search;
    _activeSort = sort;
    final requestId = reset ? _page.beginFirstPage() : _page.beginNextPage();
    notifyListeners();
    try {
      final result = await _productsRepository.getProducts(
        categoryId: categoryId,
        search: search,
        sort: sort,
        page: reset ? 1 : _page.page + 1,
        limit: _page.limit,
      );
      if (_page.isStale(requestId)) return;
      if (reset) {
        _page.applyFirstPage(result);
      } else {
        _page.applyNextPage(result);
      }
    } catch (error) {
      if (!_page.isStale(requestId)) _page.error = error.toString();
    } finally {
      if (!_page.isStale(requestId)) {
        _page.isLoading = false;
        _page.isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreCatalog() async {
    if (_page.isLoading || _page.isLoadingMore || !_page.hasMore) return;
    await fetchCatalog(categoryId: _activeCategory, search: _activeSearch, sort: _activeSort, reset: false);
  }
}
