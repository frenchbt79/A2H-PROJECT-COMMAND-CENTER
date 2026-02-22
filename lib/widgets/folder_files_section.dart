import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import '../services/file_ops_service.dart';
import 'file_drop_target.dart';

/// A compact section that shows scanned files from a folder.
/// Designed to be embedded inside existing pages below manual data.
/// Columns are sortable; default sort is date modified descending (newest first).
class FolderFilesSection extends ConsumerStatefulWidget {
  final String sectionTitle;
  final FutureProvider<List<ScannedFile>> provider;
  final Color accentColor;
  final String? destinationFolder;

  const FolderFilesSection({
    super.key,
    required this.sectionTitle,
    required this.provider,
    this.accentColor = Tokens.accent,
    this.destinationFolder,
  });

  @override
  ConsumerState<FolderFilesSection> createState() => _FolderFilesSectionState();
}

class _FolderFilesSectionState extends ConsumerState<FolderFilesSection> {
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
        _sortAsc = column == 'name';
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final asyncFiles = ref.watch(widget.provider);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_outlined, size: 16, color: Tokens.textMuted),
            const SizedBox(width: 6),
            Text(widget.sectionTitle, style: AppTheme.sidebarGroupLabel.copyWith(color: widget.accentColor, letterSpacing: 1.2)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 14, color: Tokens.textMuted),
              tooltip: 'Refresh',
              iconSize: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => ref.read(scanRefreshProvider.notifier).state++,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: asyncFiles.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.accent))),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: $err', style: AppTheme.caption.copyWith(color: Tokens.chipRed)),
            ),
            data: (files) {
              if (files.isEmpty) {
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('No files in project folder', style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
                  ),
                );
              }
              final sortedFiles = _sorted(files);
              return GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    // Compact header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(child: _CompactSortHeader(label: 'NAME', column: 'name', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                          SizedBox(width: 60, child: _CompactSortHeader(label: 'SIZE', column: 'size', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                          SizedBox(width: 70, child: _CompactSortHeader(label: 'DATE', column: 'modified', currentColumn: _sortColumn, ascending: _sortAsc, onTap: _onSort)),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                    const Divider(color: Tokens.glassBorder, height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: sortedFiles.length,
                        itemBuilder: (context, i) {
                          final f = sortedFiles[i];
                          return RepaintBoundary(
                            child: GestureDetector(
                              onSecondaryTapDown: (details) => showFileContextMenu(context, ref, details.globalPosition, f.fullPath),
                              onDoubleTap: () => FolderScanService.openFile(f.fullPath),
                              child: InkWell(
                                onTap: () => FolderScanService.openFile(f.fullPath),
                                mouseCursor: SystemMouseCursors.click,
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(_fileIcon(f), size: 14, color: _fileColor(f)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(f.name, style: AppTheme.body.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                                      ),
                                      SizedBox(width: 60, child: Text(f.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 9))),
                                      SizedBox(width: 70, child: Text(_fmtDate(f.modified), style: AppTheme.caption.copyWith(fontSize: 9))),
                                      Icon(Icons.open_in_new, size: 11, color: widget.accentColor),
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
              );
            },
          ),
        ),
      ],
    );

    if (widget.destinationFolder != null) {
      content = FileDropTarget(
        destinationRelativePath: widget.destinationFolder!,
        child: content,
      );
    }

    return content;
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  static IconData _fileIcon(ScannedFile f) {
    if (f.isPdf) return Icons.picture_as_pdf_outlined;
    if (f.isImage) return Icons.image_outlined;
    if (f.isDocument) return Icons.description_outlined;
    if (f.isVideo) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  static Color _fileColor(ScannedFile f) {
    if (f.isPdf) return Tokens.chipRed;
    if (f.isImage) return Tokens.chipGreen;
    if (f.isDocument) return Tokens.chipBlue;
    if (f.isVideo) return Tokens.chipYellow;
    return Tokens.textMuted;
  }
}

/// Compact sortable column header for the embedded section.
class _CompactSortHeader extends StatelessWidget {
  final String label;
  final String column;
  final String currentColumn;
  final bool ascending;
  final void Function(String) onTap;

  const _CompactSortHeader({
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.sidebarGroupLabel.copyWith(
              fontSize: 9,
              color: isActive ? Tokens.accent : Tokens.textMuted,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 2),
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 9,
              color: Tokens.accent,
            ),
          ],
        ],
      ),
    );
  }
}
