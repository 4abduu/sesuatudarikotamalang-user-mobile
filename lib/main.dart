import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/account/providers/orders_provider.dart';
import 'features/account/providers/reviews_provider.dart';
import 'features/account/providers/applications_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/catalog/providers/products_provider.dart';
import 'features/creators/providers/artisans_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'features/creator_dashboard/providers/creator_dashboard_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  final products = ProductsProvider();
  final artisans = ArtisansProvider();
  final search = SearchProvider();
  final orders = OrdersProvider();
  final reviews = ReviewsProvider();
  final apps = ApplicationsProvider();
  final notifications = NotificationsProvider();
  final creatorDashboard = CreatorDashboardProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: products),
        ChangeNotifierProvider.value(value: artisans),
        ChangeNotifierProvider.value(value: search),
        ChangeNotifierProvider.value(value: orders),
        ChangeNotifierProvider.value(value: reviews),
        ChangeNotifierProvider.value(value: apps),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider.value(value: creatorDashboard),
      ],
      child: const SesuatuApp(),
    ),
  );
}
