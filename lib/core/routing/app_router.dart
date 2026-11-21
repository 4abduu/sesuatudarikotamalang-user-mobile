import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'route_names.dart';
import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/auth/viewmodel/login_view_model.dart';
import '../../features/auth/viewmodel/register_view_model.dart';
import '../../features/auth/viewmodel/forgot_password_view_model.dart';
import 'package:provider/provider.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/home/viewmodel/home_view_model.dart';
import '../../features/catalog/viewmodel/catalog_view_model.dart';
import '../../features/search/viewmodel/search_view_model.dart';
import '../../features/catalog/view/catalog_screen.dart';
import '../../features/product_detail/view/product_detail_screen.dart';
import '../../features/creators/view/creators_list_screen.dart';
import '../../features/creators/view/creator_profile_screen.dart';
import '../../features/creators/viewmodel/creators_list_view_model.dart';
import '../../features/creators/viewmodel/creator_profile_view_model.dart';
import '../../features/reservation/view/reservation_flow_screen.dart';
import '../../features/reservation/view/reservation_confirmation_screen.dart';
import '../../features/creator_application/view/creator_application_form_screen.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/register_screen.dart';
import '../../features/auth/view/forgot_password_screen.dart';
import '../../features/creator_dashboard/view/creator_dashboard_screen.dart';
import '../../features/creator_dashboard/view/my_products_screen.dart';
import '../../features/creator_dashboard/view/product_form_screen.dart';
import '../../features/creator_dashboard/view/my_stories_screen.dart';
import '../../features/creator_dashboard/view/story_form_screen.dart';
import '../../features/creator_dashboard/view/edit_store_profile_screen.dart';
import '../../features/creator_dashboard/view/creator_report_screen.dart';
import '../../features/creator_dashboard/view/creator_report_detail_screen.dart';
import '../../features/notifications/view/notifications_screen.dart';
import '../../features/account/view/account_home_screen.dart';
import '../../features/account/view/account_orders_screen.dart';
import '../../features/account/view/order_detail_screen.dart';
import '../../features/account/view/my_reviews_screen.dart';
import '../../features/account/view/write_review_screen.dart';
import '../../features/account/view/application_status_screen.dart';
import '../../features/account/view/account_settings_screen.dart';
import '../../features/search/view/search_results_screen.dart';
import '../../features/about/view/about_screen.dart';
import '../../features/product_detail/view/product_reviews_screen.dart';
import '../../features/product_detail/viewmodel/product_detail_view_model.dart';
import '../../features/product_detail/viewmodel/product_reviews_view_model.dart';
import '../../features/account/viewmodel/my_reviews_view_model.dart';
import '../../features/account/viewmodel/write_review_view_model.dart';
import '../../features/account/viewmodel/order_detail_view_model.dart';
import '../../features/account/viewmodel/profile_settings_view_model.dart';
import '../../features/account/viewmodel/change_email_view_model.dart';
import '../../features/account/viewmodel/change_password_view_model.dart';
import '../../features/account/viewmodel/application_status_view_model.dart';
import '../../features/account/viewmodel/orders_view_model.dart';
import '../../features/creator_application/viewmodel/application_form_view_model.dart';
import '../../features/creator_dashboard/viewmodel/creator_dashboard_view_model.dart';
import '../../features/creator_dashboard/viewmodel/creator_report_view_model.dart';
import '../../features/creator_dashboard/viewmodel/creator_report_detail_view_model.dart';
import '../../features/creator_dashboard/viewmodel/edit_store_profile_view_model.dart';
import '../../features/creator_dashboard/viewmodel/product_form_view_model.dart';
import '../../features/creator_dashboard/viewmodel/my_stories_view_model.dart';
import '../../features/creator_dashboard/viewmodel/story_form_view_model.dart';
import '../../features/creator_dashboard/viewmodel/story_ai_view_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/catalog_repositories.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/services/photo_picker_service.dart';
import '../viewmodel/photo_editor_view_model.dart';
import '../di/app_dependencies.dart';
import '../../data/repositories/slot_repository.dart';
import '../../features/reservation/viewmodel/reservation_flow_view_model.dart';

