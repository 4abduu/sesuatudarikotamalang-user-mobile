/// Satu slot pickup dari GET /api/slots?date=YYYY-MM-DD.
/// Backend adalah sumber kebenaran: [isPast], [isClosed], dan [bookable] dihitung di server (WIB).
/// [isPast]: jam mulai sudah lewat. [isClosed]: pemesanan sudah ditutup (jam mulai lewat ATAU sudah
/// masuk jeda minimal sebelum jam mulai, default 30 menit).
class PickupSlot {
  final String time;
  final int capacity;
  final int booked;
  final int available;
  final bool isPast;
  final bool isClosed;
  final bool bookable;

  const PickupSlot({
    required this.time,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.isPast,
    required this.isClosed,
    required this.bookable,
  });

  factory PickupSlot.fromJson(
    Map<String, dynamic> j, {
    DateTime? selectedDate,
    int leadMinutes = 30,
  }) {
    final available = (j['available'] as num?)?.toInt() ?? 0;
    final timeStr = (j['time'] ?? '').toString();

    // Normalnya status slot datang dari backend (`isPast`, `isClosed`, `bookable`).
    // Blok fallback di bawah HANYA dipakai bila server belum mengirim `isPast` (backend lama) dan
    // boleh dihapus setelah backend baru ter-deploy: jam perangkat bukan sumber kebenaran.
    bool isPast = j['isPast'] == true;
    bool isClosed = j['isClosed'] is bool ? j['isClosed'] as bool : isPast;
    if (j['isPast'] == null && selectedDate != null && timeStr.isNotEmpty) {
      final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
      final dateWib = selectedDate.toUtc().add(const Duration(hours: 7));
      final isToday = nowWib.year == dateWib.year && nowWib.month == dateWib.month && nowWib.day == dateWib.day;
      if (isToday) {
        final parts = timeStr.split(':');
        if (parts.isNotEmpty) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final slotMinutes = hour * 60 + minute;
          final nowMinutes = nowWib.hour * 60 + nowWib.minute;
          if (slotMinutes <= nowMinutes) {
            isPast = true;
          }
          // Sudah masuk jeda minimal sebelum jam mulai: pemesanan ditutup.
          if (slotMinutes - leadMinutes <= nowMinutes) {
            isClosed = true;
          }
        }
      }
    }
    if (isPast) isClosed = true; // lewat selalu berarti ditutup

    return PickupSlot(
      time: timeStr,
      capacity: (j['capacity'] as num?)?.toInt() ?? 0,
      booked: (j['booked'] as num?)?.toInt() ?? 0,
      available: available,
      isPast: isPast,
      isClosed: isClosed,
      // Pakai field backend; fallback bila server lama belum mengirim `bookable`.
      bookable: j['bookable'] is bool ? j['bookable'] as bool : (!isClosed && available > 0),
    );
  }
}

