import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

class ProjectInfoPage extends ConsumerWidget {
  const ProjectInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(projectInfoProvider);

    // Group by category
    final grouped = <String, List<ProjectInfoEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    final categories = grouped.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('PROJECT INFORMATION', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (!isWide) {
                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _CategoryCard(
                    category: categories[i],
                    entries: grouped[categories[i]]!,
                  ),
                );
              }
              // Two-column masonry-style layout
              final leftCats = <String>[];
              final rightCats = <String>[];
              for (var i = 0; i < categories.length; i++) {
                if (i % 2 == 0) {
                  leftCats.add(categories[i]);
                } else {
                  rightCats.add(categories[i]);
                }
              }
              return SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: leftCats.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CategoryCard(category: cat, entries: grouped[cat]!),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: rightCats.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CategoryCard(category: cat, entries: grouped[cat]!),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final List<ProjectInfoEntry> entries;
  const _CategoryCard({required this.category, required this.entries});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = switch (category) {
      'General' => Icons.business_outlined,
      'Codes & Standards' => Icons.gavel_outlined,
      'Zoning' => Icons.map_outlined,
      'Site' => Icons.terrain_outlined,
      'Contacts' => Icons.people_outlined,
      _ => Icons.folder_outlined,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(categoryIcon, size: 18, color: Tokens.accent),
              const SizedBox(width: 8),
              Text(
                category.toUpperCase(),
                style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Tokens.glassBorder, height: 1),
          const SizedBox(height: 8),
          ...entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(e.label, style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted)),
                ),
                Expanded(
                  child: Text(e.value, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
