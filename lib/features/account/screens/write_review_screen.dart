import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/order_model.dart';
import '../../../features/account/providers/orders_provider.dart';
import '../../../features/account/providers/reviews_provider.dart';
import '../../../shared/app_scaffold.dart';

class WriteReviewScreen extends StatefulWidget {
  final String orderId;
  const WriteReviewScreen({super.key, required this.orderId});
  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_rating == 0 || _comment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rating dan tulis komentar')));
      return;
    }
    final orders = context.read<OrdersProvider>();
    final reviews = context.read<ReviewsProvider>();
    final order = orders.orders.cast<OrderModel?>().firstWhere(
      (o) => o?.id == widget.orderId,
      orElse: () => null,
    );

    // Ambil orderItemId dari item order jika tersedia
    final orderItemId = order?.items.isNotEmpty == true ? order!.items.first.id : null;

    setState(() => _isSubmitting = true);
    try {
      await reviews.submitReview(
        orderItemId: orderItemId,
        rating: _rating,
        comment: _comment.text.trim(),
      );
      orders.markReviewed(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan terkirim')));
        context.go('/akun/ulasan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim ulasan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tulis Ulasan',
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Beri Rating', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => _rating = i + 1), child: Icon(Icons.star, size: 36, color: i < _rating ? AppColors.mustard : AppColors.border)))),
        const SizedBox(height: 16),
        Text('Komentar', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        TextField(controller: _comment, maxLines: 4, decoration: const InputDecoration(alignLabelWithHint: true, hintText: 'Ceritakan pengalamanmu dengan produk ini...')),
        const SizedBox(height: 24),
        PrimaryButton(
          label: _isSubmitting ? 'Mengirim...' : 'Kirim Ulasan',
          icon: const Icon(Icons.send, size: 16),
          onPressed: _isSubmitting ? null : _submit,
        ),
      ])),
    );
  }
}
