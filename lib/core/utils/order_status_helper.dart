import '../../data/models/order_model.dart';

/// Computed status checks (no background cron — pure date comparison).
/// Midtrans Lunas orders past their pickupDeadline → "Lewat Batas Pengambilan".
/// Cash/QRIS orders past holdExpiresAt + autoCancel → "Kedaluwarsa".
/// NOTE: pickupDeadlineDays defaults to 14 — in production this comes from
/// admin settings (web-only). Mobile hardcodes 14 as the default.
const int defaultPickupDeadlineDays = 14;

bool isPastPickupDeadline(OrderModel order) {
  if (order.status != OrderStatus.lunas) return false;
  final deadline = order.pickupDeadline;
  if (deadline == null || deadline.isEmpty) return false;
  try {
    return DateTime.now().isAfter(DateTime.parse(deadline));
  } catch (_) {
    return false;
  }
}

bool isHoldExpired(OrderModel order) {
  if (order.status != OrderStatus.menungguBayar) return false;
  final hold = order.holdExpiresAt;
  if (hold == null || hold.isEmpty) return false;
  try {
    return DateTime.now().isAfter(DateTime.parse(hold));
  } catch (_) {
    return false;
  }
}

/// Returns the effective display status (may differ from stored status for
/// Lunas→LewatBatas and MenungguBayar→Kedaluwarsa computed transitions).
OrderStatus effectiveStatus(OrderModel order) {
  if (isPastPickupDeadline(order)) return OrderStatus.lewatBatas;
  if (isHoldExpired(order)) return OrderStatus.kedaluwarsa;
  return order.status;
}

/// Computes pickupDeadline ISO = pickupDate + [days] days.
String computePickupDeadline(String pickupDateIso, int days) {
  try {
    final d = DateTime.parse(pickupDateIso);
    return d.add(Duration(days: days)).toIso8601String();
  } catch (_) {
    return '';
  }
}
