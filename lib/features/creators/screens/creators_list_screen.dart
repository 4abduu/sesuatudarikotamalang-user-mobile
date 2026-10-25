import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/search_helper.dart';
import '../../../core/widgets/app_search_decoration.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_title.dart';
import '../../../data/models/creator_model.dart';
import '../../../shared/app_scaffold.dart';
import '../providers/artisans_provider.dart';
import '../widgets/creator_card.dart';

class CreatorsListScreen extends StatefulWidget {
  const CreatorsListScreen({super.key});
  @override
  State<CreatorsListScreen> createState() => _CreatorsListScreenState();
}

class _CreatorsListScreenState extends State<CreatorsListScreen> {
  String _search = '';

  List<CreatorModel> _filtered(List<CreatorModel> list) {
    if (_search.trim().isEmpty) return list;
    return list.where((c) => matchesCreatorQuery(c, _search)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final artisansProvider = context.watch<ArtisansProvider>();
    final allArtisans = artisansProvider.artisans;
    final list = _filtered(allArtisans);

    return AppScaffold(
      title: 'Meet The Artisans',
      body: RefreshIndicator(
        onRefresh: () => artisansProvider.fetchArtisans(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(eyebrow: 'Artisans', title: 'Tangan-tangan di Balik Karya'),
              const SizedBox(height: 8),
              Text(
                'Setiap kreator punya cerita dan keahlian unik. Kenalan yuk!',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                style: appSearchTextStyle,
                decoration: appSearchDecoration('Cari nama kreator...'),
              ),
              const SizedBox(height: 16),
              if (artisansProvider.isLoading && allArtisans.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (list.isEmpty)
                const EmptyState(
                  icon: Icons.person_search,
                  title: 'Tidak ada kreator yang cocok',
                  description: 'Coba kata kunci lain, atau jelajahi semua kreator.',
                )
              else
                ...list.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CreatorCard(
                      creator: c,
                      onTap: () => context.push('/kreator/${c.id}'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
