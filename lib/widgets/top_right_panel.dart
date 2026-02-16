import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
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
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 7,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3,
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

// ── Deadlines ─────────────────────────────────────────────
class _DeadlinesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(deadlinesProvider);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UPCOMING DEADLINES', style: AppTheme.caption),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: deadlines.map((dl) {
                final color = switch (dl.severity) { 'green' => Tokens.chipGreen, 'yellow' => Tokens.chipYellow, 'red' => Tokens.chipRed, _ => Tokens.chipBlue };
                final dateStr = '${months[dl.date.month - 1]} ${dl.date.day.toString().padLeft(2, '0')}';
                return _DeadlineRow(label: dl.label, date: dateStr, color: color);
              }).toList(),
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
  final Color color;
  const _DeadlineRow({required this.label, required this.date, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTheme.body.copyWith(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Tokens.radiusSm)),
            child: Text(date, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
          ),
        ],
      ),
    );
  }
}
