import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../state/nav_state.dart';
import '../state/folder_scan_providers.dart';
import '../services/folder_scan_service.dart' show DiscoveredMilestone;
import 'glass_card.dart';

/// Calendar + Deadlines stacked panel for the dashboard top-right.
class TopRightPanel extends ConsumerWidget {
  const TopRightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(child: _MiniCalendarCard()),
        const SizedBox(height: 12),
        Expanded(child: _DeadlinesCard()),
      ],
    );
  }
}

// ── Mini Calendar ─────────────────────────────────────────
class _MiniCalendarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final cells = List.generate(startWeekday, (_) => 0) + List.generate(daysInMonth, (i) => i + 1);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CALENDAR', style: AppTheme.caption),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${months[now.month - 1]} ${now.year}', style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                    Row(children: [
                      Icon(Icons.chevron_left, size: 16, color: Tokens.textMuted),
                      Icon(Icons.chevron_right, size: 16, color: Tokens.textMuted),
                    ]),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: dayLabels.map((d) => Expanded(child: Center(child: Text(d, style: AppTheme.caption.copyWith(fontSize: 10))))).toList()),
                const SizedBox(height: 4),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: cells.map((d) => Center(
                      child: d == 0 ? const SizedBox.shrink() : Container(
                        width: 22, height: 22,
                        decoration: d == now.day ? BoxDecoration(color: Tokens.accent, borderRadius: BorderRadius.circular(6)) : null,
                        alignment: Alignment.center,
                        child: Text('$d', style: AppTheme.caption.copyWith(fontSize: 10, color: d == now.day ? Tokens.bgDark : Tokens.textSecondary, fontWeight: d == now.day ? FontWeight.w700 : FontWeight.w400)),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Key Milestones & Deadlines ────────────────────────────
class _DeadlinesCard extends ConsumerWidget {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(deadlinesProvider);
    final discoveredAsync = ref.watch(discoveredMilestonesProvider);
    final discovered = discoveredAsync.valueOrNull ?? <DiscoveredMilestone>[];
    final now = DateTime.now();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('KEY MILESTONES & DEADLINES', style: AppTheme.caption),
              const Spacer(),
              if (discovered.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Tokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  ),
                  child: Text('${deadlines.length + discovered.length}', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Manual deadlines
                ...deadlines.map((dl) {
                  final color = switch (dl.severity) { 'green' => Tokens.chipGreen, 'yellow' => Tokens.chipYellow, 'red' => Tokens.chipRed, _ => Tokens.chipBlue };
                  final dateStr = '${_months[dl.date.month - 1]} ${dl.date.day}, ${dl.date.year}';
                  final daysAway = dl.date.difference(now).inDays;
                  final subLabel = daysAway > 0 ? 'in $daysAway days' : daysAway == 0 ? 'Today' : '${-daysAway} days ago';
                  return _DeadlineRow(
                    label: dl.label,
                    date: dateStr,
                    subLabel: subLabel,
                    color: color,
                    onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.schedule),
                  );
                }),
                // Discovered milestones from project files
                if (discovered.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 10, color: Tokens.chipYellow),
                      const SizedBox(width: 4),
                      Text('FROM PROJECT FILES', style: AppTheme.caption.copyWith(fontSize: 8, letterSpacing: 0.6, color: Tokens.chipYellow)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...discovered.map((m) {
                    final isPast = m.date.isBefore(now);
                    final color = isPast ? Tokens.chipGreen : Tokens.chipBlue;
                    final dateStr = '${_months[m.date.month - 1]} ${m.date.day}, ${m.date.year}';
                    final subLabel = isPast ? '${m.fileCount} files' : 'in ${m.date.difference(now).inDays} days';
                    return _DeadlineRow(
                      label: m.label,
                      date: dateStr,
                      subLabel: subLabel,
                      color: color,
                      onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.schedule),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final String label;
  final String date;
  final String subLabel;
  final Color color;
  final VoidCallback? onTap;
  const _DeadlineRow({required this.label, required this.date, required this.subLabel, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text(subLabel, style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Tokens.radiusSm)),
              child: Text(date, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
