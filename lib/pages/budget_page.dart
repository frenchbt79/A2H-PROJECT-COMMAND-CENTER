import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../services/folder_scan_service.dart' show FolderScanService;
import '../widgets/folder_files_section.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(budgetProvider);
    final totalBudget = lines.fold(0.0, (s, l) => s + l.budgeted);
    final totalSpent = lines.fold(0.0, (s, l) => s + l.spent);
    final totalCommitted = lines.fold(0.0, (s, l) => s + l.committed);
    final totalRemaining = totalBudget - totalSpent - totalCommitted;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BUDGET', style: AppTheme.heading),
              const SizedBox(height: Tokens.spaceLg),
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
              Expanded(
                flex: 3,
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
                                    const SizedBox(width: 52),
                                  ],
                                ),
                              ),
                              const Divider(color: Tokens.glassBorder, height: 1),
                              Expanded(
                                child: lines.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Tokens.textMuted),
                                            const SizedBox(height: 12),
                                            Text('No budget lines defined.', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                  padding: const EdgeInsets.only(top: 4),
                                  itemCount: lines.length,
                                  separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                                  itemBuilder: (context, i) {
                                    final line = lines[i];
                                    return RepaintBoundary(child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(line.category, style: AppTheme.body.copyWith(fontSize: 12))),
                                          Expanded(flex: 2, child: Text(_fmt(line.budgeted), style: AppTheme.body.copyWith(fontSize: 12))),
                                          Expanded(flex: 2, child: Text(_fmt(line.spent), style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.chipRed))),
                                          Expanded(flex: 2, child: Text(_fmt(line.committed), style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.chipYellow))),
                                          Expanded(flex: 2, child: Text(_fmt(line.remaining), style: AppTheme.body.copyWith(fontSize: 12, color: line.remaining > 0 ? Tokens.chipGreen : Tokens.chipRed))),
                                          Expanded(flex: 3, child: _UtilBar(percent: line.percentUsed)),
                                          SizedBox(
                                            width: 52,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () => showBudgetLineDialog(context, ref, existing: line),
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 14, color: Tokens.textMuted)),
                                                ),
                                                InkWell(
                                                  onTap: () async {
                                                    final ok = await showDeleteConfirmation(context, line.category);
                                                    if (ok) ref.read(budgetProvider.notifier).remove(line.id);
                                                  },
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 14, color: Tokens.chipRed)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ));
                                  },
                                ),
                              ),
                              const Divider(color: Tokens.glassBorder, height: 1),
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
                                    const SizedBox(width: 52),
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
              const SizedBox(height: Tokens.spaceMd),
              // ── Discovered fee worksheets ──
              _FeeWorksheetsSection(),
              const SizedBox(height: Tokens.spaceMd),
              Expanded(
                flex: 1,
                child: FolderFilesSection(
                  sectionTitle: 'FEE WORKSHEETS & CONTRACTS',
                  provider: scannedBudgetProvider,
                  accentColor: Tokens.accent,
                  destinationFolder: r'0 Project Management\Contracts\Fee Worksheets',
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
            onPressed: () => showBudgetLineDialog(context, ref),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
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

class _FeeWorksheetsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worksheetsAsync = ref.watch(feeWorksheetsProvider);

    return worksheetsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (worksheets) {
        if (worksheets.isEmpty) return const SizedBox.shrink();

        // Assign colors per discipline
        const disciplineColors = <String, Color>{
          'Architectural': Tokens.chipBlue,
          'Civil': Tokens.chipGreen,
          'Electrical': Tokens.chipYellow,
          'Fire Protection': Tokens.chipRed,
          'Landscape Architectural': Tokens.chipIndigo,
          'Mechanical': Tokens.chipOrange,
          'Planning': Tokens.accent,
          'Plumbing': Color(0xFF4DB6AC),
          'Structural': Color(0xFFBA68C8),
          'Summary': Tokens.textSecondary,
        };

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Tokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.table_chart_outlined, size: 14, color: Tokens.accent),
                  ),
                  const SizedBox(width: 8),
                  Text('FEE WORKSHEETS',
                      style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10, letterSpacing: 0.8)),
                  const Spacer(),
                  Text('${worksheets.length} file${worksheets.length == 1 ? '' : 's'}',
                      style: AppTheme.caption.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: worksheets.map((ws) {
                  final color = disciplineColors[ws.discipline] ?? Tokens.textSecondary;
                  return InkWell(
                    onTap: () => FolderScanService.openFile(ws.fullPath),
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    child: Tooltip(
                      message: ws.filename,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart, size: 12, color: color),
                            const SizedBox(width: 6),
                            Text(
                              ws.discipline,
                              style: AppTheme.caption.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
