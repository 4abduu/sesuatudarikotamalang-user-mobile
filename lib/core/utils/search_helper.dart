import '../../data/models/product_model.dart';
import '../../data/models/creator_model.dart';
import '../../data/dummy/dummy_categories.dart';
import '../../data/dummy/dummy_creators.dart';

/// Local katalog search: matches a product by name, short description,
/// category name, or creator name. Returns true if query is empty.
bool matchesProductQuery(ProductModel product, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final cat = dummyCategories.where((c) => c.id == product.categoryId).firstOrNull;
  final creator = dummyCreators.where((c) => c.id == product.creatorId).firstOrNull;
  return product.name.toLowerCase().contains(q) ||
      product.shortDesc.toLowerCase().contains(q) ||
      (cat?.name.toLowerCase().contains(q) ?? false) ||
      (creator?.name.toLowerCase().contains(q) ?? false);
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

/// Global search: product matches query OR product's creator matches query.
/// Used by the global search results screen at `/pencarian`.
bool productMatchesGlobalSearch(ProductModel product, String query) {
  if (matchesProductQuery(product, query)) return true;
  final creator = dummyCreators.where((c) => c.id == product.creatorId).firstOrNull;
  if (creator != null && matchesCreatorQuery(creator, query)) return true;
  return false;
}
