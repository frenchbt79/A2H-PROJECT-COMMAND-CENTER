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
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final category = categories[i];
                final items = grouped[category]!;
                return _CategorySection(
                  category: category,
                  items: items,
                  icon: _iconForCategory(category),
                  color: _colorForCategory(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForCategory(String cat) {
    return switch (cat) {
      'General' => Icons.business_outlined,
      'Codes & Standards' => Icons.gavel_outlined,
      'Zoning' => Icons.map_outlined,
      'Site' => Icons.terrain_outlined,
      _ => Icons.info_outline,
    };
  }

  static Color _colorForCategory(String cat) {
    return switch (cat) {
      'General' => Tokens.accent,
      'Codes & Standards' => Tokens.chipBlue,
      'Zoning' => Tokens.chipYellow,
      'Site' => Tokens.chipGreen,
      _ => Tokens.textSecondary,
    };
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<ProjectInfoEntry> items;
  final IconData icon;
  final Color color;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                category.toUpperCase(),
                style: AppTheme.sidebarGroupLabel.copyWith(color: color, fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Tokens.glassBorder, height: 1),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(e.label, style: AppTheme.caption.copyWith(fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
