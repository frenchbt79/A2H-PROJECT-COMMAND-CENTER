import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/top_right_panel.dart';
import '../state/project_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Tokens.mobileBreakpoint;
        if (isMobile) return _MobileLayout();
        return _DesktopLayout();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ═══════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROJECT DASHBOARD', style: AppTheme.heading),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(flex: 3, child: _GanttCard()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: const TopRightPanel()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(child: _RecentFilesCard()),
                const SizedBox(width: 12),
                Expanded(child: _ActiveTodosCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE LAYOUT
// ═══════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Tokens.spaceMd),
      children: [
        Text('PROJECT DASHBOARD', style: AppTheme.heading),
        const SizedBox(height: Tokens.spaceMd),
        SizedBox(height: 300, child: _GanttCard()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _CalendarCardStandalone()),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _DeadlinesCardStandalone()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _RecentFilesCard()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _ActiveTodosCard()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GANTT CARD — reads from scheduleProvider
// ═══════════════════════════════════════════════════════════
class _GanttCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(scheduleProvider);
    final earliest = phases.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = phases.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = latest.difference(earliest).inDays.toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROJECT TIMELINE', style: AppTheme.caption),
              const Spacer(),
              _LegendDot(color: Tokens.chipGreen, label: 'Complete'),
              const SizedBox(width: 12),
              _LegendDot(color: Tokens.chipBlue, label: 'In Progress'),
              const SizedBox(width: 12),
              _LegendDot(color: Tokens.textMuted, label: 'Upcoming'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barAreaWidth = constraints.maxWidth - 130;
                return Column(
                  children: phases.map((phase) {
                    final color = switch (phase.status) {
                      'Complete' => Tokens.chipGreen,
                      'In Progress' => Tokens.chipBlue,
                      _ => Tokens.textMuted,
                    };
                    final startFrac = phase.start.difference(earliest).inDays / totalDays;
                    final widthFrac = phase.end.difference(phase.start).inDays / totalDays;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(width: 130, child: Text(phase.name, style: AppTheme.caption.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(child: Center(child: Container(height: 1, color: Tokens.glassBorder))),
                                  Positioned(
                                    left: startFrac * barAreaWidth,
                                    child: Container(
                                      width: widthFrac * barAreaWidth,
                                      height: 14,
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RECENT FILES CARD — reads from filesProvider
// ═══════════════════════════════════════════════════════════
class _RecentFilesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT FILES', style: AppTheme.caption),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: files.length.clamp(0, 6),
              itemBuilder: (context, i) {
                final f = files[i];
                final isPdf = f.name.endsWith('.pdf');
                final isImage = f.name.endsWith('.png') || f.name.endsWith('.jpg');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isPdf ? Icons.picture_as_pdf : isImage ? Icons.image_outlined : Icons.description_outlined,
                        size: 18,
                        color: isPdf ? Tokens.chipRed : isImage ? Tokens.chipBlue : Tokens.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name, style: AppTheme.body.copyWith(fontSize: 12)),
                            Text(f.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 10)),
                          ],
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
}

// ═══════════════════════════════════════════════════════════
// ACTIVE TO-DOS CARD — reads from todosProvider
// ═══════════════════════════════════════════════════════════
class _ActiveTodosCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);
    final doneCount = todos.where((t) => t.done).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ACTIVE TO-DOS', style: AppTheme.caption),
              const Spacer(),
              Text('$doneCount/${todos.length}', style: AppTheme.caption.copyWith(color: Tokens.chipGreen)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: todos.length,
              itemBuilder: (context, i) {
                final todo = todos[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: Checkbox(
                          value: todo.done,
                          onChanged: (_) => ref.read(todosProvider.notifier).toggle(todo.id),
                          activeColor: Tokens.accent,
                          side: const BorderSide(color: Tokens.textMuted),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          todo.text,
                          style: AppTheme.body.copyWith(
                            fontSize: 12,
                            decoration: todo.done ? TextDecoration.lineThrough : null,
                            color: todo.done ? Tokens.textMuted : Tokens.textPrimary,
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
}

// ═══════════════════════════════════════════════════════════
// STANDALONE CALENDAR (mobile)
// ═══════════════════════════════════════════════════════════
class _CalendarCardStandalone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
          Row(children: days.map((d) => Expanded(child: Center(child: Text(d, style: AppTheme.caption.copyWith(fontSize: 10))))).toList()),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: cells.map((d) => Center(
                child: d == 0 ? const SizedBox.shrink() : Container(
                  width: 26, height: 26,
                  decoration: d == now.day ? BoxDecoration(color: Tokens.accent, borderRadius: BorderRadius.circular(6)) : null,
                  alignment: Alignment.center,
                  child: Text('$d', style: AppTheme.caption.copyWith(fontSize: 11, color: d == now.day ? Tokens.bgDark : Tokens.textSecondary)),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STANDALONE DEADLINES (mobile)
// ═══════════════════════════════════════════════════════════
class _DeadlinesCardStandalone extends ConsumerWidget {
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(dl.label, style: AppTheme.body.copyWith(fontSize: 12))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Tokens.radiusSm)),
                        child: Text(dateStr, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
