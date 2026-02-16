import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

/// Serves 6 discipline routes: Architectural, Civil, Landscape,
/// Mechanical, Electrical, Plumbing.
class DisciplinePage extends ConsumerWidget {
  final String disciplineName;
  final IconData icon;
  final Color accentColor;

  const DisciplinePage({
    super.key,
    required this.disciplineName,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSheets = ref.watch(drawingSheetsProvider);
    final sheets = allSheets.where((s) => s.discipline == disciplineName).toList();
    final current = sheets.where((s) => s.status == 'Current').length;
    final inProgress = sheets.where((s) => s.status == 'In Progress').length;
    final review = sheets.where((s) => s.status == 'Review').length;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(disciplineName.toUpperCase(), style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              ),
              _CountChip(label: 'Current', count: current, color: Tokens.chipGreen),
              const SizedBox(width: 8),
              _CountChip(label: 'In Progress', count: inProgress, color: Tokens.chipYellow),
              if (review > 0) ...[
                const SizedBox(width: 8),
                _CountChip(label: 'Review', count: review, color: Tokens.chipBlue),
              ],
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          // ── Summary tiles ─────────────────────────────────
          _buildSummaryRow(sheets),
          const SizedBox(height: Tokens.spaceMd),
          // ── Drawing index ─────────────────────────────────
          Expanded(child: _buildDrawingTable(sheets)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<DrawingSheet> sheets) {
    final latestRev = sheets.isNotEmpty
        ? sheets.reduce((a, b) => a.lastRevised.isAfter(b.lastRevised) ? a : b)
        : null;
    final phases = sheets.map((s) => s.phase).toSet().join(', ');

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Sheets', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text('${sheets.length}', style: AppTheme.heading.copyWith(color: accentColor)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phases', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text(phases.isNotEmpty ? phases : '—', style: AppTheme.subheading),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last Revision', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text(
                  latestRev != null ? _fmtDate(latestRev.lastRevised) : '—',
                  style: AppTheme.subheading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingTable(List<DrawingSheet> sheets) {
    return GlassCard(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text('SHEET #', style: AppTheme.sidebarGroupLabel)),
                Expanded(flex: 4, child: Text('TITLE', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 60, child: Text('PHASE', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 50, child: Text('REV', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 90, child: Text('LAST REVISED', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 80, child: Text('STATUS', style: AppTheme.sidebarGroupLabel)),
              ],
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1),
          Expanded(
            child: sheets.isEmpty
                ? Center(child: Text('No drawings for this discipline.', style: AppTheme.caption))
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: sheets.length,
                    separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                    itemBuilder: (context, i) {
                      final s = sheets[i];
                      final statusColor = switch (s.status) {
                        'Current' => Tokens.chipGreen,
                        'In Progress' => Tokens.chipYellow,
                        'Review' => Tokens.chipBlue,
                        _ => Tokens.chipRed,
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                s.sheetNumber,
                                style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(s.title, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(s.phase, style: AppTheme.caption.copyWith(fontSize: 11)),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text('Rev ${s.revision}', style: AppTheme.caption.copyWith(fontSize: 11)),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(_fmtDate(s.lastRevised), style: AppTheme.caption.copyWith(fontSize: 10)),
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
                                  s.status,
                                  style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
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

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
