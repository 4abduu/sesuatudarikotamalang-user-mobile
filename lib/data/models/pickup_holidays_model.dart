/// Data libur pickup dari `GET /api/slots/holidays`.
/// Hari mengikuti ISO: 1 = Senin ... 7 = Minggu (sama dengan `DateTime.weekday` di Dart).
library;

const List<String> _weekdayNames = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

DateTime _parseDateOnly(dynamic v) {
  final s = (v ?? '').toString();
  if (s.length >= 10) {
    final parts = s.substring(0, 10).split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
  }
  return DateTime(1970);
}

/// Satu jadwal libur: satu tanggal atau beberapa tanggal berurutan, lengkap dengan alasan.
class HolidayRange {
  final String id;
  final DateTime start;
  final DateTime end;
  final String reason;

  const HolidayRange({
    required this.id,
    required this.start,
    required this.end,
    required this.reason,
  });

  factory HolidayRange.fromJson(Map<String, dynamic> j) {
    final start = _parseDateOnly(j['startDate']);
    final end = j['endDate'] == null ? start : _parseDateOnly(j['endDate']);
    return HolidayRange(
      id: (j['id'] ?? '').toString(),
      start: start,
      end: end,
      reason: (j['reason'] ?? '').toString(),
    );
  }

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// Penjelasan kenapa suatu tanggal libur, dipakai oleh pop-up alasan.
class HolidayInfo {
  /// true bila libur karena libur mingguan, false bila karena jadwal libur khusus.
  final bool weekly;
  final String reason;

  const HolidayInfo({required this.weekly, required this.reason});
}

class PickupHolidays {
  final bool weeklyEnabled;
  final Set<int> weeklyDays;
  final List<HolidayRange> ranges;

  const PickupHolidays({
    required this.weeklyEnabled,
    required this.weeklyDays,
    required this.ranges,
  });

  static const PickupHolidays empty = PickupHolidays(
    weeklyEnabled: false,
    weeklyDays: <int>{},
    ranges: <HolidayRange>[],
  );

  factory PickupHolidays.fromJson(Map<String, dynamic> j) {
    final weekly = j['weeklyOff'];
    var enabled = false;
    final days = <int>{};
    if (weekly is Map<String, dynamic>) {
      enabled = weekly['enabled'] == true;
      final rawDays = weekly['days'];
      if (rawDays is List) {
        for (final d in rawDays) {
          final n = d is num ? d.toInt() : int.tryParse(d.toString());
          if (n != null && n >= 1 && n <= 7) days.add(n);
        }
      }
    }
    final rawRanges = j['holidays'];
    final ranges = <HolidayRange>[];
    if (rawRanges is List) {
      for (final r in rawRanges) {
        if (r is Map<String, dynamic>) ranges.add(HolidayRange.fromJson(r));
      }
    }
    return PickupHolidays(weeklyEnabled: enabled, weeklyDays: days, ranges: ranges);
  }

  /// Null bila tanggal buka. Jadwal libur khusus didahulukan karena punya alasan sendiri.
  HolidayInfo? infoFor(DateTime date) {
    for (final r in ranges) {
      if (r.contains(date)) {
        return HolidayInfo(
          weekly: false,
          reason: r.reason.isEmpty ? 'Toko libur pada tanggal ini.' : r.reason,
        );
      }
    }
    if (weeklyEnabled && weeklyDays.contains(date.weekday)) {
      return HolidayInfo(
        weekly: true,
        reason: 'Toko libur setiap hari ${_weekdayNames[date.weekday]}.',
      );
    }
    return null;
  }
}

