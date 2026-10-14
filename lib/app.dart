import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/account/providers/orders_provider.dart';
import 'features/account/providers/reviews_provider.dart';
import 'features/account/providers/applications_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/catalog/providers/products_provider.dart';
import 'features/creators/providers/artisans_provider.dart';
import 'features/creator_dashboard/providers/creator_dashboard_provider.dart';
import 'package:provider/provider.dart';

class SesuatuApp extends StatefulWidget {
  const SesuatuApp({super.key});
  @override
  State<SesuatuApp> createState() => _SesuatuAppState();
}

class _SesuatuAppState extends State<SesuatuApp> {
  bool _initialized = false;
  GoRouter? _router;

  Future<void> _initProviders() async {
    // Baca semua provider sebelum await pertama untuk menghindari
    // penggunaan BuildContext di seberang async gap.
    final auth = context.read<AuthProvider>();
    final products = context.read<ProductsProvider>();
    final artisans = context.read<ArtisansProvider>();
    final orders = context.read<OrdersProvider>();
    final reviews = context.read<ReviewsProvider>();
    final applications = context.read<ApplicationsProvider>();
    final notifications = context.read<NotificationsProvider>();
    final creatorDashboard = context.read<CreatorDashboardProvider>();

    await auth.init();
    await products.init();
    await artisans.init();
    await orders.init();
    await reviews.init();
    await applications.init();
    await notifications.init();
    await creatorDashboard.init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) _initProviders();
    // Build router lazily — reuses AuthProvider via refreshListenable so
    // the router re-evaluates redirects when auth state changes (login/logout).
    _router ??= buildAppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sesuatu DariKota Malang',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router!,
      builder: (context, child) {
        if (!_initialized) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return child ?? const SizedBox();
      },
    );
  }
}
