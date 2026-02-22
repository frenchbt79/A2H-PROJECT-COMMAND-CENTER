import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../services/sheet_name_parser.dart';
import '../services/file_ops_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CloseoutDocumentsPage extends ConsumerStatefulWidget {
  const CloseoutDocumentsPage({super.key});

  @override
  ConsumerState<CloseoutDocumentsPage> createState() =>
      _CloseoutDocumentsPageState();
}

class _CloseoutDocumentsPageState extends ConsumerState<CloseoutDocumentsPage> {
  String _filter = '';
  final Set<int> _unchecked = {};
  bool _merging = false;

  /// Collect all latest-per-sheet files from the cached closeout provider.
  List<ScannedFile>? _collectAllSheets() {
    final asyncValue = ref.watch(closeoutDocumentsProvider);
    return asyncValue.valueOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final allFiles = _collectAllSheets();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: allFiles == null
          ? const Center(
              child: CircularProgressIndicator(color: Tokens.accent))
          : _buildContent(allFiles),
    );
  }

  Widget _buildContent(List<ScannedFile> allFiles) {
    if (allFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt,
                size: 48, color: Tokens.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No drawings found',
                style: AppTheme.subheading.copyWith(color: Tokens.textMuted)),
            const SizedBox(height: 4),
            Text(
              'Scanned drawings from all disciplines will appear here',
              style: AppTheme.caption,
            ),
          ],
        ),
      );
    }

    // Apply text filter
    final filtered = _filter.isEmpty
        ? allFiles
        : allFiles.where((f) {
            final info = SheetNameParser.parse(f.name);
            return f.name.toLowerCase().contains(_filter.toLowerCase()) ||
                info.sheetNumber.toLowerCase().contains(_filter.toLowerCase());
          }).toList();

    // Count selected (checked) files
    final selectedCount =
        allFiles.where((f) => !_unchecked.contains(allFiles.indexOf(f))).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.assignment_turned_in,
                size: 20, color: Tokens.accent),
            const SizedBox(width: 8),
            Text('CLOSEOUT DOCUMENTS',
                style: AppTheme.subheading.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(width: 16),
            _StatChip(
                label: '${allFiles.length} sheets', color: Tokens.chipGreen),
            const SizedBox(width: 6),
            _StatChip(
                label: '$selectedCount selected', color: Tokens.accent),
            const Spacer(),
            // Filter
            SizedBox(
              width: 200,
              height: 32,
              child: TextField(
                onChanged: (v) => setState(() => _filter = v),
                style: AppTheme.body.copyWith(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filter sheets...',
                  hintStyle: AppTheme.caption
                      .copyWith(fontSize: 11, color: Tokens.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Tokens.textMuted),
                  filled: true,
                  fillColor: Tokens.bgDark,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _MergeButton(
              enabled: selectedCount > 0 && !_merging,
              merging: _merging,
              onPressed: () => _mergeSelected(allFiles),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Most recent drawing per sheet from all disciplines — ordered by G0.01 index',
          style:
              AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
        ),
        const SizedBox(height: Tokens.spaceMd),
        // Select all / deselect all
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _unchecked.clear()),
              icon:
                  const Icon(Icons.check_box, size: 14, color: Tokens.accent),
              label: Text('Select All',
                  style: AppTheme.caption
                      .copyWith(fontSize: 10, color: Tokens.accent)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                for (int i = 0; i < allFiles.length; i++) {
                  _unchecked.add(i);
                }
              }),
              icon: const Icon(Icons.check_box_outline_blank,
                  size: 14, color: Tokens.textMuted),
              label: Text('Deselect All',
                  style: AppTheme.caption
                      .copyWith(fontSize: 10, color: Tokens.textMuted)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Table
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 40), // checkbox
                      const SizedBox(width: 36), // folder icon
                      SizedBox(
                          width: 44,
                          child:
                              Text('#', style: AppTheme.sidebarGroupLabel)),
                      SizedBox(
                          width: 80,
                          child: Text('SHEET',
                              style: AppTheme.sidebarGroupLabel)),
                      SizedBox(
                          width: 80,
                          child: Text('DISCIPLINE',
                              style: AppTheme.sidebarGroupLabel)),
                      Expanded(
                          flex: 4,
                          child: Text('FILE NAME',
                              style: AppTheme.sidebarGroupLabel)),
                      SizedBox(
                          width: 80,
                          child: Text('SIZE',
                              style: AppTheme.sidebarGroupLabel)),
                      SizedBox(
                          width: 100,
                          child: Text('MODIFIED',
                              style: AppTheme.sidebarGroupLabel)),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(color: Tokens.glassBorder, height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Tokens.glassBorder, height: 1),
                    itemBuilder: (context, i) {
                      final f = filtered[i];
                      final info = SheetNameParser.parse(f.name);
                      final origIdx = allFiles.indexOf(f);
                      final isChecked = !_unchecked.contains(origIdx);

                      // Map prefix to discipline label
                      final disciplineLabel =
                          _prefixToDiscipline(info.prefix);

                      return RepaintBoundary(
                        child: GestureDetector(
                          onSecondaryTapDown: (details) =>
                              showFileContextMenu(context, ref,
                                  details.globalPosition, f.fullPath),
                          child: InkWell(
                            onTap: () =>
                                FolderScanService.openFile(f.fullPath),
                            mouseCursor: SystemMouseCursors.click,
                            hoverColor: const Color(0x0AFFFFFF),
                            splashColor: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  // Checkbox
                                  SizedBox(
                                    width: 40,
                                    child: Checkbox(
                                      value: isChecked,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _unchecked.remove(origIdx);
                                          } else {
                                            _unchecked.add(origIdx);
                                          }
                                        });
                                      },
                                      activeColor: Tokens.accent,
                                      side: const BorderSide(
                                          color: Tokens.textMuted,
                                          width: 1.5),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  // Folder icon
                                  SizedBox(
                                    width: 36,
                                    child: InkWell(
                                      onTap: () => FolderScanService
                                          .openContainingFolder(f.fullPath),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                            Icons.folder_open_outlined,
                                            size: 16,
                                            color: Tokens.textMuted),
                                      ),
                                    ),
                                  ),
                                  // Row number
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '${i + 1}',
                                      style: AppTheme.caption.copyWith(
                                          fontSize: 10,
                                          color: Tokens.textMuted),
                                    ),
                                  ),
                                  // Sheet number from parser
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      info.valid
                                          ? info.sheetNumber
                                          : '—',
                                      style: AppTheme.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: info.valid
                                            ? const Color(0xFFEF5350)
                                            : Tokens.textMuted,
                                      ),
                                    ),
                                  ),
                                  // Discipline
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      disciplineLabel,
                                      style: AppTheme.caption.copyWith(
                                          fontSize: 10,
                                          color: Tokens.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // File name
                                  Expanded(
                                    flex: 4,
                                    child: Text(f.name,
                                        style: AppTheme.body
                                            .copyWith(fontSize: 12),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  // Size
                                  SizedBox(
                                    width: 80,
                                    child: Text(f.sizeLabel,
                                        style: AppTheme.caption
                                            .copyWith(fontSize: 11)),
                                  ),
                                  // Modified
                                  SizedBox(
                                    width: 100,
                                    child: Text(_fmtDate(f.modified),
                                        style: AppTheme.caption
                                            .copyWith(fontSize: 10)),
                                  ),
                                  // Open icon
                                  SizedBox(
                                    width: 40,
                                    child: Icon(Icons.open_in_new,
                                        size: 14,
                                        color: const Color(0xFFEF5350)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _mergeSelected(List<ScannedFile> allFiles) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluebeam stapling is not available on Web.'),
          backgroundColor: Tokens.chipRed,
        ),
      );
      return;
    }

    final projectPath = ref.read(projectPathProvider);
    final project = ref.read(activeProjectProvider);
    if (projectPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No project path set.'),
          backgroundColor: Tokens.chipRed,
        ),
      );
      return;
    }

    // Collect checked file paths in order
    final inputPaths = <String>[];
    for (int i = 0; i < allFiles.length; i++) {
      if (!_unchecked.contains(i)) {
        inputPaths.add(allFiles[i].fullPath);
      }
    }

    if (inputPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No files selected.'),
          backgroundColor: Tokens.chipRed,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final projectNumber = project?.number ?? 'PROJECT';
    final outputName = '$projectNumber - CLOSEOUT SET - $dateStr.pdf';

    // Create CLOSEOUT directory if needed
    final closeoutDir = Directory('$projectPath\\CLOSEOUT');
    if (!closeoutDir.existsSync()) {
      closeoutDir.createSync(recursive: true);
    }
    final outputPath = '${closeoutDir.path}\\$outputName';

    setState(() => _merging = true);

    // ── Launch Bluebeam Stapler.exe ──
    // Bluebeam Revu 20 Stapler staples PDFs into a single file.
    // Syntax: Stapler.exe "output.pdf" "input1.pdf" "input2.pdf" ...
    const staplerPath = r'C:\Program Files\Bluebeam Software\Bluebeam Revu\20\Revu\Stapler.exe';
    const revuPath = r'C:\Program Files\Bluebeam Software\Bluebeam Revu\20\Revu\Revu.exe';

    // Check Bluebeam is installed
    if (!File(staplerPath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluebeam Stapler not found. Is Bluebeam Revu 20 installed?'),
            backgroundColor: Tokens.chipRed,
            duration: Duration(seconds: 6),
          ),
        );
        setState(() => _merging = false);
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Opening Bluebeam Stapler — ${inputPaths.length} sheets...'),
            ),
          ],
        ),
        backgroundColor: Tokens.accent,
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      // Run Stapler.exe: first arg is output, rest are inputs
      final args = [outputPath, ...inputPaths];
      final result = await Process.run(staplerPath, args);

      if (!mounted) return;

      if (result.exitCode == 0 && File(outputPath).existsSync()) {
        // Open the merged PDF in Bluebeam Revu
        if (File(revuPath).existsSync()) {
          await Process.start(revuPath, [outputPath]);
        } else {
          // Fallback: open with system default
          FolderScanService.openFile(outputPath);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Closeout set created — ${inputPaths.length} sheets stapled in Bluebeam'),
                ),
              ],
            ),
            backgroundColor: Tokens.chipGreen,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () => FolderScanService.openContainingFolder(outputPath),
            ),
          ),
        );
      } else {
        // Stapler might not support command-line args — fall back to opening
        // all files directly in Revu so user can staple manually.
        if (File(revuPath).existsSync()) {
          await Process.start(revuPath, inputPaths);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Opened ${inputPaths.length} PDFs in Bluebeam — use File > Staple to combine'),
              backgroundColor: Tokens.accent,
              duration: const Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stapler error (exit ${result.exitCode}): ${result.stderr}'),
              backgroundColor: Tokens.chipRed,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching Bluebeam: $e'),
          backgroundColor: Tokens.chipRed,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  static String _prefixToDiscipline(String prefix) {
    switch (prefix.toUpperCase()) {
      case 'G':
        return 'General';
      case 'A':
        return 'Arch';
      case 'S':
        return 'Struct';
      case 'C':
        return 'Civil';
      case 'L':
        return 'Landscape';
      case 'M':
        return 'Mech';
      case 'E':
        return 'Elec';
      case 'P':
        return 'Plumbing';
      case 'FP':
        return 'Fire Prot';
      default:
        return prefix;
    }
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Merge button ─────────────────────────────────────────────
class _MergeButton extends StatelessWidget {
  final bool enabled;
  final bool merging;
  final VoidCallback onPressed;

  const _MergeButton({
    required this.enabled,
    required this.merging,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: merging
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.merge_type, size: 16),
      label: Text(merging ? 'Merging...' : 'Make Current Set',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? Tokens.accent : Tokens.bgDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Tokens.bgDark,
        disabledForegroundColor: Tokens.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
        ),
      ),
    );
  }
}

// ── Stat chip ────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTheme.caption.copyWith(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
