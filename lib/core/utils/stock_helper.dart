import '../../data/models/order_model.dart';
import 'order_status_helper.dart';

/// Counts how many units of a specific product+variant combination are
/// currently "reserved" by active orders. A reserved unit is one that is
/// either paid (Lunas / Selesai) OR still on an active hold (MenungguBayar
/// that hasn't expired yet). Expired holds are no longer reserving stock.
///
/// This is the canonical stock-reservation logic shared by:
///   - variant_selection_provider (effective stock for display)
///   - reservation_flow_provider (check-at-submit validation)
int reservedCount(List<OrderModel> orders, String productId, String variantLabel) {
  return orders.where((o) {
    if (o.productId != productId) return false;
    if (o.variantLabel != variantLabel) return false;
    if (o.status == OrderStatus.lunas || o.status == OrderStatus.selesai) return true;
    if (o.status == OrderStatus.menungguBayar && !isHoldExpired(o)) return true;
    return false;
  }).length;
}

/// Effective stock = original stock - reserved. Never negative.
int effectiveStock(int originalStock, int reserved) {
  final remaining = originalStock - reserved;
  return remaining < 0 ? 0 : remaining;
}
