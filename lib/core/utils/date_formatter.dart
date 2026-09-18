import 'package:intl/intl.dart';

String formatDateID(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

String formatDateShort(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('d MMM yyyy', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}

String formatDateTime(String iso) {
  if (iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);
  } catch (_) {
    return iso;
  }
}
