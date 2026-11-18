import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sesuatu_darikota_malang/core/network/api_service.dart';
import 'package:sesuatu_darikota_malang/core/network/token_storage.dart';
import 'package:sesuatu_darikota_malang/data/repositories/catalog_repositories.dart';
import 'package:sesuatu_darikota_malang/features/catalog/viewmodel/app_config_view_model.dart';
import 'package:sesuatu_darikota_malang/features/catalog/viewmodel/catalog_view_model.dart';
import 'package:sesuatu_darikota_malang/features/product_detail/viewmodel/product_reviews_view_model.dart';

class _Tokens implements TokenStorage {
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> removeToken() async {}
}

void main() {
  test('Katalog load-more meminta halaman berikutnya tanpa mengulang produk', () async {
    final pages = <String?>[];
    final api = ApiService(baseUrl: 'http://localhost/api', tokenStorage: _Tokens(),
      client: MockClient((request) async {
        final page = request.url.queryParameters['page'];
        pages.add(page);
        return http.Response(jsonEncode({
          'products': [{'id': 'p$page', 'name': 'Produk $page'}],
          'pagination': {'total': 2, 'totalPages': 2},
        }), 200);
      }));
    final vm = CatalogViewModel(products: ProductRepository(api), categories: CategoryRepository(api));
    await vm.fetchCatalog();
    await vm.loadMoreCatalog();
    expect(pages, ['1', '2']);
    expect(vm.catalogProducts.map((p) => p.id), ['p1', 'p2']);
    expect(vm.catalogHasMore, isFalse);
    vm.dispose();
  });
  test('ProductRepository tidak mengirim page/limit bila tidak diminta', () async {
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: _Tokens(),
      client: MockClient((request) async {
        expect(request.url.queryParameters.containsKey('page'), isFalse);
        expect(request.url.queryParameters.containsKey('limit'), isFalse);
        return http.Response('{"products":[]}', 200);
      }),
    );
    final result = await ProductRepository(api).getProducts();
    expect(result.items, isEmpty);
    expect(result.totalPages, 1);
  });

  test('AppConfigViewModel membersihkan WA, teks kosong, dan marketplace', () async {
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: _Tokens(),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/categories')) return http.Response('{"categories":[]}', 200);
        return http.Response(jsonEncode({'settings': {
          'whatsappAdminNumber': '+62 812-345',
          'contactEmail': '  ',
          'aboutDescription': ' Tentang Malang ',
          'olshopStores': {'shopee': 'https://shopee.co.id/sdkm'},
        }}), 200);
      }),
    );
    final vm = AppConfigViewModel(categories: CategoryRepository(api), settings: SettingsRepository(api));
    await vm.init();
    expect(vm.whatsappAdminNumber, '62812345');
    expect(vm.contactEmail, isNull);
    expect(vm.aboutDescription, 'Tentang Malang');
    expect(vm.settingsOk, isTrue);
  });

  test('ReviewRepository memakai fallback legacy saat endpoint ulasan produk gagal', () async {
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: _Tokens(),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/products/p1/reviews')) {
          return http.Response('{"error":"belum tersedia"}', 404);
        }
        return http.Response(jsonEncode({'reviews': [
          {'id': 'r1', 'productId': 'p1', 'rating': 5, 'comment': 'Bagus'},
        ]}), 200);
      }),
    );
    final result = await ReviewRepository(api).getProductReviewsPaginated('p1');
    expect(result.reviews, hasLength(1));
    expect(result.reviews.single.productId, 'p1');
  });

  test('ProductReviewsViewModel memuat halaman dan load-more', () async {
    final api = ApiService(
      baseUrl: 'http://localhost/api',
      tokenStorage: _Tokens(),
      client: MockClient((request) async {
        final page = request.url.queryParameters['page'];
        return http.Response(jsonEncode({
          'reviews': [
            {'id': 'r$page', 'productId': 'p1', 'rating': 5, 'comment': 'Bagus'},
          ],
          'pagination': {'page': int.parse(page!), 'limit': 10, 'total': 2, 'totalPages': 2},
          'summary': {'avgRating': 5, 'reviewCount': 2, 'breakdown': {'5': 2}},
        }), 200);
      }),
    );
    final vm = ProductReviewsViewModel(productId: 'p1', repository: ReviewRepository(api));
    await vm.load();
    expect(vm.reviews, hasLength(1));
    expect(vm.hasMore, isTrue);
    await vm.loadMore();
    expect(vm.reviews, hasLength(2));
    expect(vm.isLoadingMore, isFalse);
  });
}
