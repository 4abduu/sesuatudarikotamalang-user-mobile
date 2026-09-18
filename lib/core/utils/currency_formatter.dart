import 'package:intl/intl.dart';

String formatRupiah(int value) {
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(value);
}
