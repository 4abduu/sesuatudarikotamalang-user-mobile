import 'package:intl/intl.dart';

/// Backend mengirim waktu dalam ISO UTC (akhiran Z). Semua tampilan ke pengguna memakai WIB (UTC+7),
/// terlepas dari zona waktu perangkat. `DateTime.parse` pada string berakhiran Z menghasilkan waktu UTC,
/// jadi tanpa konversi ini jam yang tampil mundur 7 jam.
///
/// Catatan: `pickupDate` disimpan sebagai tanggal kalender WIB pada pukul 00:00 UTC, sehingga konversi
/// +7 jam tetap menghasilkan tanggal yang sama.
DateTime toWib(DateTime d) => d.toUtc().add(const Duration(hours: 7));

String formatDateID(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = toWib(DateTime.parse(iso));
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

String formatDateShort(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = toWib(DateTime.parse(iso));
    return DateFormat('d MMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

String formatDateTime(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = toWib(DateTime.parse(iso));
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

/// Seperti [formatDateTime] tetapi dengan keterangan zona, untuk batas waktu penting
/// (batas hold, batas refund) agar tidak ambigu bagi pembeli di luar WIB.
String formatDateTimeWib(String iso) {
  final base = formatDateTime(iso);
  return base == '—' || base == iso ? base : '$base WIB';
}

/// Merapikan teks body notifikasi (misal: "Batas hold: 2026-11-23T10:15:00.000Z")
/// agar tanggal ISO mentah diubah ke format ramah pembeli (WIB).
String formatNotificationBody(String body) {
  if (body.isEmpty) return body;
  final isoPattern = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?');
  return body.replaceAllMapped(isoPattern, (match) {
    final matchedText = match.group(0)!;
    final formatted = formatDateTimeWib(matchedText);
    return formatted != matchedText ? formatted : matchedText;
  });
}
