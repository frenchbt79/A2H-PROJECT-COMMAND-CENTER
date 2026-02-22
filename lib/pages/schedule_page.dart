import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../services/folder_scan_service.dart' show DiscoveredMilestone, FolderScanService;
import '../widgets/folder_files_section.dart';
import 'package:intl/intl.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phases = ref.watch(scheduleProvider);
    // Timeline bounds
    final earliest = phases.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = phases.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = latest.difference(earliest).inDays.toDouble();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('SCHEDULE', style: AppTheme.heading),
                  _LegendChip(color: Tokens.chipGreen, label: 'Complete'),
                  _LegendChip(color: Tokens.chipBlue, label: 'In Progress'),
                  _LegendChip(color: Tokens.textMuted, label: 'Upcoming'),
                ],
              ),
              const SizedBox(height: Tokens.spaceLg),
              Expanded(
                flex: 3,
                child: GlassCard(
                  child: Column(
                    children: [
                      _MonthHeader(earliest: earliest, latest: latest),
                      const SizedBox(height: 8),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      Expanded(
                        child: phases.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 40, color: Tokens.textMuted),
                                    const SizedBox(height: 12),
                                    Text('No schedule phases defined.', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: phases.length,
                          itemBuilder: (context, i) => RepaintBoundary(child: _PhaseRow(
                            phase: phases[i],
                            earliest: earliest,
                            totalDays: totalDays,
                            onEdit: () => showSchedulePhaseDialog(context, ref, existing: phases[i]),
                            onDelete: () async {
                              final ok = await showDeleteConfirmation(context, phases[i].name);
                              if (ok) ref.read(scheduleProvider.notifier).remove(phases[i].id);
                            },
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _PhaseStatCard(phases: phases, statusFilter: 'Complete', color: Tokens.chipGreen),
                    _PhaseStatCard(phases: phases, statusFilter: 'In Progress', color: Tokens.chipBlue),
                    _PhaseStatCard(phases: phases, statusFilter: 'Upcoming', color: Tokens.textMuted),
                  ];
                  if (constraints.maxWidth > 500) {
                    return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList());
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
                  );
                },
              ),
              const SizedBox(height: Tokens.spaceMd),
              // ── Discovered Milestones from project folders ──
              _DiscoveredMilestonesSection(),
              const SizedBox(height: Tokens.spaceMd),
              // ── Contract Timeline from scanned filenames ──
              _ContractTimelineSection(),
              const SizedBox(height: Tokens.spaceMd),
              Expanded(
                flex: 1,
                child: FolderFilesSection(
                  sectionTitle: 'SCHEDULE & CONTRACT FILES',
                  provider: scannedScheduleProvider,
                  accentColor: Tokens.accent,
                  destinationFolder: r'0 Project Management\Schedule',
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Tokens.accent,
            onPressed: () => showSchedulePhaseDialog(context, ref),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PhaseRow({required this.phase, required this.earliest, required this.totalDays, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final startOffset = phase.start.difference(earliest).inDays / totalDays;
    final width = phase.end.difference(phase.start).inDays / totalDays;
    final color = switch (phase.status) {
      'Complete' => Tokens.chipGreen,
      'In Progress' => Tokens.chipBlue,
      _ => Tokens.textMuted,
    };

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                  return SizedBox(
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(child: Container(height: 1, color: Tokens.glassBorder)),
                        ),
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
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 14, color: Tokens.textMuted)),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 14, color: Tokens.chipRed)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveredMilestonesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(discoveredMilestonesProvider);

    return milestonesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (milestones) {
        if (milestones.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Tokens.chipYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 14, color: Tokens.chipYellow),
                  ),
                  const SizedBox(width: 8),
                  Text('DISCOVERED FROM PROJECT FILES',
                      style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10, letterSpacing: 0.8)),
                  const Spacer(),
                  Text('${milestones.length} milestone${milestones.length == 1 ? '' : 's'}',
                      style: AppTheme.caption.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 6),
              ...milestones.map((m) => _MilestoneRow(milestone: m)),
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final DiscoveredMilestone milestone;
  const _MilestoneRow({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final now = DateTime.now();
    final isPast = milestone.date.isBefore(now);
    final color = isPast ? Tokens.chipGreen : Tokens.chipBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.label,
                  style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${milestone.fileCount} file${milestone.fileCount == 1 ? '' : 's'} • ${milestone.source.split('\\').take(3).join('\\')}',
                  style: AppTheme.caption.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
            ),
            child: Text(
              fmt.format(milestone.date),
              style: AppTheme.caption.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractTimelineSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractMetadataProvider);

    return contractsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();

        final fmt = DateFormat('MMM d, yyyy');

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Tokens.chipGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.description_outlined, size: 14, color: Tokens.chipGreen),
                  ),
                  const SizedBox(width: 8),
                  Text('CONTRACT TIMELINE',
                      style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10, letterSpacing: 0.8)),
                  const Spacer(),
                  Text('${contracts.length} document${contracts.length == 1 ? '' : 's'}',
                      style: AppTheme.caption.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 6),
              ...contracts.map((c) {
                final typeColor = switch (c.type) {
                  'Original' => Tokens.chipGreen,
                  'Amendment' => Tokens.chipBlue,
                  'Consultant' => Tokens.chipYellow,
                  _ => Tokens.textMuted,
                };
                return InkWell(
                  onTap: () => FolderScanService.openFile(c.fullPath),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.displayTitle,
                            style: AppTheme.body.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          ),
                          child: Text(
                            fmt.format(c.date),
                            style: AppTheme.caption.copyWith(fontSize: 9, color: typeColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
