/// Model untuk objek `order.refund` dari respons GET /api/orders/:id
/// Mengikuti Dokumen Master v1.5 dan PANDUAN-USER-MOBILE-FINAL-v2 Bagian 4.3 & 7.
class RefundInfo {
  final String state; // dalam_batas_waktu | lewat_batas_waktu | lewat_batas_pengambilan | menunggu_refund | sudah_direfund | sudah_diambil | tidak_berlaku
  final bool paid;
  final String? paidAt;
  final String? eligibleUntil;
  final int refundWindowDays;
  final String refundStatus; // tidak_ada | menunggu | selesai
  final String? refundedAt;
  final bool canCancelByBuyerRequest;
  final String? disabledReason;

  const RefundInfo({
    required this.state,
    required this.paid,
    this.paidAt,
    this.eligibleUntil,
    this.refundWindowDays = 3,
    this.refundStatus = 'tidak_ada',
    this.refundedAt,
    this.canCancelByBuyerRequest = false,
    this.disabledReason,
  });

  factory RefundInfo.fromJson(Map<String, dynamic> j) {
    return RefundInfo(
      state: j['state'] ?? 'tidak_berlaku',
      paid: j['paid'] == true,
      paidAt: j['paidAt'],
      eligibleUntil: j['eligibleUntil'],
      refundWindowDays: (j['refundWindowDays'] as num?)?.toInt() ?? 3,
      refundStatus: j['refundStatus'] ?? 'tidak_ada',
      refundedAt: j['refundedAt'],
      canCancelByBuyerRequest: j['canCancelByBuyerRequest'] == true,
      disabledReason: j['disabledReason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state,
    'paid': paid,
    if (paidAt != null) 'paidAt': paidAt,
    if (eligibleUntil != null) 'eligibleUntil': eligibleUntil,
    'refundWindowDays': refundWindowDays,
    'refundStatus': refundStatus,
    if (refundedAt != null) 'refundedAt': refundedAt,
    'canCancelByBuyerRequest': canCancelByBuyerRequest,
    if (disabledReason != null) 'disabledReason': disabledReason,
  };

  /// Section tetap tampil HANYA jika sudah dibayar secara online (Midtrans)
  /// dan state BUKAN sudah_diambil atau tidak_berlaku.
  bool get shouldShowSection {
    if (!paid) return false;
    if (state == 'sudah_diambil' || state == 'tidak_berlaku') return false;
    return true;
  }
}
