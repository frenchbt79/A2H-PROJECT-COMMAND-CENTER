import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../models/project_models.dart';

class ProgrammingPage extends ConsumerWidget {
  const ProgrammingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRequirementsProvider);
    final asyncFiles = ref.watch(scannedProgrammingProvider);
    final totalProg = spaces.fold(0, (s, r) => s + r.programmedSF);
    final totalDes = spaces.fold(0, (s, r) => s + r.designedSF);
    final totalVar = totalDes - totalProg;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.space_dashboard_outlined, color: Tokens.accent, size: 22),
            const SizedBox(width: 10),
            Text('PROGRAMMING', style: AppTheme.heading),
            const Spacer(),
            asyncFiles.whenOrNull(
              data: (files) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
                ),
                child: Text('${files.length} files found', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w600)),
              ),
            ) ?? const SizedBox.shrink(),
          ]),
          const SizedBox(height: Tokens.spaceMd),
          if (spaces.isNotEmpty) ...[
            _SummaryRow(totalProg: totalProg, totalDes: totalDes, totalVar: totalVar),
            const SizedBox(height: Tokens.spaceMd),
          ],
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Expanded(flex: 3, child: _GroupedFilesPanel(asyncFiles: asyncFiles)),
                      if (spaces.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _SpaceTable(spaces: spaces, totalProg: totalProg, totalDes: totalDes, totalVar: totalVar)),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 2, child: _GroupedFilesPanel(asyncFiles: asyncFiles)),
                      if (spaces.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Expanded(flex: 2, child: _SpaceTable(spaces: spaces, totalProg: totalProg, totalDes: totalDes, totalVar: totalVar)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GROUPED FILES PANEL — scanned files organized by folder
// ═══════════════════════════════════════════════════════════
class _GroupedFilesPanel extends StatelessWidget {
  final AsyncValue<List<ScannedFile>> asyncFiles;
  const _GroupedFilesPanel({required this.asyncFiles});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: Tokens.accent),
              const SizedBox(width: 6),
              Text('PROGRAMMING FILES', style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2)),
              const Spacer(),
              Text('Scanning for "program" & "planning"', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Tokens.glassBorder, height: 1),
          const SizedBox(height: 4),
          Expanded(
            child: asyncFiles.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Tokens.accent)),
              error: (err, _) => Center(
                child: Text('Error: $err', style: AppTheme.caption.copyWith(color: Tokens.chipRed)),
              ),
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 40, color: Tokens.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No programming files found', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                        const SizedBox(height: 4),
                        Text('Files with "program" or "planning" in their name will appear here', style: AppTheme.caption, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                // Group by parent folder
                final grouped = <String, List<ScannedFile>>{};
                for (final f in files) {
                  final parts = f.relativePath.split(RegExp(r'[/\\]'));
                  final folderPath = parts.length > 1
                      ? parts.sublist(0, parts.length - 1).join(' / ')
                      : 'Root';
                  grouped.putIfAbsent(folderPath, () => []).add(f);
                }
                for (final list in grouped.values) {
                  list.sort((a, b) => b.modified.compareTo(a.modified));
                }
                final folders = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: folders.length,
                  itemBuilder: (context, fi) {
                    final folder = folders[fi];
                    final folderFiles = grouped[folder]!;
                    return _FolderGroup(folderName: folder, files: folderFiles);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderGroup extends StatelessWidget {
  final String folderName;
  final List<ScannedFile> files;
  const _FolderGroup({required this.folderName, required this.files});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 13, color: Tokens.chipYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  folderName,
                  style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: Tokens.chipYellow),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Tokens.chipYellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Text('${files.length}', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.chipYellow)),
              ),
            ],
          ),
        ),
        ...files.map((f) => InkWell(
          onTap: () => FolderScanService.openFile(f.fullPath),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Icon(_fileIcon(f), size: 13, color: _fileColor(f)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f.name, style: AppTheme.body.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                Text(f.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 9)),
                const SizedBox(width: 8),
                Text('${_months[f.modified.month - 1]} ${f.modified.day}', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 10, color: Tokens.accent.withValues(alpha: 0.6)),
              ],
            ),
          ),
        )),
        const Divider(color: Tokens.glassBorder, height: 1),
      ],
    );
  }

  static IconData _fileIcon(ScannedFile f) {
    if (f.isPdf) return Icons.picture_as_pdf_outlined;
    if (f.isImage) return Icons.image_outlined;
    if (f.isDocument) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static Color _fileColor(ScannedFile f) {
    if (f.isPdf) return Tokens.chipRed;
    if (f.isImage) return Tokens.chipGreen;
    if (f.isDocument) return Tokens.chipBlue;
    return Tokens.textMuted;
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY ROW
// ═══════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════
// SPACE TABLE
// ═══════════════════════════════════════════════════════════
class _SpaceTable extends StatelessWidget {
  final List<SpaceRequirement> spaces;
  final int totalProg;
  final int totalDes;
  final int totalVar;
  const _SpaceTable({required this.spaces, required this.totalProg, required this.totalDes, required this.totalVar});

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Column(children: [
      Row(
        children: [
          const Icon(Icons.grid_on_outlined, size: 14, color: Tokens.accent),
          const SizedBox(width: 6),
          Text('SPACE REQUIREMENTS', style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.0)),
        ],
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(flex: 3, child: Text('ROOM', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 9))),
          Expanded(flex: 2, child: Text('DEPT', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 9))),
          SizedBox(width: 60, child: Text('PROG', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 9))),
          SizedBox(width: 60, child: Text('DESIGN', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 9))),
          SizedBox(width: 60, child: Text('VAR', style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 9))),
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
          return RepaintBoundary(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(flex: 3, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sp.roomName, style: AppTheme.body.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                  if (sp.notes.isNotEmpty) Text(sp.notes, style: AppTheme.caption.copyWith(fontSize: 8, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              Expanded(flex: 2, child: Text(sp.department, style: AppTheme.caption.copyWith(fontSize: 10))),
              SizedBox(width: 60, child: Text(_fmtNum(sp.programmedSF), style: AppTheme.body.copyWith(fontSize: 11), textAlign: TextAlign.right)),
              SizedBox(width: 60, child: Text(_fmtNum(sp.designedSF), style: AppTheme.body.copyWith(fontSize: 11), textAlign: TextAlign.right)),
              SizedBox(width: 60, child: Text('${v >= 0 ? "+" : ""}$v', style: AppTheme.body.copyWith(fontSize: 11, color: vc), textAlign: TextAlign.right)),
            ]),
          ));
        },
      )),
      const Divider(color: Tokens.glassBorder, height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(flex: 3, child: Text('TOTALS', style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700))),
          const Expanded(flex: 2, child: SizedBox.shrink()),
          SizedBox(width: 60, child: Text(_fmtNum(totalProg), style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          SizedBox(width: 60, child: Text(_fmtNum(totalDes), style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
          SizedBox(width: 60, child: Text(
            '${totalVar >= 0 ? "+" : ""}${_fmtNum(totalVar)}',
            style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: totalVar.abs() <= totalProg * 0.05 ? Tokens.chipGreen : Tokens.chipYellow),
            textAlign: TextAlign.right,
          )),
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
