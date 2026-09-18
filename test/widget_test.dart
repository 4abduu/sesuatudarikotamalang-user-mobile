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
import 'package:sesuatu_darikota_malang/features/auth/providers/auth_provider.dart';
import 'package:sesuatu_darikota_malang/features/account/providers/orders_provider.dart';
import 'package:sesuatu_darikota_malang/features/account/providers/reviews_provider.dart';
import 'package:sesuatu_darikota_malang/features/account/providers/applications_provider.dart';
import 'package:sesuatu_darikota_malang/features/notifications/providers/notifications_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots with providers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ChangeNotifierProvider(create: (_) => ReviewsProvider()),
          ChangeNotifierProvider(create: (_) => ApplicationsProvider()),
          ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ],
        child: const SesuatuApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
