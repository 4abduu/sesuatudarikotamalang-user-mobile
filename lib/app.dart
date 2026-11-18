import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/di/app_dependencies.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'features/notifications/viewmodel/notifications_view_model.dart';
import 'features/catalog/viewmodel/app_config_view_model.dart';
import 'package:provider/provider.dart';

class SesuatuApp extends StatefulWidget {
  const SesuatuApp({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<SesuatuApp> createState() => _SesuatuAppState();
}

class _SesuatuAppState extends State<SesuatuApp> with WidgetsBindingObserver {
  bool _initialized = false;
  bool _initializing = false;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      final auth = context.read<AuthViewModel>();
      if (auth.isAuthenticated) {
        context.read<NotificationsViewModel>().fetchNotifications();
      }
      auth.refreshMeThrottled().then((roleChanged) {
        if (roleChanged && auth.isCreator && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Selamat! Akunmu sekarang berperan sebagai kreator.')),
          );
        }
      });
    }
  }

  Future<void> _initProviders() async {
    if (_initializing) return;
    _initializing = true;
    // Baca semua provider sebelum await pertama untuk menghindari
    // penggunaan BuildContext di seberang async gap.
    final auth = context.read<AuthViewModel>();
    final config = context.read<AppConfigViewModel>();
    await Future.wait([auth.init(), config.init()]);
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) _initProviders();
    // Build router lazily — reuses AuthViewModel via refreshListenable so
    // the router re-evaluates redirects when auth state changes (login/logout).
    _router ??=
        buildAppRouter(context.read<AuthViewModel>(), widget.dependencies);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sesuatu DariKota Malang',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router!,
      builder: (context, child) {
        if (!_initialized) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return child ?? const SizedBox();
      },
    );
  }
}

/// Izinkan drag scroll menggunakan mouse, touch, maupun trackpad di seluruh platform (Desktop & Mobile).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
