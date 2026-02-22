import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../services/file_ops_service.dart';
import 'glass_card.dart';
import 'file_drop_target.dart';

/// Reusable widget that displays scanned files from a FutureProvider.
/// Shows loading, error, empty, and file-list states.
/// Columns are sortable; default sort is date modified descending (newest first).
class ScannedFilesView extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final FutureProvider<List<ScannedFile>> provider;
  final bool showImages;
  final String? destinationFolder;

  const ScannedFilesView({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.provider,
    this.showImages = false,
    this.destinationFolder,
  });

  @override
  ConsumerState<ScannedFilesView> createState() => _ScannedFilesViewState();
}

class _ScannedFilesViewState extends ConsumerState<ScannedFilesView> {
  String _sortColumn = 'modified';
  bool _sortAsc = false; // newest first by default

  List<ScannedFile> _sorted(List<ScannedFile> files) {
    final sorted = List<ScannedFile>.from(files);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'size':
          cmp = a.sizeBytes.compareTo(b.sizeBytes);
        case 'modified':
          cmp = a.modified.compareTo(b.modified);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = column;
        _sortAsc = column == 'name'; // name defaults A→Z, others default descending
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncFiles = ref.watch(widget.provider);

    Widget content = Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(widget.icon, color: widget.accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title.toUpperCase(), style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Tokens.textMuted),
                tooltip: 'Refresh',
                onPressed: () => ref.read(scanRefreshProvider.notifier).state++,
              ),
              // File count chip
              asyncFiles.whenOrNull(
                data: (files) => _CountChip(count: files.length, color: widget.accentColor),
              ) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 4),
          // Folder path subtitle
          _FolderPathLabel(provider: widget.provider),
          const SizedBox(height: Tokens.spaceMd),
          // Content
          Expanded(
            child: asyncFiles.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Tokens.accent)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Tokens.chipRed),
                    const SizedBox(height: 12),
                    Text('Error scanning folder', style: AppTheme.subheading),
                    const SizedBox(height: 4),
                    Text('$err', style: AppTheme.caption, textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 48, color: Tokens.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No files found', style: AppTheme.subheading.copyWith(color: Tokens.textMuted)),
                        const SizedBox(height: 4),
                        Text('Files placed in this folder will appear here', style: AppTheme.caption),
                      ],
                    ),
                  );
                }
                final sortedFiles = _sorted(files);
                return GlassCard(
                  child: Column(
                    children: [
                      // Table header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const SizedBox(width: 30),
                            Expanded(flex: 5, child: _SortableHeader(label: 'FILE NAME', column: 'name', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                            SizedBox(width: 80, child: _SortableHeader(label: 'SIZE', column: 'size', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                            SizedBox(width: 100, child: _SortableHeader(label: 'MODIFIED', column: 'modified', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 4),
                          itemCount: sortedFiles.length,
                          separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                          itemBuilder: (context, i) => RepaintBoundary(
                            child: _FileRow(
                              file: sortedFiles[i],
                              accentColor: widget.accentColor,
                              ref: ref,
                            ),
                          ),
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

    if (widget.destinationFolder != null) {
      content = FileDropTarget(
        destinationRelativePath: widget.destinationFolder!,
        child: content,
      );
    }

    return content;
  }
}

/// Clickable column header with sort indicator.
class _SortableHeader extends StatelessWidget {
  final String label;
  final String column;
  final String currentColumn;
  final bool ascending;
  final void Function(String) onTap;

  const _SortableHeader({
    required this.label,
    required this.column,
    required this.currentColumn,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentColumn == column;
    return InkWell(
      onTap: () => onTap(column),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.sidebarGroupLabel.copyWith(
                color: isActive ? Tokens.accent : null,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 3),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color: Tokens.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Displays the resolved folder path for a scan provider.
class _FolderPathLabel extends ConsumerWidget {
  final FutureProvider<List<ScannedFile>> provider;
  const _FolderPathLabel({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(projectPathProvider);
    return Text(
      path,
      style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FileRow extends StatelessWidget {
  final ScannedFile file;
  final Color accentColor;
  final WidgetRef ref;
  const _FileRow({required this.file, required this.accentColor, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => showFileContextMenu(context, ref, details.globalPosition, file.fullPath),
      onDoubleTap: () => FolderScanService.openFile(file.fullPath),
      child: InkWell(
        onTap: () => FolderScanService.openFile(file.fullPath),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: accentColor.withValues(alpha: 0.06),
        splashColor: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Folder icon — opens containing folder in Explorer
              SizedBox(
                width: 30,
                child: InkWell(
                  onTap: () => FolderScanService.openContainingFolder(file.fullPath),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.folder_open_outlined, size: 16, color: Tokens.textMuted),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  file.name,
                  style: AppTheme.body.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(file.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 11)),
              ),
              SizedBox(
                width: 100,
                child: Text(_fmtDate(file.modified), style: AppTheme.caption.copyWith(fontSize: 10)),
              ),
              SizedBox(
                width: 40,
                child: Icon(Icons.open_in_new, size: 14, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final Color color;
  const _CountChip({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text('files', style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
