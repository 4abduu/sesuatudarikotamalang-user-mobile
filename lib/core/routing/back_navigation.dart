import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Halaman tingkat atas yang tidak membutuhkan tombol kembali.
bool isTopLevelPath(String path) =>
    path == RouteNames.home ||
    path == RouteNames.catalog ||
    path == RouteNames.creatorsList ||
    path == RouteNames.account ||
    path == RouteNames.notifications;

/// Menentukan induk halaman ketika halaman dibuka langsung melalui URL.
String parentLocationOf(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return RouteNames.home;

  switch (segments.first) {
    case 'produk':
      return segments.length >= 3
          ? '${RouteNames.productDetail}/${segments[1]}'
          : RouteNames.catalog;
    case 'kreator':
      return RouteNames.creatorsList;
    case 'reservasi':
      return segments.length == 2 && segments[1] != 'konfirmasi'
          ? '${RouteNames.productDetail}/${segments[1]}'
          : RouteNames.accountOrders;
    case 'akun':
      return segments.length >= 3 && segments[1] == 'pesanan'
          ? RouteNames.accountOrders
          : RouteNames.account;
    case 'dashboard-kreator':
      if (segments.length == 1) return RouteNames.account;
      if (segments.length >= 3 && segments[1] == 'laporan') {
        return RouteNames.creatorReports;
      }
      return RouteNames.creatorDashboard;
    default:
      return RouteNames.home;
  }
}

extension BackNavigation on BuildContext {
  /// Pop bila ada riwayat; bila deep-link, pindah ke induk yang masuk akal.
  void popOrParent<T extends Object?>([T? result]) {
    if (canPop()) {
      pop<T>(result);
    } else {
      go(parentLocationOf(GoRouterState.of(this).uri.path));
    }
  }
}
