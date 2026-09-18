import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../creators/widgets/creator_card.dart';

class CreatorsPreviewSection extends StatelessWidget {
  const CreatorsPreviewSection({super.key});
  @override
  Widget build(BuildContext context) {
    final top = dummyCreators.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Meet The Artisans', style: AppTextStyles.h2),
      const SizedBox(height: 12),
      ...top.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: CreatorCard(creator: c, onTap: () => context.push('/kreator/${c.id}')))),
      const SizedBox(height: 8),
      Center(child: OutlinedButton(onPressed: () => context.push('/kreator'), child: const Text('Kenal semua kreator'))),
    ]);
  }
}
