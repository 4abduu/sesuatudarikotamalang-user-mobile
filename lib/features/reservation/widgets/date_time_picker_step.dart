import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../product_detail/widgets/variant_picker.dart';
import '../providers/reservation_flow_provider.dart';

class DateTimePickerStep extends StatelessWidget {
  final ReservationFlowProvider provider;
  const DateTimePickerStep({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final first = provider.firstDate;
    final last = provider.lastDate;
    // initialDate harus berada dalam [firstDate, lastDate] dan memenuhi predicate.
    // Tidak ada predicate hari: toko buka 7 hari seminggu, termasuk Minggu.
    final selected = provider.selectedDate ?? first;
    final initial = selected.isBefore(first) ? first : (selected.isAfter(last) ? last : selected);

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
      Text(
        'Toko buka setiap hari, termasuk Minggu. Ambil hari ini selama slotnya belum ditutup, atau pilih sampai ${ReservationFlowProvider.maxAdvanceDays} hari ke depan.',
        style: AppTextStyles.caption,
      ),
      const SizedBox(height: 8),
      CalendarDatePicker(
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        onDateChanged: (d) => provider.setDate(d),
      ),
      const SizedBox(height: 16),
      // Time slot
      Text('Pilih Waktu Ambil', style: AppTextStyles.h3),
      const SizedBox(height: 8),
      _SlotSection(provider: provider),
    ]);
  }
}

class _SlotSection extends StatelessWidget {
  final ReservationFlowProvider provider;
  const _SlotSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
      );
    }
    if (provider.slotsError != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(provider.slotsError!, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: provider.loadSlots,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Coba lagi'),
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (provider.noBookableSlot) ...[
        Text('Tidak ada slot yang tersedia di tanggal ini. Silakan pilih tanggal lain.', style: AppTextStyles.caption),
        const SizedBox(height: 8),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.slots.map((s) {
          final active = provider.selectedSlot == s.time;
          final disabled = !s.bookable;
          final label = s.isPast
              ? '${s.time} (Lewat)'
              : (s.isClosed ? '${s.time} (Ditutup)' : (s.available <= 0 ? '${s.time} (Penuh)' : s.time));
          return GestureDetector(
            onTap: disabled ? null : () => provider.setSlot(s.time),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.onPrimary : (disabled ? AppColors.muted : AppColors.foreground),
                  decoration: disabled ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      if (provider.leadMinutes > 0) ...[
        const SizedBox(height: 8),
        Text(
          'Pemesanan slot ditutup ${provider.leadMinutes} menit sebelum jam pickup.',
          style: AppTextStyles.caption,
        ),
      ],
    ]);
  }
}