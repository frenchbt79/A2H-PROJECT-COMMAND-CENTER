import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(scheduleProvider);
    // Timeline bounds
    final earliest = phases.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = phases.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = latest.difference(earliest).inDays.toDouble();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SCHEDULE', style: AppTheme.heading),
              const Spacer(),
              _LegendChip(color: Tokens.chipGreen, label: 'Complete'),
              const SizedBox(width: 12),
              _LegendChip(color: Tokens.chipBlue, label: 'In Progress'),
              const SizedBox(width: 12),
              _LegendChip(color: Tokens.textMuted, label: 'Upcoming'),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Phase detail cards
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  // Gantt header months
                  _MonthHeader(earliest: earliest, latest: latest),
                  const SizedBox(height: 8),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  // Phase rows
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: phases.length,
                      itemBuilder: (context, i) => _PhaseRow(
                        phase: phases[i],
                        earliest: earliest,
                        totalDays: totalDays,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bottom stats row
          Row(
            children: [
              Expanded(child: _PhaseStatCard(phases: phases, statusFilter: 'Complete', color: Tokens.chipGreen)),
              const SizedBox(width: 12),
              Expanded(child: _PhaseStatCard(phases: phases, statusFilter: 'In Progress', color: Tokens.chipBlue)),
              const SizedBox(width: 12),
              Expanded(child: _PhaseStatCard(phases: phases, statusFilter: 'Upcoming', color: Tokens.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime earliest;
  final DateTime latest;
  const _MonthHeader({required this.earliest, required this.latest});

  @override
  Widget build(BuildContext context) {
    final months = <String>[];
    var d = DateTime(earliest.year, earliest.month);
    while (d.isBefore(latest) || d.month == latest.month && d.year == latest.year) {
      const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final label = d.year == earliest.year || d.month == 1 ? '${names[d.month - 1]} ${d.year}' : names[d.month - 1];
      months.add(label);
      d = DateTime(d.year, d.month + 1);
    }

    return SizedBox(
      height: 20,
      child: Row(
        children: [
          const SizedBox(width: 160),
          Expanded(
            child: Row(
              children: months.map((m) => Expanded(
                child: Text(m, style: AppTheme.caption.copyWith(fontSize: 9), textAlign: TextAlign.center, overflow: TextOverflow.clip),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final SchedulePhase phase;
  final DateTime earliest;
  final double totalDays;
  const _PhaseRow({required this.phase, required this.earliest, required this.totalDays});

  @override
  Widget build(BuildContext context) {
    final startOffset = phase.start.difference(earliest).inDays / totalDays;
    final width = phase.end.difference(phase.start).inDays / totalDays;
    final color = switch (phase.status) {
      'Complete' => Tokens.chipGreen,
      'In Progress' => Tokens.chipBlue,
      _ => Tokens.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase.name, style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
                Text('${(phase.progress * 100).toInt()}% complete', style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Track
                    Positioned.fill(
                      child: Center(child: Container(height: 1, color: Tokens.glassBorder)),
                    ),
                    // Full bar
                    Positioned(
                      left: startOffset * constraints.maxWidth,
                      child: Container(
                        width: width * constraints.maxWidth,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    // Progress fill
                    if (phase.progress > 0)
                      Positioned(
                        left: startOffset * constraints.maxWidth,
                        child: Container(
                          width: width * constraints.maxWidth * phase.progress,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseStatCard extends StatelessWidget {
  final List<SchedulePhase> phases;
  final String statusFilter;
  final Color color;
  const _PhaseStatCard({required this.phases, required this.statusFilter, required this.color});

  @override
  Widget build(BuildContext context) {
    final matching = phases.where((p) => p.status == statusFilter).toList();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(statusFilter.toUpperCase(), style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${matching.length}', style: AppTheme.heading.copyWith(color: color, fontSize: 28)),
          Text('phase${matching.length == 1 ? '' : 's'}', style: AppTheme.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
