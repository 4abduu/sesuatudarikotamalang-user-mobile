import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/account/providers/orders_provider.dart';
import 'features/account/providers/reviews_provider.dart';
import 'features/account/providers/applications_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'package:provider/provider.dart';

class SesuatuApp extends StatefulWidget {
  const SesuatuApp({super.key});
  @override
  State<SesuatuApp> createState() => _SesuatuAppState();
}

class _SesuatuAppState extends State<SesuatuApp> {
  bool _initialized = false;

  Future<void> _initProviders() async {
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrdersProvider>();
    final reviews = context.read<ReviewsProvider>();
    final applications = context.read<ApplicationsProvider>();
    final notifications = context.read<NotificationsProvider>();
    await auth.init();
    await orders.init();
    await reviews.init();
    await applications.init();
    await notifications.init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) _initProviders();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sesuatu DariKota Malang',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: buildAppRouter(),
      builder: (context, child) {
        if (!_initialized) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return child ?? const SizedBox();
      },
    );
  }
}
