import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/dummy/dummy_products.dart';
import '../../../shared/app_scaffold.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  const CreatorProfileScreen({super.key, required this.creatorId});
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final creator = dummyCreators.firstWhere((c) => c.id == widget.creatorId, orElse: () => dummyCreators.first);
    final products = dummyProducts.where((p) => p.creatorId == creator.id).toList();
    return AppScaffold(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(width: 80, height: 80, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), shape: BoxShape.circle), child: Center(child: Text(creator.name.split(' ').map((w) => w[0]).take(2).join(), style: GoogleFonts.baloo2(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onPrimary)))),
        const SizedBox(height: 12),
        Text(creator.name, style: AppTextStyles.h1),
        Text('@${creator.handle}', style: AppTextStyles.bodyMuted),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [RatingStars(value: creator.rating, size: 14, showValue: true), const SizedBox(width: 8), Text('sejak ${creator.joinedYear}', style: AppTextStyles.caption)]),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(creator.bio, style: AppTextStyles.body, textAlign: TextAlign.center))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _following
          ? OutlinedButton(onPressed: () { setState(() => _following = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhenti mengikuti ${creator.name}'))); }, child: const Text('Mengikuti'))
          : ElevatedButton(onPressed: () { setState(() => _following = true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kamu mengikuti ${creator.name}'))); }, child: const Text('Ikuti Kreator'))),
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerLeft, child: Text('Karya dari ${creator.name}', style: AppTextStyles.h2)),
        const SizedBox(height: 12),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.72),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductCard(product: products[i], onTap: () => context.push('/produk/${products[i].id}')),
        ),
      ])),
    );
  }
}