/// Rute yang butuh login — guest diarahkan ke `/login?next=<original>`.
/// Autentikasi dicek lewat [AuthViewModel] (ChangeNotifierProvider).
bool _isProtectedRoute(String location) {
  // Tab Akun (/akun persis) boleh dibuka tamu: layarnya menampilkan ajakan masuk
  // dan akses ke "Tentang Kami". Sub-halaman /akun/... tetap butuh login.
  if (Uri.tryParse(location)?.path == RouteNames.account) return false;
  return location.startsWith('/notifikasi') ||
      location.startsWith('/akun') ||
      location.startsWith('/dashboard-kreator') ||
      location.startsWith('/reservasi');
}

GoRouter buildAppRouter(AuthViewModel auth, AppDependencies dependencies) {
  return GoRouter(
    initialLocation: RouteNames.home,
    // Navigasi detail harus tercermin di URL browser agar refresh/deep-link
    // tetap membuka halaman yang sama, bukan kembali ke halaman list.
    routerNeglect: false,
    refreshListenable: auth, // re-redirect saat login/logout terjadi
    redirect: (context, state) {
      final location = state.uri.toString();
      // Hanya redirect kalau provider sudah hydrated (data session sudah
      // dimuat dari SharedPreferences). Sebelum hydrated, biarkan loading
      // screen yang menangani.
      if (!auth.hydrated) return null;
      if (!auth.isAuthenticated && _isProtectedRoute(location)) {
        final encoded = Uri.encodeComponent(location);
        return '/login?next=$encoded';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: RouteNames.home,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => HomeViewModel(
                    products: dependencies.products,
                    artisans: ArtisanRepository(dependencies.api),
                    reviews: ReviewRepository(dependencies.api),
                  )..init(),
              child: const HomeScreen())),
      GoRoute(
          path: RouteNames.catalog,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => CatalogViewModel(
                    products: dependencies.products,
                    categories: CategoryRepository(dependencies.api),
                  ),
              child: const CatalogScreen())),
      // Rute ulasan spesifik ditaruh SEBELUM :id umum agar tidak termakan parameter
      GoRoute(
          name: 'productReviews',
          path: '${RouteNames.productDetail}/:id/ulasan',
          builder: (_, s) {
            final id = s.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => ProductReviewsViewModel(
                  productId: id,
                  repository: ReviewRepository(dependencies.api)),
              child: ProductReviewsScreen(productId: id),
            );
          }),
      GoRoute(
          name: 'productDetail',
          path: '${RouteNames.productDetail}/:id',
          builder: (_, s) {
            final id = s.pathParameters['id']!;
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                    create: (_) => ProductDetailViewModel(
                          products: dependencies.products,
                          artisans: ArtisanRepository(dependencies.api),
                        )..load(id)),
                ChangeNotifierProvider(
                    create: (_) => ProductReviewsViewModel(
                          productId: id,
                          repository: ReviewRepository(dependencies.api),
                        )),
              ],
              child: ProductDetailScreen(productId: id),
            );
          }),
      GoRoute(
          path: RouteNames.creatorsList,
          builder: (_, __) => ChangeNotifierProvider(
                create: (_) => CreatorsListViewModel(
                    repository: ArtisanRepository(dependencies.api))
                  ..load(),
                child: const CreatorsListScreen(),
              )),
      GoRoute(
          name: 'creatorProfile',
          path: '${RouteNames.creatorProfile}/:id',
          builder: (_, s) {
            final id = s.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => CreatorProfileViewModel(
                  repository: ArtisanRepository(dependencies.api))
                ..load(id),
              child: CreatorProfileScreen(creatorId: id),
            );
          }),
      // Rute konfirmasi ditaruh LEBIH DULU agar tidak termakan parameter dinamis :productId
      GoRoute(
        path: RouteNames.reservationConfirm,
        builder: (_, s) => ChangeNotifierProvider(
          create: (_) =>
              OrdersViewModel(repository: OrderRepository(dependencies.api)),
          child: ReservationConfirmationScreen(
            orderNumber: s.uri.queryParameters['orderNumber'],
          ),
        ),
      ),
      GoRoute(
          path: '${RouteNames.reservation}/:productId',
          builder: (_, s) => ChangeNotifierProvider(
                create: (_) => ReservationFlowViewModel(
                  s.pathParameters['productId']!,
                   products: dependencies.products,
                  orders: OrderRepository(dependencies.api),
                  slots: SlotRepository(dependencies.api),
                ),
                child: ReservationFlowScreen(
                    productId: s.pathParameters['productId']!),
              )),
      GoRoute(
          path: RouteNames.daftarKreator,
          builder: (_, __) => ChangeNotifierProvider(
                create: (context) => ApplicationFormViewModel(
                    repository: ApplicationRepositoryImpl(dependencies.api),
                    auth: context.read<AuthViewModel>(),
                    uploadService: dependencies.upload),
                child: const CreatorApplicationFormScreen(),
              )),
      GoRoute(
          path: RouteNames.login,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => LoginViewModel(auth), child: const LoginScreen())),
      GoRoute(
          path: RouteNames.register,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => RegisterViewModel(auth),
              child: const RegisterScreen())),
      GoRoute(
          path: RouteNames.forgotPassword,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => ForgotPasswordViewModel(auth),
              child: const ForgotPasswordScreen())),
      GoRoute(
          path: RouteNames.creatorDashboard,
          builder: (_, __) => ChangeNotifierProvider(
                create: (_) => CreatorDashboardViewModel(
                   products: dependencies.products,
                  artisans: ArtisanRepository(dependencies.api),
                )..init(),
                child: const CreatorDashboardScreen(),
              )),
      GoRoute(
          path: RouteNames.creatorReports,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) =>
                  CreatorReportViewModel(ReportRepository(dependencies.api))
                    ..load(),
              child: const CreatorReportScreen())),
      GoRoute(
          path: '${RouteNames.creatorReports}/:month',
          builder: (_, s) {
            final month = s.pathParameters['month']!;
            return ChangeNotifierProvider(
                create: (_) => CreatorReportDetailViewModel(
                    ReportRepository(dependencies.api),
                    month: month)
                  ..load(),
                child: CreatorReportDetailScreen(month: month));
          }),
      GoRoute(
          path: '/dashboard-kreator/my-products',
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => CreatorDashboardViewModel(
                  products: dependencies.products,
                  artisans: ArtisanRepository(dependencies.api))
                ..init(),
              child: const MyProductsScreen())),
      GoRoute(
          path: '/dashboard-kreator/product-form',
          builder: (_, s) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                        create: (_) => ProductFormViewModel(
                            repository: dependencies.products,
                            upload: dependencies.upload,
                            photos: PhotoEditorViewModel(
                                uploadService: dependencies.upload),
                            productId: s.uri.queryParameters['id'] ?? '',
                            replaceOf:
                                s.uri.queryParameters['replaceOf'] ?? '')),
                  ],
                  child: ProductFormScreen(
                      productId: s.uri.queryParameters['id'] ?? '',
                      replaceOf: s.uri.queryParameters['replaceOf'] ?? ''))),
      GoRoute(
          path: '/dashboard-kreator/my-stories',
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => MyStoriesViewModel(
                  repository: StoryRepositoryImpl(dependencies.api))
                ..load(),
              child: const MyStoriesScreen())),
      GoRoute(
          path: '/dashboard-kreator/story-form',
          builder: (_, s) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                        create: (_) => StoryAiViewModel(
                            repository: AiRepositoryImpl(dependencies.api))),
                    ChangeNotifierProvider(
                        create: (_) => StoryFormViewModel(
                            productId: s.uri.queryParameters['productId'] ?? '',
                            repository: StoryRepositoryImpl(dependencies.api),
                            uploads: dependencies.upload,
                            photos: PhotoEditorViewModel(
                                uploadService: dependencies.upload))),
                  ],
                  child: StoryFormScreen(
                      productId: s.uri.queryParameters['productId'] ?? ''))),
      GoRoute(
          path: '/dashboard-kreator/profil-toko',
          builder: (_, __) => MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                      create: (_) => CreatorDashboardViewModel(
                             products: dependencies.products,
                            artisans: ArtisanRepository(dependencies.api),
                          )),
                  ChangeNotifierProvider(
                      create: (context) => EditStoreProfileViewModel(
                            repository: ArtisanRepository(dependencies.api),
                            upload: dependencies.upload,
                            auth: context.read<AuthViewModel>(),
                          )..load()),
                ],
                child: const EditStoreProfileScreen(),
              )),
      GoRoute(
          path: RouteNames.notifications,
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: RouteNames.account,
          builder: (_, __) => const AccountHomeScreen()),
      GoRoute(
          path: RouteNames.accountOrders,
          builder: (_, __) => ChangeNotifierProvider(
                create: (_) => OrdersViewModel(
                    repository: OrderRepository(dependencies.api))
                  ..fetchOrders(),
                child: const AccountOrdersScreen(),
              )),
      GoRoute(
          path: '${RouteNames.orderDetail}/:id',
          builder: (_, s) {
            final id = s.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => OrderDetailViewModel(id,
                  repository: OrderRepository(dependencies.api))
                ..init(),
              child: OrderDetailScreen(orderId: id),
            );
          }),
      GoRoute(
          path: RouteNames.myReviews,
          builder: (_, __) => ChangeNotifierProvider(
                create: (_) => MyReviewsViewModel(
                    repository: ReviewRepository(dependencies.api)),
                child: const MyReviewsScreen(),
              )),
      GoRoute(
          path: '/akun/ulasan/write',
          builder: (_, s) {
            final orderId = s.uri.queryParameters['order'] ?? '';
            return ChangeNotifierProvider(
              create: (_) => WriteReviewViewModel(orderId,
                  orders: OrderRepository(dependencies.api),
                  reviews: ReviewRepository(dependencies.api)),
              child: WriteReviewScreen(orderId: orderId),
            );
          }),
      GoRoute(
          path: RouteNames.applicationStatus,
          builder: (_, __) => ChangeNotifierProvider(
                create: (context) => ApplicationStatusViewModel(
                    ApplicationRepositoryImpl(dependencies.api),
                    context.read<AuthViewModel>())
                  ..load(),
                child: const ApplicationStatusScreen(),
              )),
      GoRoute(
          path: RouteNames.accountSettings,
          builder: (_, __) => MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                      create: (context) => ProfileSettingsViewModel(
                          context.read<AuthViewModel>(),
                          dependencies.upload,
                          PhotoPickerService())),
                  ChangeNotifierProvider(
                      create: (context) =>
                          ChangeEmailViewModel(context.read<AuthViewModel>())),
                  ChangeNotifierProvider(
                      create: (context) => ChangePasswordViewModel(
                          context.read<AuthViewModel>())),
                ],
                child: const AccountSettingsScreen(),
              )),
      GoRoute(
          path: RouteNames.pencarian,
          builder: (_, __) => ChangeNotifierProvider(
              create: (_) => SearchViewModel(
                  repository: SearchRepository(dependencies.api)),
              child: const SearchResultsScreen())),
      GoRoute(path: RouteNames.about, builder: (_, __) => const AboutScreen()),
    ],
    errorBuilder: (_, __) => Scaffold(
        body: Center(
            child: Text('Halaman tidak ditemukan',
                style: buildTheme().textTheme.bodyLarge))),
  );
}
