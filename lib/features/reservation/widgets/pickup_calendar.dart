import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pickup_holidays_model.dart';
import 'holiday_reason_sheet.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Kalender pemilih tanggal pickup pengganti `CalendarDatePicker`.
/// Hari libur (libur mingguan dan jadwal libur) tampil MERAH dan tidak bisa dipilih; mengetuknya membuka
/// pop-up alasan libur. Data libur diambil dari `GET /api/slots/holidays`. Bila gagal dimuat, semua tanggal
/// tampil buka dan server tetap menolak tanggal libur saat pesanan dibuat.
class PickupCalendar extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  const PickupCalendar({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  @override
  State<PickupCalendar> createState() => _PickupCalendarState();
}

class _PickupCalendarState extends State<PickupCalendar> {
  late DateTime _selected;
  late DateTime _visibleMonth;
  PickupHolidays _holidays = PickupHolidays.empty;

  DateTime get _first => _dateOnly(widget.firstDate);
  DateTime get _last => _dateOnly(widget.lastDate);

  @override
  void initState() {
    super.initState();
    _selected = _dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selected.year, _selected.month);
    _loadHolidays();
  }

  @override
  void didUpdateWidget(covariant PickupCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _dateOnly(widget.initialDate);
    if (!_sameDay(_dateOnly(oldWidget.initialDate), incoming) &&
        !_sameDay(incoming, _selected) &&
        _holidays.infoFor(incoming) == null) {
      setState(() {
        _selected = incoming;
        _visibleMonth = DateTime(incoming.year, incoming.month);
      });
    }
  }

  Future<void> _loadHolidays() async {
    PickupHolidays loaded = PickupHolidays.empty;
    try {
      final res = await ApiClient.get(
        '/slots/holidays',
        queryParameters: {'from': _fmt(_first), 'to': _fmt(_last)},
      );
      if (res is Map<String, dynamic>) {
        loaded = PickupHolidays.fromJson(res);
      }
    } catch (_) {
      // Abaikan: server tetap menolak tanggal libur saat pesanan dibuat.
    }
    if (!mounted) return;
    setState(() => _holidays = loaded);

    // Tanggal terpilih ternyata libur: pindahkan ke tanggal buka berikutnya.
    if (_holidays.infoFor(_selected) != null) {
      final next = _nextOpenDate(_selected);
      if (next != null) {
        setState(() {
          _selected = next;
          _visibleMonth = DateTime(next.year, next.month);
        });
        widget.onDateChanged(next);
      }
    }
  }

  DateTime? _nextOpenDate(DateTime from) {
    var d = _dateOnly(from);
    while (!d.isAfter(_last)) {
      if (!d.isBefore(_first) && _holidays.infoFor(d) == null) return d;
      d = d.add(const Duration(days: 1));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_visibleMonth);
    final canPrev = _visibleMonth.isAfter(DateTime(_first.year, _first.month));
    final canNext = _visibleMonth.isBefore(DateTime(_last.year, _last.month));

    final lead = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final cells = <Widget>[];
    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(DateTime(_visibleMonth.year, _visibleMonth.month, d)));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: cells
            .sublist(i, i + 7)
            .map((c) => Expanded(child: AspectRatio(aspectRatio: 1, child: c)))
            .toList(),
      ));
    }

    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              tooltip: 'Bulan sebelumnya',
              onPressed: canPrev
                  ? () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1))
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(monthLabel, textAlign: TextAlign.center, style: AppTextStyles.title),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              onPressed: canNext
                  ? () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1))
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ]),
          Row(
            children: weekdays
                .map((w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          ...rows,
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 6, children: [
            _legend(AppColors.destructive.withValues(alpha: 0.12), AppColors.destructive, 'Toko libur (ketuk untuk alasan)'),
            _legend(AppColors.primary, AppColors.primary, 'Tanggal dipilih'),
          ]),
        ],
      ),
    );
  }

  Widget _legend(Color fill, Color border, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border.withValues(alpha: 0.6)),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.caption),
    ]);
  }

  Widget _dayCell(DateTime date) {
    final inRange = !date.isBefore(_first) && !date.isAfter(_last);
    final info = inRange ? _holidays.infoFor(date) : null;
    final isSelected = _sameDay(date, _selected);
    final isToday = _sameDay(date, _dateOnly(DateTime.now()));

    Color? bg;
    Color fg;
    var weight = FontWeight.w500;
    BoxBorder? border;

    if (!inRange) {
      fg = AppColors.muted.withValues(alpha: 0.4);
    } else if (info != null) {
      bg = AppColors.destructive.withValues(alpha: 0.12);
      fg = AppColors.destructive;
      weight = FontWeight.w700;
      border = Border.all(color: AppColors.destructive.withValues(alpha: 0.35));
    } else if (isSelected) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
      weight = FontWeight.w700;
    } else {
      fg = AppColors.foreground;
      if (isToday) border = Border.all(color: AppColors.primary);
    }

    VoidCallback? onTap;
    if (inRange && info != null) {
      onTap = () => showHolidayReasonSheet(context, date: date, info: info);
    } else if (inRange) {
      onTap = () {
        setState(() => _selected = date);
        widget.onDateChanged(date);
      };
    }

    final label = DateFormat('d MMMM yyyy', 'id_ID').format(date);
    return Semantics(
      button: inRange,
      label: info != null ? '$label, toko libur' : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: weight, color: fg),
          ),
        ),
      ),
    );
  }
}

