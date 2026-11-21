import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatRupiah(int value) {
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(value);
}

/// Format angka menjadi format ribuan dengan titik (contoh: 100000 -> "100.000").
String formatRibuan(int value) {
  return NumberFormat.decimalPattern('id_ID').format(value);
}

/// Formatter input teks untuk menambahkan titik pemisah ribuan otomatis saat mengetik.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    final cleanDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final intVal = int.tryParse(cleanDigits);
    if (intVal == null) return oldValue;

    final formatted = formatRibuan(intVal);

    // Hitung posisi cursor baru agar tidak melompat ke awal
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

