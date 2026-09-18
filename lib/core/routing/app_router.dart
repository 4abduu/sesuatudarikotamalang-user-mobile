import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'route_names.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/catalog/screens/catalog_screen.dart';
import '../../features/product_detail/screens/product_detail_screen.dart';
import '../../features/creators/screens/creators_list_screen.dart';
import '../../features/creators/screens/creator_profile_screen.dart';
import '../../features/reservation/screens/reservation_flow_screen.dart';
import '../../features/reservation/screens/reservation_confirmation_screen.dart';
import '../../features/creator_application/screens/creator_application_form_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/creator_dashboard/screens/creator_dashboard_screen.dart';
import '../../features/creator_dashboard/screens/my_products_screen.dart';
import '../../features/creator_dashboard/screens/product_form_screen.dart';
import '../../features/creator_dashboard/screens/my_stories_screen.dart';
import '../../features/creator_dashboard/screens/story_form_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/account/screens/account_home_screen.dart';
import '../../features/account/screens/account_orders_screen.dart';
import '../../features/account/screens/order_detail_screen.dart';
import '../../features/account/screens/my_reviews_screen.dart';
import '../../features/account/screens/write_review_screen.dart';
import '../../features/account/screens/application_status_screen.dart';
import '../../features/account/screens/account_settings_screen.dart';
import '../../features/search/screens/search_results_screen.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: RouteNames.catalog, builder: (_, __) => const CatalogScreen()),
      GoRoute(path: '${RouteNames.productDetail}/:id', builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!)),
      GoRoute(path: RouteNames.creatorsList, builder: (_, __) => const CreatorsListScreen()),
      GoRoute(path: '${RouteNames.creatorProfile}/:id', builder: (_, s) => CreatorProfileScreen(creatorId: s.pathParameters['id']!)),
      GoRoute(path: '${RouteNames.reservation}/:productId', builder: (_, s) => ReservationFlowScreen(productId: s.pathParameters['productId']!)),
      GoRoute(path: RouteNames.reservationConfirm, builder: (_, __) => const ReservationConfirmationScreen()),
      GoRoute(path: RouteNames.daftarKreator, builder: (_, __) => const CreatorApplicationFormScreen()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: RouteNames.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: RouteNames.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: RouteNames.creatorDashboard, builder: (_, __) => const CreatorDashboardScreen()),
      GoRoute(path: '/dashboard-kreator/my-products', builder: (_, __) => const MyProductsScreen()),
      GoRoute(path: '/dashboard-kreator/product-form', builder: (_, s) => ProductFormScreen(productId: s.uri.queryParameters['id'] ?? '')),
      GoRoute(path: '/dashboard-kreator/my-stories', builder: (_, __) => const MyStoriesScreen()),
      GoRoute(path: '/dashboard-kreator/story-form', builder: (_, s) => StoryFormScreen(productId: s.uri.queryParameters['productId'] ?? '')),
      GoRoute(path: RouteNames.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteNames.account, builder: (_, __) => const AccountHomeScreen()),
      GoRoute(path: RouteNames.accountOrders, builder: (_, __) => const AccountOrdersScreen()),
      GoRoute(path: '${RouteNames.orderDetail}/:id', builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: RouteNames.myReviews, builder: (_, __) => const MyReviewsScreen()),
      GoRoute(path: '/akun/ulasan/write', builder: (_, s) {
        final orderId = s.uri.queryParameters['order'] ?? '';
        return WriteReviewScreen(orderId: orderId);
      }),
      GoRoute(path: RouteNames.applicationStatus, builder: (_, __) => const ApplicationStatusScreen()),
      GoRoute(path: RouteNames.accountSettings, builder: (_, __) => const AccountSettingsScreen()),
      GoRoute(path: RouteNames.pencarian, builder: (_, __) => const SearchResultsScreen()),
    ],
    errorBuilder: (_, __) => Scaffold(body: Center(child: Text('Halaman tidak ditemukan', style: buildTheme().textTheme.bodyLarge))),
  );
}
