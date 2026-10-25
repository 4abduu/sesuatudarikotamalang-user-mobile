import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../data/models/creator_model.dart';
import '../../../data/models/product_model.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/artisans_provider.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  const CreatorProfileScreen({super.key, required this.creatorId});
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _following = false;
  CreatorModel? _creator;
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtisan();
  }

  Future<void> _loadArtisan() async {
    final provider = context.read<ArtisansProvider>();
    final data = await provider.getArtisanDetail(widget.creatorId);
    if (mounted) {
      setState(() {
        if (data != null) {
          _creator = data['artisan'] as CreatorModel?;
          _products = (data['products'] as List<ProductModel>?) ?? [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final creator = _creator ?? CreatorModel(id: widget.creatorId, name: 'Kreator');

    return AppScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        // px-4 pt-4 pb-6
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  creator.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                  style: GoogleFonts.baloo2(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(creator.name, style: AppTextStyles.h1.copyWith(height: 1.25), textAlign: TextAlign.center),
            Text('@${creator.handle}', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RatingStars(value: creator.rating, size: 14, showValue: true),
                const SizedBox(width: 8),
                Text('sejak ${creator.joinedYear}', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            // Kartu bio: radius 20, surface, border 1px, soft shadow, p-3.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: Text(
                creator.bio.isNotEmpty ? creator.bio : 'Kreator resmi Kayutangan.',
                style: AppTextStyles.body.copyWith(height: 1.375),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            _following
                ? SecondaryButton(
                    label: 'Mengikuti',
                    onPressed: () {
                      setState(() => _following = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhenti mengikuti ${creator.name}')),
                      );
                    },
                  )
                : PrimaryButton(
                    label: 'Ikuti Kreator',
                    onPressed: () {
                      setState(() => _following = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kamu mengikuti ${creator.name}')),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Karya dari ${creator.name}', style: AppTextStyles.h2),
            ),
            const SizedBox(height: 12),
            if (_products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Belum ada karya yang ditampilkan'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.6,
                ),
                itemCount: _products.length,
                itemBuilder: (_, i) => ProductCard(
                  product: _products[i],
                  onTap: () => context.push('/produk/${_products[i].id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
