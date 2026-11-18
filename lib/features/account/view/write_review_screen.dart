import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../features/account/viewmodel/write_review_view_model.dart';
import '../../../shared/app_scaffold.dart';

class WriteReviewScreen extends StatefulWidget {
  final String orderId;
  const WriteReviewScreen({super.key, required this.orderId});
  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final vm = context.read<WriteReviewViewModel>();
    final ok = await vm.submit(_comment.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Ulasan terkirim' : vm.errorMessage ?? 'Gagal mengirim ulasan')));
    if (ok) context.go('/akun/ulasan');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteReviewViewModel>();
    return AppScaffold(
      title: 'Tulis Ulasan',
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Beri Rating', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => vm.setRating(i + 1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.star, size: 36, color: i < vm.rating ? AppColors.mustard : AppColors.border))))),
        const SizedBox(height: 16),
        Text('Komentar', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          minLines: 4,
          maxLines: 4,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            hintText: 'Ceritakan pengalamanmu dengan produk ini...',
            hintStyle: AppTextStyles.bodyMuted,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: vm.isSubmitting ? 'Mengirim...' : 'Kirim Ulasan',
          icon: const Icon(Icons.send_outlined, size: 16),
          onPressed: vm.isSubmitting ? null : _submit,
        ),
      ])),
    );
  }
}
