import '../../data/models/product_model.dart';
import '../../data/models/creator_model.dart';

/// Local katalog search: matches a product by name or short description.
/// Returns true if query is empty.
bool matchesProductQuery(ProductModel product, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return product.name.toLowerCase().contains(q) ||
      product.shortDesc.toLowerCase().contains(q);
}

/// Local daftar kreator search: matches by name, handle, or specialty.
/// Returns true if query is empty.
bool matchesCreatorQuery(CreatorModel creator, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return creator.name.toLowerCase().contains(q) ||
      creator.handle.toLowerCase().contains(q) ||
      creator.specialty.toLowerCase().contains(q);
}

/// Global search: product matches query directly.
/// Used by the global search results screen at `/pencarian`.
bool productMatchesGlobalSearch(ProductModel product, String query) {
  return matchesProductQuery(product, query);
}
