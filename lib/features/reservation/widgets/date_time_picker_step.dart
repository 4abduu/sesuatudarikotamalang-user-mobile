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

    // Gunakan daftar slot saat ini, atau fallback ke 6 jam operasional toko jika masih kosong awal
    final slotsList = provider.slots.isNotEmpty
        ? provider.slots
        : const [
            PickupSlot(time: '10:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
            PickupSlot(time: '11:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
            PickupSlot(time: '12:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
            PickupSlot(time: '13:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
            PickupSlot(time: '14:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
            PickupSlot(time: '15:00', capacity: 5, booked: 0, available: 5, isPast: false, isClosed: false, bookable: true),
          ];

    final isLoading = provider.slotsLoading;

    final bool isTrulyEmpty = !isLoading && provider.slots.isEmpty && provider.slotsError == null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isTrulyEmpty) ...[
        Text(
          'Saat ini tidak ada slot pengambilan yang tersedia. Silakan coba lagi nanti.',
          style: AppTextStyles.caption.copyWith(color: AppColors.mustard),
        ),
        const SizedBox(height: 8),
      ] else if (provider.noBookableSlot) ...[
        Text('Tidak ada slot yang tersedia di tanggal ini. Silakan pilih tanggal lain.', style: AppTextStyles.caption),
        const SizedBox(height: 8),
      ],
      if (!isTrulyEmpty)
        Wrap(
        spacing: 8,
        runSpacing: 8,
        children: slotsList.map((s) {
          final active = provider.selectedSlot == s.time;
          final disabled = isLoading || !s.bookable;
          final label = s.isPast
              ? '${s.time} (Lewat)'
              : (s.isClosed ? '${s.time} (Ditutup)' : (s.available <= 0 ? '${s.time} (Penuh)' : s.time));

          return GestureDetector(
            onTap: disabled ? null : () => provider.setSlot(s.time),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : (isLoading ? AppColors.surface.withValues(alpha: 0.6) : AppColors.surface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? AppColors.primary
                      : (isLoading ? AppColors.border.withValues(alpha: 0.4) : AppColors.border),
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isLoading ? 0.45 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.onPrimary : (s.bookable ? AppColors.foreground : AppColors.muted),
                        decoration: (!isLoading && !s.bookable) ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ],
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