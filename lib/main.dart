import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/account/providers/orders_provider.dart';
import 'features/account/providers/reviews_provider.dart';
import 'features/account/providers/applications_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  final orders = OrdersProvider();
  final reviews = ReviewsProvider();
  final apps = ApplicationsProvider();
  final notifications = NotificationsProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: orders),
        ChangeNotifierProvider.value(value: reviews),
        ChangeNotifierProvider.value(value: apps),
        ChangeNotifierProvider.value(value: notifications),
      ],
      child: const SesuatuApp(),
    ),
  );
}
