import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';

class MidtransMockSheet extends StatefulWidget {
  final int amount;
  final VoidCallback onPaid;
  const MidtransMockSheet({super.key, required this.amount, required this.onPaid});

  @override
  State<MidtransMockSheet> createState() => _MidtransMockSheetState();
}

class _MidtransMockSheetState extends State<MidtransMockSheet> {
  final _card = TextEditingController(text: '4811 1111 1111 1114');
  final _exp = TextEditingController(text: '12/26');
  final _cvv = TextEditingController(text: '123');
  bool _processing = false;

  @override
  void dispose() { _card.dispose(); _exp.dispose(); _cvv.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock, size: 16, color: AppColors.moss), const SizedBox(width: 4), Text('Pembayaran Aman', style: AppTextStyles.label)]),
      const SizedBox(height: 16),
      TextField(controller: _card, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nomor Kartu', prefixIcon: Icon(Icons.credit_card))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _exp, decoration: const InputDecoration(labelText: 'MM/YY'))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _cvv, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CVV'))),
      ]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _processing ? null : () async {
          setState(() => _processing = true);
          await Future.delayed(const Duration(seconds: 2));
          widget.onPaid();
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _processing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary)) : Text('Bayar ${formatRupiah(widget.amount)}'),
      )),
      const SizedBox(height: 8),
    ])));
  }
}
