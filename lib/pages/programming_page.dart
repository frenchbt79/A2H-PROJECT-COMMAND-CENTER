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
    final totalProg = spaces.fold(0, (s, r) => s + r.programmedSF);
    final totalDes = spaces.fold(0, (s, r) => s + r.designedSF);
    final totalVar = totalDes - totalProg;
    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.space_dashboard_outlined, color: Tokens.accent, size: 22),
            const SizedBox(width: 10),
            Text('PROGRAMMING', style: AppTheme.heading),
          ]),
          const SizedBox(height: Tokens.spaceMd),
          _SummaryRow(totalProg: totalProg, totalDes: totalDes, totalVar: totalVar),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(child: _SpaceTable(spaces: spaces, totalProg: totalProg, totalDes: totalDes, totalVar: totalVar)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalProg;
  final int totalDes;
  final int totalVar;
  const _SummaryRow({required this.totalProg, required this.totalDes, required this.totalVar});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Programmed', style: AppTheme.caption),
          const SizedBox(height: 4),
          Text('${_fmtNum(totalProg)} SF', style: AppTheme.heading.copyWith(fontSize: 18, color: Tokens.accent)),
        ]),
      )),
      const SizedBox(width: 12),
      Expanded(child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Designed', style: AppTheme.caption),
          const SizedBox(height: 4),
          Text('${_fmtNum(totalDes)} SF', style: AppTheme.heading.copyWith(fontSize: 18, color: Tokens.chipBlue)),
        ]),
      )),
      const SizedBox(width: 12),
      Expanded(child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Variance', style: AppTheme.caption),
          const SizedBox(height: 4),
          Text(
            '${totalVar >= 0 ? "+" : ""}${_fmtNum(totalVar)} SF',
            style: AppTheme.heading.copyWith(fontSize: 18, color: totalVar.abs() <= totalProg * 0.05 ? Tokens.chipGreen : Tokens.chipYellow),
          ),
        ]),
      )),
    ]);
  }
}

class _SpaceTable extends StatelessWidget {
  final List<SpaceRequirement> spaces;
  final int totalProg;
  final int totalDes;
  final int totalVar;
  const _SpaceTable({required this.spaces, required this.totalProg, required this.totalDes, required this.totalVar});

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(flex: 3, child: Text('ROOM', style: AppTheme.sidebarGroupLabel)),
          Expanded(flex: 2, child: Text('DEPARTMENT', style: AppTheme.sidebarGroupLabel)),
          SizedBox(width: 80, child: Text('PROG. SF', style: AppTheme.sidebarGroupLabel)),
          SizedBox(width: 80, child: Text('DESIGN SF', style: AppTheme.sidebarGroupLabel)),
          SizedBox(width: 80, child: Text('VARIANCE', style: AppTheme.sidebarGroupLabel)),
          Expanded(flex: 2, child: Text('ADJACENCY', style: AppTheme.sidebarGroupLabel)),
        ]),
      ),
      const Divider(color: Tokens.glassBorder, height: 1),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.only(top: 4),
        itemCount: spaces.length,
        separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
        itemBuilder: (context, i) {
          final sp = spaces[i];
          final v = sp.varianceSF;
          final vc = v == 0 ? Tokens.textSecondary : v > 0 ? Tokens.chipGreen : Tokens.chipRed;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sp.roomName, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                  if (sp.notes.isNotEmpty) Text(sp.notes, style: AppTheme.caption.copyWith(fontSize: 9, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              Expanded(flex: 2, child: Text(sp.department, style: AppTheme.caption.copyWith(fontSize: 11))),
              SizedBox(width: 80, child: Text(_fmtNum(sp.programmedSF), style: AppTheme.body.copyWith(fontSize: 12), textAlign: TextAlign.right)),
              SizedBox(width: 80, child: Text(_fmtNum(sp.designedSF), style: AppTheme.body.copyWith(fontSize: 12), textAlign: TextAlign.right)),
              SizedBox(width: 80, child: Text('${v >= 0 ? "+" : ""}$v', style: AppTheme.body.copyWith(fontSize: 12, color: vc), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(sp.adjacency, style: AppTheme.caption.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
              )),
            ]),
          );
        },
      )),
      const Divider(color: Tokens.glassBorder, height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(flex: 3, child: Text('TOTALS', style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700))),
          const Expanded(flex: 2, child: SizedBox.shrink()),
          SizedBox(width: 80, child: Text(_fmtNum(totalProg), style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text(_fmtNum(totalDes), style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          SizedBox(width: 80, child: Text(
            '${totalVar >= 0 ? "+" : ""}${_fmtNum(totalVar)}',
            style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: totalVar.abs() <= totalProg * 0.05 ? Tokens.chipGreen : Tokens.chipYellow),
            textAlign: TextAlign.right,
          )),
          const Expanded(flex: 2, child: SizedBox.shrink()),
        ]),
      ),
    ]));
  }
}

String _fmtNum(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-${buf.toString()}' : buf.toString();
}
