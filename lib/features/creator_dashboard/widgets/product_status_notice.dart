import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'product_status_badge.dart';

/// Penjelasan di bawah kartu produk untuk status selain aktif. Pada produk yang ditarik muncul tombol
/// "Ajukan produk baru" (isi `onSubmitNew` dengan navigasi ke form produk).
class ProductStatusNotice extends StatelessWidget {
  final String displayStatus;
  final String? note;
  final VoidCallback? onSubmitNew;

  const ProductStatusNotice({
    super.key,
    required this.displayStatus,
    this.note,
    this.onSubmitNew,
  });

  String _message() {
    final reason = (note ?? '').trim();
    switch (displayStatus) {
      case 'menunggu':
        return 'Produk sedang ditinjau admin dan belum tampil di katalog.';
      case 'ditolak':
        return reason.isEmpty
            ? 'Produk ditolak admin. Perbaiki produk lalu simpan untuk mengajukan ulang.'
            : 'Produk ditolak admin. Alasan: $reason. Perbaiki produk lalu simpan untuk mengajukan ulang.';
      case 'disembunyikan':
        return reason.isEmpty
            ? 'Produk disembunyikan admin dari katalog.'
            : 'Produk disembunyikan admin. Alasan: $reason';
      case 'ditarik':
        return 'Produk ditarik karena 6 bulan tidak laku. Produk ini tidak bisa diaktifkan lagi, tetapi kamu bisa mengajukan produk pengganti.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (displayStatus == 'aktif' || displayStatus.isEmpty) return const SizedBox.shrink();
    final color = ProductStatusBadge.colorFor(displayStatus);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_message(), style: AppTextStyles.caption.copyWith(color: AppColors.foreground)),
        if (displayStatus == 'ditarik' && onSubmitNew != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubmitNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajukan produk baru'),
            ),
          ),
        ],
      ]),
    );
  }
}

