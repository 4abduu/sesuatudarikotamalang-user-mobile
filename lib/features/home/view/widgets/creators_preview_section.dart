import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../viewmodel/home_view_model.dart';
import '../../../creators/view/widgets/creator_card.dart';

class CreatorsPreviewSection extends StatelessWidget {
  const CreatorsPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final top = context.watch<HomeViewModel>().featuredCreators;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meet The Artisans', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        if (top.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Belum ada data kreator')),
          )
        else
          ...top.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CreatorCard(
                creator: c,
                onTap: () => context.pushNamed('creatorProfile',
                    pathParameters: {'id': c.id}),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: OutlinedButton(
            onPressed: () => context.push('/kreator'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: GoogleFonts.baloo2(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Kenal semua kreator'),
          ),
        ),
      ],
    );
  }
}
