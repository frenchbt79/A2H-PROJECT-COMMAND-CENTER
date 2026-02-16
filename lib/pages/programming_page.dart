import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

class ProgrammingPage extends ConsumerWidget {
  const ProgrammingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRequirementsProvider);
    final totalProgrammed = spaces.fold(0, (s, r) => s + r.programmedSF);
    final totalDesigned = spaces.fold(0, (s, r) => s + r.designedSF);
    final totalVariance = totalDesigned - totalProgrammed;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.space_dashboard_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('PROGRAMMING', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          _buildSummaryRow(totalProgrammed, totalDesigned, totalVariance),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(child: _buildTable(spaces, totalProgrammed, totalDesigned, totalVariance)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(int totalProgrammed, int totalDesigned, int totalVariance) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Programmed', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text('${_fmtNum(totalProgrammed)} SF', style: AppTheme.heading.copyWith(fontSize: 18, color: Tokens.accent)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Designed', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text('${_fmtNum(totalDesigned)} SF', style: AppTheme.heading.copyWith(fontSize: 18, color: Tokens.chipBlue)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Variance', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text(
                  '${totalVariance >= 0 ? "+" : ""}${_fmtNum(totalVariance)} SF',
                  style: AppTheme.heading.copyWith(
                    fontSize: 18,
                    color: totalVariance.abs() <= totalProgrammed * 0.05 ? Tokens.chipGreen : Tokens.chipYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<SpaceRequirement> spaces, int totalProgrammed, int totalDesigned, int totalVariance) {
    return GlassCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('ROOM', style: AppTheme.sidebarGroupLabel)),
                Expanded(flex: 2, child: Text('DEPARTMENT', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 80, child: Text('PROG. SF', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 80, child: Text('DESIGN SF', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 80, child: Text('VARIANCE', style: AppTheme.sidebarGroupLabel)),
                Expanded(flex: 2, child: Text('ADJACENCY', style: AppTheme.sidebarGroupLabel)),
              ],
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 4),
              itemCount: spaces.length,
              separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
              itemBuilder: (context, i) {
                final sp = spaces[i];
                final variance = sp.varianceSF;
                final varColor = variance == 0
                    ? Tokens.textSecondary
                    : variance > 0
                        ? Tokens.chipGreen
                        : Tokens.chipRed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sp.roomName, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                            if (sp.notes.isNotEmpty)
                              Text(sp.notes, style: AppTheme.caption.copyWith(fontSize: 9, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(sp.department, style: AppTheme.caption.copyWith(fontSize: 11)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(_fmtNum(sp.programmedSF), style: AppTheme.body.copyWith(fontSize: 12), textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(_fmtNum(sp.designedSF), style: AppTheme.body.copyWith(fontSize: 12), textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${variance >= 0 ? "+" : ""}$variance',
                          style: AppTheme.body.copyWith(fontSize: 12, color: varColor),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(sp.adjacency, style: AppTheme.caption.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('TOTALS', style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                SizedBox(
                  width: 80,
                  child: Text(
                    _fmtNum(totalProgrammed),
                    style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    _fmtNum(totalDesigned),
                    style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${totalVariance >= 0 ? "+" : ""}${_fmtNum(totalVariance)}',
                    style: AppTheme.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: totalVariance.abs() <= totalProgrammed * 0.05 ? Tokens.chipGreen : Tokens.chipYellow,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtNum(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-${buf.toString()}' : buf.toString();
  }
}
