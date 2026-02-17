import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

/// Serves 2 routes: Progress Prints and Signed Prints.
class PrintSetsPage extends ConsumerWidget {
  final String printType; // 'Progress' or 'Signed/Sealed'
  final String title;

  const PrintSetsPage({
    super.key,
    required this.printType,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSets = ref.watch(printSetsProvider);
    final sets = allSets.where((s) => s.type == printType).toList();
    final totalSheets = sets.fold(0, (sum, s) => sum + s.sheetCount);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Icon(
                printType == 'Progress' ? Icons.print_outlined : Icons.verified_outlined,
                color: Tokens.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title.toUpperCase(), style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              ),
              Text('${sets.length} sets  •  $totalSheets sheets total', style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          // ── Cards ─────────────────────────────────────────
          Expanded(
            child: sets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print_disabled_outlined, size: 40, color: Tokens.textMuted),
                        const SizedBox(height: 12),
                        Text('No print sets of this type.', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PrintSetCard(ps: sets[i], printType: printType),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrintSetCard extends StatelessWidget {
  final PrintSet ps;
  final String printType;
  const _PrintSetCard({required this.ps, required this.printType});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ps.status) {
      'Distributed' => Tokens.chipGreen,
      'Pending' => Tokens.chipYellow,
      'Archived' => Tokens.textMuted,
      _ => Tokens.textSecondary,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ps.title, style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Text(ps.status, style: AppTheme.caption.copyWith(fontSize: 11, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoTile(label: 'Date', value: _fmtDate(ps.date)),
              const SizedBox(width: 24),
              _InfoTile(label: 'Sheets', value: '${ps.sheetCount}'),
              const SizedBox(width: 24),
              Expanded(child: _InfoTile(label: 'Distributed To', value: ps.distributedTo)),
            ],
          ),
          if (ps.sealedBy != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified, size: 14, color: Tokens.chipGreen),
                const SizedBox(width: 6),
                Text(
                  'Sealed by ${ps.sealedBy}',
                  style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.chipGreen),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
