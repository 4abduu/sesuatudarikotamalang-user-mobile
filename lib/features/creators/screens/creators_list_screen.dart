import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/search_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_title.dart';
import '../../../data/dummy/dummy_creators.dart';
import '../../../data/models/creator_model.dart';
import '../../../shared/app_scaffold.dart';
import '../widgets/creator_card.dart';

class CreatorsListScreen extends StatefulWidget {
  const CreatorsListScreen({super.key});
  @override
  State<CreatorsListScreen> createState() => _CreatorsListScreenState();
}

class _CreatorsListScreenState extends State<CreatorsListScreen> {
  String _search = '';

  List<CreatorModel> get _filtered =>
      dummyCreators.where((c) => matchesCreatorQuery(c, _search)).toList();

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return AppScaffold(
      title: 'Meet The Artisans',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(eyebrow: 'Artisans', title: 'Tangan-tangan di Balik Karya'),
            const SizedBox(height: 8),
            Text('Setiap kreator punya cerita dan keahlian unik. Kenalan yuk!', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Cari nama kreator...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.person_search,
                title: 'Tidak ada kreator yang cocok',
                description: 'Coba kata kunci lain, atau jelajahi semua kreator.',
              )
            else
              ...list.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CreatorCard(
                      creator: c,
                      onTap: () => context.push('/kreator/${c.id}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
