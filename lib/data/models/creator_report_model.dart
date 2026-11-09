/// Model laporan bulanan kreator (hanya laporan berstatus final yang dikirim backend).
library;

int _toInt(dynamic v) {
  if (v is num) return v.round();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString()) ?? 0;
}

/// Baris ringkasan di daftar laporan (`GET /api/artisans/mine/reports`).
class CreatorReportSummary {
  final String month; // YYYY-MM
  final String? finalizedAt;
  final int itemsSold;
  final int revenue;
  final int creatorShare;

  const CreatorReportSummary({
    required this.month,
    required this.finalizedAt,
    required this.itemsSold,
    required this.revenue,
    required this.creatorShare,
  });

  factory CreatorReportSummary.fromJson(Map<String, dynamic> j) => CreatorReportSummary(
        month: (j['month'] ?? '').toString(),
        finalizedAt: j['finalizedAt']?.toString(),
        itemsSold: _toInt(j['itemsSold']),
        revenue: _toInt(j['revenue']),
        creatorShare: _toInt(j['creatorShare']),
      );
}

class CreatorReportSaleLine {
  final String productName;
  final String? variantLabel;
  final int quantity;
  final int price;
  final int revenue;

  const CreatorReportSaleLine({
    required this.productName,
    required this.variantLabel,
    required this.quantity,
    required this.price,
    required this.revenue,
  });

  factory CreatorReportSaleLine.fromJson(Map<String, dynamic> j) => CreatorReportSaleLine(
        productName: (j['productName'] ?? '').toString(),
        variantLabel: j['variantLabel']?.toString(),
        quantity: _toInt(j['quantity']),
        price: _toInt(j['price']),
        revenue: _toInt(j['revenue']),
      );
}

class CreatorReportStockLine {
  final String productName;
  final String? variantLabel;
  final int stock;

  const CreatorReportStockLine({
    required this.productName,
    required this.variantLabel,
    required this.stock,
  });

  factory CreatorReportStockLine.fromJson(Map<String, dynamic> j) => CreatorReportStockLine(
        productName: (j['productName'] ?? '').toString(),
        variantLabel: j['variantLabel']?.toString(),
        stock: _toInt(j['stock']),
      );
}

/// Detail satu bulan (`GET /api/artisans/mine/reports/:month`, di dalam kunci `report`).
class CreatorReport {
  final String month;
  final String? finalizedAt;
  final String brandName;
  final int itemsSold;
  final int revenue;
  final double sharePercent;
  final int creatorShare;
  final int storeShare;
  final List<CreatorReportSaleLine> sales;
  final List<CreatorReportStockLine> stock;

  const CreatorReport({
    required this.month,
    required this.finalizedAt,
    required this.brandName,
    required this.itemsSold,
    required this.revenue,
    required this.sharePercent,
    required this.creatorShare,
    required this.storeShare,
    required this.sales,
    required this.stock,
  });

  factory CreatorReport.fromJson(Map<String, dynamic> j) {
    final rawSales = j['sales'];
    final rawStock = j['stock'];
    return CreatorReport(
      month: (j['month'] ?? '').toString(),
      finalizedAt: j['finalizedAt']?.toString(),
      brandName: (j['brandName'] ?? '').toString(),
      itemsSold: _toInt(j['itemsSold']),
      revenue: _toInt(j['revenue']),
      sharePercent: _toDouble(j['sharePercent']),
      creatorShare: _toInt(j['creatorShare']),
      storeShare: _toInt(j['storeShare']),
      sales: rawSales is List
          ? rawSales.whereType<Map<String, dynamic>>().map(CreatorReportSaleLine.fromJson).toList()
          : <CreatorReportSaleLine>[],
      stock: rawStock is List
          ? rawStock.whereType<Map<String, dynamic>>().map(CreatorReportStockLine.fromJson).toList()
          : <CreatorReportStockLine>[],
    );
  }
}

