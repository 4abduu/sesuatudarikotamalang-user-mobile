import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  GoRouter? _router;

  Future<void> _initProviders() async {
    final ctx = context;
    await ctx.read<AuthProvider>().init();
    await ctx.read<OrdersProvider>().init();
    await ctx.read<ReviewsProvider>().init();
    await ctx.read<ApplicationsProvider>().init();
    await ctx.read<NotificationsProvider>().init();
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
