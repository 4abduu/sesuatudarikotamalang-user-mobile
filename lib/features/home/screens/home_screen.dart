import 'package:flutter/material.dart';
import '../../../shared/app_scaffold.dart';
import '../widgets/hero_section.dart';
import '../widgets/category_grid.dart';
import '../widgets/recommendation_section.dart';
import '../widgets/creators_preview_section.dart';
import '../widgets/review_summary_section.dart';
import '../widgets/become_creator_cta_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Jarak antar-section mengikuti 01-mhome-guest.tsx:
    // kategori pt-4, rekomendasi pt-5, kreator/ulasan pt-6, CTA pt-6 + pb-6.
    return const AppScaffold(
      body: SingleChildScrollView(child: Column(children: [
        HeroSection(),
        Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: CategoryGrid()),
        Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 0), child: RecommendationSection()),
        Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 0), child: CreatorsPreviewSection()),
        Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 0), child: ReviewSummarySection()),
        Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 24), child: BecomeCreatorCtaBanner()),
      ])),
    );
  }
}
