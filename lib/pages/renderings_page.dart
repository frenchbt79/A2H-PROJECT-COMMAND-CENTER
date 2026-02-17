import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

class RenderingsPage extends ConsumerWidget {
  const RenderingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderings = ref.watch(renderingsProvider);
    final totalSize = renderings.fold(0, (s, r) => s + r.sizeBytes);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.panorama_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('RENDERINGS', style: AppTheme.heading),
              const Spacer(),
              Text(
                '${renderings.length} renderings  •  ${(totalSize / (1024 * 1024)).toStringAsFixed(0)} MB',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 550
                      ? 2
                      : 1;
              if (renderings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.panorama_outlined, size: 40, color: Tokens.textMuted),
                      const SizedBox(height: 12),
                      Text('No renderings yet', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                    ],
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: renderings.length,
                itemBuilder: (context, i) => _RenderingCard(rendering: renderings[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RenderingCard extends StatelessWidget {
  final RenderingItem rendering;
  const _RenderingCard({required this.rendering});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (rendering.status) {
      'Final' => Tokens.chipGreen,
      'Client Review' => Tokens.chipYellow,
      'Draft' => Tokens.chipBlue,
      'In Progress' => Tokens.accent,
      _ => Tokens.textSecondary,
    };

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Placeholder thumbnail
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: rendering.placeholderColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForViewType(rendering.viewType),
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rendering.viewType,
                      style: AppTheme.caption.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rendering.title,
                    style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: Tokens.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                        ),
                        child: Text(
                          rendering.status,
                          style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmtDate(rendering.created),
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForViewType(String type) {
    return switch (type) {
      'Exterior' => Icons.home_outlined,
      'Interior' => Icons.chair_outlined,
      'Aerial' => Icons.flight_outlined,
      'Detail' => Icons.zoom_in_outlined,
      _ => Icons.panorama_outlined,
    };
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
