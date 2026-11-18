import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repositories.dart';
import 'data/services/session_store.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'features/notifications/viewmodel/notifications_view_model.dart';
import 'features/catalog/viewmodel/app_config_view_model.dart';
import 'data/repositories/notification_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter Web: navigasi imperative lewat push/pushNamed tetap tercermin di
  // address bar sehingga deep-link dan refresh membuka halaman yang benar.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await initializeDateFormatting('id_ID', null);
  final dependencies = AppDependencies();
  final auth = AuthViewModel(
      repository: AuthRepository(
          dependencies.api, dependencies.tokenStorage, SessionStore()));
  dependencies.api.onUnauthorized = auth.handleUnauthorized;
  final config = AppConfigViewModel(
    categories: CategoryRepository(dependencies.api),
    settings: SettingsRepository(dependencies.api),
  );
  final notifications = NotificationsViewModel(
      repository: NotificationRepositoryImpl(dependencies.api));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: config),
        ChangeNotifierProxyProvider<AuthViewModel, NotificationsViewModel>(
          create: (_) => notifications,
          update: (_, authState, vm) {
            vm!.updateAuth(authState);
            return vm;
          },
        ),
      ],
      child: SesuatuApp(dependencies: dependencies),
    ),
  );
}
