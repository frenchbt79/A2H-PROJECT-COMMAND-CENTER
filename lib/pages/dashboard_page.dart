import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/top_right_panel.dart';
import '../state/project_providers.dart';
import '../widgets/crud_dialogs.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < Tokens.mobileBreakpoint;
    if (isMobile) return _MobileLayout();
    return _DesktopLayout();
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
          // Row 1: Summary tiles
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Expanded(child: _ChangeOrderSummaryTile()),
                const SizedBox(width: 12),
                Expanded(child: _SubmittalStatusTile()),
                const SizedBox(width: 12),
                Expanded(child: _RfiStatusTile()),
                const SizedBox(width: 12),
                Expanded(child: _BudgetOverviewTile()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Row 2: Gantt + Calendar/Deadlines
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
          // Row 3: Files + Todos
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
        // Summary tiles in 2x2 grid on mobile
        Row(
          children: [
            Expanded(child: SizedBox(height: 100, child: _ChangeOrderSummaryTile())),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 100, child: _SubmittalStatusTile())),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: SizedBox(height: 100, child: _RfiStatusTile())),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 100, child: _BudgetOverviewTile())),
          ],
        ),
        const SizedBox(height: 12),
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
// SUMMARY TILE: Change Orders
// ═══════════════════════════════════════════════════════════
class _ChangeOrderSummaryTile extends ConsumerWidget {
  static final _fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(changeOrdersProvider);
    final approvedTotal = orders
        .where((c) => c.status == 'Approved')
        .fold<double>(0, (sum, c) => sum + c.amount);
    final pendingTotal = orders
        .where((c) => c.status == 'Pending')
        .fold<double>(0, (sum, c) => sum + c.amount);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: Tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text('CHANGE ORDERS', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Text('${orders.length}', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Approved', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.chipGreen)),
                    Text(_fmt.format(approvedTotal), style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: Tokens.chipGreen)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.chipYellow)),
                    Text(_fmt.format(pendingTotal), style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: Tokens.chipYellow)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY TILE: Submittals
// ═══════════════════════════════════════════════════════════
class _SubmittalStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(submittalsProvider);
    final approved = subs.where((s) => s.status == 'Approved' || s.status == 'Approved as Noted').length;
    final pending = subs.where((s) => s.status == 'Pending').length;
    final revise = subs.where((s) => s.status == 'Revise & Resubmit').length;
    final total = subs.length;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: Tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text('SUBMITTALS', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Text('$total', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          if (total > 0) ...[
            _MiniBar(segments: [
              _BarSegment(approved / total, Tokens.chipGreen),
              _BarSegment(pending / total, Tokens.chipYellow),
              _BarSegment(revise / total, Tokens.chipOrange),
            ]),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              _MiniStat(label: 'Approved', count: approved, color: Tokens.chipGreen),
              const SizedBox(width: 8),
              _MiniStat(label: 'Pending', count: pending, color: Tokens.chipYellow),
              if (revise > 0) ...[
                const SizedBox(width: 8),
                _MiniStat(label: 'Revise', count: revise, color: Tokens.chipOrange),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY TILE: RFIs
// ═══════════════════════════════════════════════════════════
class _RfiStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rfis = ref.watch(rfisProvider);
    final open = rfis.where((r) => r.status == 'Open').length;
    final pending = rfis.where((r) => r.status == 'Pending').length;
    final closed = rfis.where((r) => r.status == 'Closed').length;
    final now = DateTime.now();
    final overdue = rfis.where((r) =>
        r.status != 'Closed' &&
        now.difference(r.dateOpened).inDays > 14).length;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: Tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text('RFIs', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10)),
              const Spacer(),
              if (overdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Tokens.chipRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  ),
                  child: Text('$overdue overdue', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.chipRed, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _MiniStat(label: 'Open', count: open, color: Tokens.chipBlue),
              const SizedBox(width: 8),
              _MiniStat(label: 'Pending', count: pending, color: Tokens.chipYellow),
              const SizedBox(width: 8),
              _MiniStat(label: 'Closed', count: closed, color: Tokens.chipGreen),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY TILE: Budget Overview
// ═══════════════════════════════════════════════════════════
class _BudgetOverviewTile extends ConsumerWidget {
  static final _fmt = NumberFormat.compact();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final totalBudget = budget.fold<double>(0, (s, b) => s + b.budgeted);
    final totalSpent = budget.fold<double>(0, (s, b) => s + b.spent);
    final totalCommitted = budget.fold<double>(0, (s, b) => s + b.committed);
    final used = totalSpent + totalCommitted;
    final pct = totalBudget > 0 ? used / totalBudget : 0.0;
    final barColor = pct > 0.9 ? Tokens.chipRed : pct > 0.75 ? Tokens.chipYellow : Tokens.chipGreen;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text('BUDGET', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10)),
              const Spacer(),
              Text('${(pct * 100).toInt()}%', style: AppTheme.caption.copyWith(fontSize: 11, color: barColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: Tokens.glassBorder,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('\$${_fmt.format(totalBudget)} budget', style: AppTheme.caption.copyWith(fontSize: 9)),
              ),
              Text('\$${_fmt.format(totalBudget - used)} remaining', style: AppTheme.caption.copyWith(fontSize: 9, color: barColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED HELPERS for summary tiles
// ═══════════════════════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _MiniStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$count', style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 2),
        Text(label, style: AppTheme.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _BarSegment {
  final double fraction;
  final Color color;
  const _BarSegment(this.fraction, this.color);
}

class _MiniBar extends StatelessWidget {
  final List<_BarSegment> segments;
  const _MiniBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: segments.map((seg) {
            if (seg.fraction <= 0) return const SizedBox.shrink();
            return Flexible(
              flex: (seg.fraction * 100).round().clamp(1, 100),
              child: Container(color: seg.color),
            );
          }).toList(),
        ),
      ),
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
            child: Column(
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
                          child: ClipRect(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final barArea = constraints.maxWidth;
                                return Stack(
                                  children: [
                                    Positioned.fill(child: Center(child: Container(height: 1, color: Tokens.glassBorder))),
                                    Positioned(
                                      left: startFrac * barArea,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Container(
                                          width: widthFrac * barArea,
                                          height: 14,
                                          decoration: BoxDecoration(color: color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
class _ActiveTodosCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ActiveTodosCard> createState() => _ActiveTodosCardState();
}

class _ActiveTodosCardState extends ConsumerState<_ActiveTodosCard> {
  final _controller = TextEditingController();

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(todosProvider.notifier).add(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                return Dismissible(
                  key: ValueKey(todo.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    color: Tokens.chipRed.withValues(alpha: 0.2),
                    child: const Icon(Icons.delete_outline, size: 16, color: Tokens.chipRed),
                  ),
                  onDismissed: (_) => ref.read(todosProvider.notifier).remove(todo.id),
                  child: Padding(
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
                        child: GestureDetector(
                          onTap: () => showTodoDialog(context, ref, existing: todo),
                          child: Text(
                            todo.text,
                            style: AppTheme.body.copyWith(
                              fontSize: 12,
                              decoration: todo.done ? TextDecoration.lineThrough : null,
                              color: todo.done ? Tokens.textMuted : Tokens.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          icon: Icon(Icons.delete_outline, color: Tokens.chipRed.withValues(alpha: 0.7)),
                          onPressed: () => ref.read(todosProvider.notifier).remove(todo.id),
                          tooltip: 'Delete',
                        ),
                      ),
                    ],
                  ),
                ));
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Tokens.glassFill,
                      border: Border.all(color: Tokens.glassBorder),
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add a new to-do...',
                        hintStyle: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textMuted),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.add, color: Tokens.accent),
                    style: IconButton.styleFrom(
                      backgroundColor: Tokens.accent.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                        side: const BorderSide(color: Tokens.accent, width: 0.5),
                      ),
                    ),
                    onPressed: _addTodo,
                    tooltip: 'Add to-do',
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
          Flexible(
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
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
