import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/review_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
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

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  void _submit() {
    if (_rating == 0 || _comment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rating dan tulis komentar')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrdersProvider>();
    final reviews = context.read<ReviewsProvider>();
    final order = orders.orders.firstWhere((o) => o.id == widget.orderId, orElse: () => orders.orders.first);
    reviews.addReview(ReviewModel(id: 'r-${DateTime.now().millisecondsSinceEpoch}', productId: order.productId, author: auth.user!.name, city: 'Malang', rating: _rating, comment: _comment.text, date: 'Baru saja'));
    orders.markReviewed(widget.orderId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan terkirim')));
    context.go('/akun/ulasan');
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
        PrimaryButton(label: 'Kirim Ulasan', icon: const Icon(Icons.send, size: 16), onPressed: _submit),
      ])),
    );
  }
}
