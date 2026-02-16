import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(budgetProvider);
    final totalBudget = lines.fold(0.0, (s, l) => s + l.budgeted);
    final totalSpent = lines.fold(0.0, (s, l) => s + l.spent);
    final totalCommitted = lines.fold(0.0, (s, l) => s + l.committed);
    final totalRemaining = totalBudget - totalSpent - totalCommitted;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUDGET', style: AppTheme.heading),
          const SizedBox(height: Tokens.spaceLg),
          // Summary tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _BudgetTile(label: 'Total Budget', value: _fmt(totalBudget), color: Tokens.textPrimary),
                _BudgetTile(label: 'Spent', value: _fmt(totalSpent), color: Tokens.chipRed),
                _BudgetTile(label: 'Committed', value: _fmt(totalCommitted), color: Tokens.chipYellow),
                _BudgetTile(label: 'Remaining', value: _fmt(totalRemaining), color: Tokens.chipGreen),
              ];
              if (constraints.maxWidth > 600) {
                return Row(children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: t))).toList());
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: tiles.map((t) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: t)).toList(),
              );
            },
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Table
          Expanded(
            child: GlassCard(
              child: LayoutBuilder(
                builder: (context, outerConstraints) {
                  final minTableWidth = outerConstraints.maxWidth < 700 ? 700.0 : outerConstraints.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: minTableWidth,
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('CATEGORY', style: AppTheme.sidebarGroupLabel)),
                                Expanded(flex: 2, child: Text('BUDGETED', style: AppTheme.sidebarGroupLabel)),
                                Expanded(flex: 2, child: Text('SPENT', style: AppTheme.sidebarGroupLabel)),
                                Expanded(flex: 2, child: Text('COMMITTED', style: AppTheme.sidebarGroupLabel)),
                                Expanded(flex: 2, child: Text('REMAINING', style: AppTheme.sidebarGroupLabel)),
                                Expanded(flex: 3, child: Text('UTILIZATION', style: AppTheme.sidebarGroupLabel)),
                              ],
                            ),
                          ),
                          const Divider(color: Tokens.glassBorder, height: 1),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(top: 4),
                              itemCount: lines.length,
                              separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                              itemBuilder: (context, i) => _BudgetRow(line: lines[i]),
                            ),
                          ),
                          const Divider(color: Tokens.glassBorder, height: 1),
                          // Totals row
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('TOTAL', style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, fontSize: 12))),
                                Expanded(flex: 2, child: Text(_fmt(totalBudget), style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12))),
                                Expanded(flex: 2, child: Text(_fmt(totalSpent), style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: Tokens.chipRed))),
                                Expanded(flex: 2, child: Text(_fmt(totalCommitted), style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: Tokens.chipYellow))),
                                Expanded(flex: 2, child: Text(_fmt(totalRemaining), style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: Tokens.chipGreen))),
                                Expanded(flex: 3, child: _UtilBar(percent: (totalSpent + totalCommitted) / totalBudget)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _BudgetTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BudgetTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.subheading.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final BudgetLine line;
  const _BudgetRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(line.category, style: AppTheme.body.copyWith(fontSize: 12))),
          Expanded(flex: 2, child: Text(BudgetPage._fmt(line.budgeted), style: AppTheme.body.copyWith(fontSize: 12))),
          Expanded(flex: 2, child: Text(BudgetPage._fmt(line.spent), style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.chipRed))),
          Expanded(flex: 2, child: Text(BudgetPage._fmt(line.committed), style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.chipYellow))),
          Expanded(flex: 2, child: Text(
            BudgetPage._fmt(line.remaining),
            style: AppTheme.body.copyWith(fontSize: 12, color: line.remaining > 0 ? Tokens.chipGreen : Tokens.chipRed),
          )),
          Expanded(flex: 3, child: _UtilBar(percent: line.percentUsed)),
        ],
      ),
    );
  }
}

class _UtilBar extends StatelessWidget {
  final double percent;
  const _UtilBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final clamp = percent.clamp(0.0, 1.0);
    final color = clamp > 0.9 ? Tokens.chipRed : clamp > 0.7 ? Tokens.chipYellow : Tokens.chipGreen;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Tokens.glassFill,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamp,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(clamp * 100).toInt()}%', style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
      ],
    );
  }
}
