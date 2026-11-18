// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sesuatu_darikota_malang/app.dart';
import 'package:sesuatu_darikota_malang/features/auth/viewmodel/auth_view_model.dart';
import 'package:sesuatu_darikota_malang/features/notifications/viewmodel/notifications_view_model.dart';
import 'package:sesuatu_darikota_malang/features/catalog/viewmodel/app_config_view_model.dart';
import 'package:sesuatu_darikota_malang/data/repositories/catalog_repositories.dart';
import 'package:sesuatu_darikota_malang/data/repositories/notification_repository.dart';
import 'package:sesuatu_darikota_malang/data/repositories/auth_repository.dart';
import 'package:sesuatu_darikota_malang/core/di/app_dependencies.dart';
import 'package:sesuatu_darikota_malang/data/services/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots with providers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final dependencies = AppDependencies();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AuthViewModel(
                      repository: AuthRepository(
                    dependencies.api,
                    dependencies.tokenStorage,
                    SessionStore(),
                  ))),
          ChangeNotifierProvider(
              create: (_) => AppConfigViewModel(
                    categories: CategoryRepository(dependencies.api),
                    settings: SettingsRepository(dependencies.api),
                  )),
          ChangeNotifierProxyProvider<AuthViewModel, NotificationsViewModel>(
            create: (_) => NotificationsViewModel(
                repository: NotificationRepositoryImpl(dependencies.api)),
            update: (_, auth, vm) {
              vm!.updateAuth(auth);
              return vm;
            },
          ),
        ],
        child: SesuatuApp(dependencies: dependencies),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
