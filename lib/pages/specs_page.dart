import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

class SpecsPage extends ConsumerWidget {
  const SpecsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDocs = ref.watch(phaseDocumentsProvider);
    final specs = allDocs.where((d) => d.docType == 'Specification').toList();

    // Group by phase
    final grouped = <String, List<PhaseDocument>>{};
    for (final s in specs) {
      grouped.putIfAbsent(s.phase, () => []).add(s);
    }
    final phases = grouped.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Specifications', style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${specs.length} specifications',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: specs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 48, color: Tokens.textMuted),
                        const SizedBox(height: 12),
                        Text('No specifications yet.', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: phases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final phase = phases[i];
                      final phaseDocs = grouped[phase]!;
                      final phaseLabel = switch (phase) {
                        'SD' => 'Schematic Design',
                        'DD' => 'Design Development',
                        'CD' => 'Construction Documents',
                        _ => phase,
                      };
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Tokens.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                  ),
                                  child: Text(
                                    phase,
                                    style: AppTheme.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: Tokens.accent),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(phaseLabel, style: AppTheme.subheading),
                                const Spacer(),
                                Text(
                                  '${phaseDocs.length} doc${phaseDocs.length == 1 ? '' : 's'}',
                                  style: AppTheme.caption.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Tokens.glassBorder, height: 1),
                            const SizedBox(height: 8),
                            ...phaseDocs.map((doc) {
                              final statusColor = _statusColor(doc.status);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.description_outlined, size: 16, color: Tokens.chipBlue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        doc.name,
                                        style: AppTheme.body.copyWith(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        doc.revision > 0 ? 'Rev ${doc.revision}' : '\u2014',
                                        style: AppTheme.caption.copyWith(fontSize: 11),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Text(doc.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 11)),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        _fmtDate(doc.modified),
                                        style: AppTheme.caption.copyWith(fontSize: 10),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                        ),
                                        child: Text(
                                          doc.status,
                                          style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'Current' => Tokens.chipGreen,
      'Under Review' => Tokens.chipYellow,
      'Draft' => Tokens.chipBlue,
      'Superseded' => Tokens.chipRed,
      _ => Tokens.textSecondary,
    };
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
