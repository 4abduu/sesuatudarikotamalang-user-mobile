import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
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
    return const AppScaffold(
      body: SingleChildScrollView(padding: EdgeInsets.only(bottom: AppDimens.spaceLg), child: Column(children: [
        HeroSection(),
        Padding(padding: EdgeInsets.all(16), child: CategoryGrid()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: RecommendationSection()),
        SizedBox(height: 24),
        Padding(padding: EdgeInsets.all(16), child: CreatorsPreviewSection()),
        SizedBox(height: 24),
        Padding(padding: EdgeInsets.all(16), child: ReviewSummarySection()),
        SizedBox(height: 24),
        Padding(padding: EdgeInsets.all(16), child: BecomeCreatorCtaBanner()),
      ])),
    );
  }
}
