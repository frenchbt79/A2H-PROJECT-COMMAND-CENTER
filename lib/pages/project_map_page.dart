import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';
import '../state/project_signals_provider.dart';
import '../models/project_signals.dart';

class ProjectMapPage extends ConsumerWidget {
  const ProjectMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(scheduleProvider);
    final deadlines = ref.watch(deadlinesProvider);
    final signalsAsync = ref.watch(projectSignalsProvider);
    final signals = signalsAsync.valueOrNull ?? ProjectSignals.empty();

    final openRfis = signals.openRfis;
    final pendingTodos = signals.pendingTodos;
    final completedPhases = signals.phasesComplete;
    final overallProgress = signals.overallProgress;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROJECT MAP', style: AppTheme.heading),
          const SizedBox(height: 4),
          Text(
            'Visual overview of project phases, milestones, and key metrics',
            style: AppTheme.caption.copyWith(color: Tokens.textMuted),
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Stats row
          _StatsRow(
            overallProgress: overallProgress,
            completedPhases: completedPhases,
            totalPhases: phases.length,
            openRfis: openRfis,
            pendingTodos: pendingTodos,
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Timeline
          Expanded(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PROJECT TIMELINE', style: AppTheme.caption),
                      const Spacer(),
                      _LegendDot(color: Tokens.chipGreen, label: 'Complete'),
                      const SizedBox(width: 14),
                      _LegendDot(color: Tokens.chipBlue, label: 'In Progress'),
                      const SizedBox(width: 14),
                      _LegendDot(color: Tokens.textMuted, label: 'Upcoming'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _TimelineView(phases: phases, deadlines: deadlines),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Deadlines bar
          SizedBox(
            height: 100,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KEY MILESTONES & DEADLINES', style: AppTheme.caption),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: deadlines.length,
                      itemBuilder: (context, i) => RepaintBoundary(child: _MilestoneChip(deadline: deadlines[i])),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final double overallProgress;
  final int completedPhases;
  final int totalPhases;
  final int openRfis;
  final int pendingTodos;

  const _StatsRow({
    required this.overallProgress,
    required this.completedPhases,
    required this.totalPhases,
    required this.openRfis,
    required this.pendingTodos,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _StatTile(
            icon: Icons.pie_chart_outline,
            label: 'Overall Progress',
            value: '${(overallProgress * 100).toInt()}%',
            color: Tokens.accent,
            progress: overallProgress,
          ),
          _StatTile(
            icon: Icons.check_circle_outline,
            label: 'Phases Complete',
            value: '$completedPhases / $totalPhases',
            color: Tokens.chipGreen,
          ),
          _StatTile(
            icon: Icons.help_outline,
            label: 'Open RFIs',
            value: '$openRfis',
            color: openRfis > 0 ? Tokens.chipYellow : Tokens.chipGreen,
          ),
          _StatTile(
            icon: Icons.assignment_outlined,
            label: 'Pending To-Dos',
            value: '$pendingTodos',
            color: pendingTodos > 5 ? Tokens.chipRed : Tokens.textSecondary,
          ),
        ];
        if (constraints.maxWidth > 600) {
          return Row(
            children: cards
                .map((c) => Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 12), child: c)))
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((c) =>
                  SizedBox(width: (constraints.maxWidth - 12) / 2, child: c))
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? progress;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.subheading.copyWith(color: color)),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Tokens.glassFill,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Timeline View ─────────────────────────────────────────────
class _TimelineView extends StatelessWidget {
  final List<SchedulePhase> phases;
  final List<Deadline> deadlines;

  const _TimelineView({required this.phases, required this.deadlines});

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) {
      return Center(
        child: Text('No schedule phases defined.',
            style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          // Vertical timeline for narrow screens
          return ListView.builder(
            itemCount: phases.length,
            itemBuilder: (context, i) => RepaintBoundary(child: _VerticalPhaseNode(
              phase: phases[i],
              isFirst: i == 0,
              isLast: i == phases.length - 1,
            )),
          );
        }
        // Horizontal timeline for wide screens
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (phases.length * 180.0).clamp(constraints.maxWidth, double.infinity),
            child: Column(
              children: [
                // Phase nodes
                Expanded(
                  child: Row(
                    children: List.generate(phases.length, (i) {
                      return Expanded(
                        child: _HorizontalPhaseNode(
                          phase: phases[i],
                          isFirst: i == 0,
                          isLast: i == phases.length - 1,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Horizontal Phase Node ─────────────────────────────────────
class _HorizontalPhaseNode extends StatelessWidget {
  final SchedulePhase phase;
  final bool isFirst;
  final bool isLast;

  const _HorizontalPhaseNode({
    required this.phase,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (phase.status) {
      'Complete' => Tokens.chipGreen,
      'In Progress' => Tokens.chipBlue,
      _ => Tokens.textMuted,
    };
    final progressPct = (phase.progress * 100).toInt();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phase name
          Text(
            phase.name,
            style: AppTheme.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Node + connecting line
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Left line
                if (!isFirst)
                  Expanded(child: Container(height: 2, color: color.withValues(alpha: 0.4)))
                else
                  const Expanded(child: SizedBox()),
                // Circle node
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: phase.status == 'Complete'
                        ? Icon(Icons.check, size: 16, color: color)
                        : phase.status == 'In Progress'
                            ? Icon(Icons.play_arrow, size: 16, color: color)
                            : Icon(Icons.circle, size: 8, color: color.withValues(alpha: 0.5)),
                  ),
                ),
                // Right line
                if (!isLast)
                  Expanded(child: Container(height: 2, color: color.withValues(alpha: 0.4)))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Progress bar
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: phase.progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Tokens.glassFill,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('$progressPct%', style: AppTheme.caption.copyWith(fontSize: 9, color: color)),
          const SizedBox(height: 4),
          // Date range
          Text(
            '${months[phase.start.month - 1]} ${phase.start.year}',
            style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
          ),
          Text(
            '${months[phase.end.month - 1]} ${phase.end.year}',
            style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Vertical Phase Node ───────────────────────────────────────
class _VerticalPhaseNode extends StatelessWidget {
  final SchedulePhase phase;
  final bool isFirst;
  final bool isLast;

  const _VerticalPhaseNode({
    required this.phase,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (phase.status) {
      'Complete' => Tokens.chipGreen,
      'In Progress' => Tokens.chipBlue,
      _ => Tokens.textMuted,
    };
    final progressPct = (phase.progress * 100).toInt();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst) Container(width: 2, height: 10, color: color.withValues(alpha: 0.4)),
                // Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: phase.status == 'Complete'
                        ? Icon(Icons.check, size: 12, color: color)
                        : phase.status == 'In Progress'
                            ? Icon(Icons.play_arrow, size: 12, color: color)
                            : Icon(Icons.circle, size: 6, color: color.withValues(alpha: 0.5)),
                  ),
                ),
                // Bottom line
                if (!isLast) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.4))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.name, style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${months[phase.start.month - 1]} ${phase.start.year} – ${months[phase.end.month - 1]} ${phase.end.year}',
                        style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                      ),
                      const Spacer(),
                      Text('$progressPct%', style: AppTheme.caption.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: phase.progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Tokens.glassFill,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone Chip ────────────────────────────────────────────
class _MilestoneChip extends StatelessWidget {
  final Deadline deadline;
  const _MilestoneChip({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final color = switch (deadline.severity) {
      'green' => Tokens.chipGreen,
      'yellow' => Tokens.chipYellow,
      'red' => Tokens.chipRed,
      _ => Tokens.chipBlue,
    };
    final now = DateTime.now();
    final daysAway = deadline.date.difference(now).inDays;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[deadline.date.month - 1]} ${deadline.date.day}';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  deadline.label,
                  style: AppTheme.body.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$dateStr · ${daysAway >= 0 ? '${daysAway}d away' : '${-daysAway}d ago'}',
            style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
