import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/creator_avatar.dart';
import '../../../shared/app_scaffold.dart';
import '../viewmodel/creator_profile_view_model.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  const CreatorProfileScreen({super.key, required this.creatorId});
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CreatorProfileViewModel>();
    if (profile.isLoading) {
      return AppScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/kreator'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final creator = profile.creator;
    if (creator == null) {
      return AppScaffold(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go('/kreator')),
        body: const Center(child: Text('Kreator tidak ditemukan')),
      );
    }

    return AppScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go('/kreator'),
      ),
      body: SingleChildScrollView(
        // px-4 pt-4 pb-6
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            CreatorAvatar(
              avatarUrl: creator.avatarUrl,
              name: creator.name,
              size: 80,
              isOfficial: creator.isOfficial,
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

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Karya dari ${creator.name}', style: AppTextStyles.h2),
            ),
            const SizedBox(height: 12),
            if (profile.products.isEmpty)
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
                itemCount: profile.products.length,
                itemBuilder: (_, i) => ProductCard(
                  product: profile.products[i],
                  onTap: () => context.pushNamed('productDetail',
                      pathParameters: {'id': profile.products[i].id}),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
