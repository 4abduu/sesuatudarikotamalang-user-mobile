import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../product_detail/widgets/variant_picker.dart';
import '../providers/reservation_flow_provider.dart';

class DateTimePickerStep extends StatelessWidget {
  final ReservationFlowProvider provider;
  const DateTimePickerStep({super.key, required this.provider});

  static const _slots = ['10:00', '11:00', '13:00', '15:00', '17:00'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Variant
      if (provider.product.hasVariants) ...[
        Text('Pilih Varian', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: VariantPicker(product: provider.product, provider: provider.variantProvider))),
        const SizedBox(height: 16),
      ],
      // Date
      Text('Pilih Tanggal Ambil', style: AppTextStyles.h3),
      const SizedBox(height: 4),
      Text('Toko tutup hari Minggu. Tanggal lampau tidak bisa dipilih.', style: AppTextStyles.caption),
      const SizedBox(height: 8),
      CalendarDatePicker(initialDate: now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 60)),
        onDateChanged: (d) => provider.setDate(d),
        selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
      ),
      const SizedBox(height: 16),
      // Time slot
      Text('Pilih Waktu Ambil', style: AppTextStyles.h3),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _slots.map((s) {
        final active = provider.selectedSlot == s;
        final full = s == '13:00';
        return GestureDetector(onTap: full ? null : () => provider.setSlot(s),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? AppColors.primary : AppColors.border)),
            child: Text(full ? '$s (Penuh)' : s, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.onPrimary : (full ? AppColors.muted : AppColors.foreground), decoration: full ? TextDecoration.lineThrough : TextDecoration.none))));
      }).toList()),
    ]);
  }
}
