import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';

/// Persistent info strip showing date, next deadline, open RFIs, pending todos, current phase.
class InfoBar extends ConsumerWidget {
  const InfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(deadlinesProvider);
    final rfis = ref.watch(rfisProvider);
    final todos = ref.watch(todosProvider);
    final phases = ref.watch(scheduleProvider);

    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    // Next upcoming deadline
    final upcoming = deadlines.where((d) => d.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextDeadline = upcoming.isNotEmpty ? upcoming.first : null;
    final daysUntil = nextDeadline?.date.difference(now).inDays;

    // Open RFI count
    final openRfis = rfis.where((r) => r.status == 'Open').length;
    final pendingRfis = rfis.where((r) => r.status == 'Pending').length;

    // Pending todos
    final pendingTodos = todos.where((t) => !t.done).length;

    // Current phase
    final currentPhase = phases.where((p) => p.status == 'In Progress').toList();
    final phaseLabel = currentPhase.isNotEmpty ? currentPhase.first.name : 'No active phase';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Tokens.glassFill,
        border: Border(bottom: BorderSide(color: Tokens.glassBorder.withValues(alpha: 0.5))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Date
            _InfoChip(
              icon: Icons.calendar_today,
              label: dateStr,
              color: Tokens.accent,
            ),
            const SizedBox(width: 20),
            // Current phase
            _InfoChip(
              icon: Icons.play_circle_outline,
              label: phaseLabel,
              color: Tokens.chipBlue,
            ),
            const SizedBox(width: 20),
            // Next deadline
            if (nextDeadline != null) ...[
              _InfoChip(
                icon: Icons.flag_outlined,
                label: '${nextDeadline.label} — ${daysUntil}d',
                color: daysUntil! <= 7
                    ? Tokens.chipRed
                    : daysUntil <= 30
                        ? Tokens.chipYellow
                        : Tokens.chipGreen,
              ),
              const SizedBox(width: 20),
            ],
            // Open RFIs
            _InfoChip(
              icon: Icons.help_outline,
              label: '$openRfis open · $pendingRfis pending',
              color: openRfis > 0 ? Tokens.chipYellow : Tokens.chipGreen,
            ),
            const SizedBox(width: 20),
            // Pending todos
            _InfoChip(
              icon: Icons.check_circle_outline,
              label: '$pendingTodos to-dos',
              color: pendingTodos > 5 ? Tokens.chipRed : Tokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
