import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../models/drawing_metadata.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/file_ops_service.dart';
import '../state/nav_state.dart';

/// Serves discipline routes: General, Structural, Architectural, Civil,
/// Landscape, Mechanical, Electrical, Plumbing.
class DisciplinePage extends ConsumerStatefulWidget {
  final String disciplineName;
  final IconData icon;
  final Color accentColor;
  final bool showHeader;

  const DisciplinePage({
    super.key,
    required this.disciplineName,
    required this.icon,
    required this.accentColor,
    this.showHeader = true,
  });

  @override
  ConsumerState<DisciplinePage> createState() => _DisciplinePageState();
}

class _DisciplinePageState extends ConsumerState<DisciplinePage> {
  String _filter = '';
  String _sortColumn = 'sheet';
  bool _sortAsc = true;

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = column;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metaProvider = disciplineMetaProviders[widget.disciplineName];
    if (metaProvider == null) {
      return Center(
        child: Text('Unknown discipline: ${widget.disciplineName}',
            style: AppTheme.subheading),
      );
    }

    final filesAsync = ref.watch(metaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.only(
              left: Tokens.spaceLg,
              right: Tokens.spaceLg,
              top: Tokens.spaceLg,
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.accentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.disciplineName.toUpperCase(),
                  style: AppTheme.heading,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        if (widget.showHeader) const SizedBox(height: 4),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.spaceLg),
            child: filesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Tokens.accent)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 40, color: Tokens.chipRed),
                    const SizedBox(height: 12),
                    Text('Error loading files', style: AppTheme.subheading),
                    const SizedBox(height: 4),
                    Text('$err',
                        style: AppTheme.caption,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (metas) => _buildFileList(metas),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(List<DrawingMetadata> metas) {
    if (metas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open,
                size: 48,
                color: Tokens.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No ${widget.disciplineName} drawings found',
                style:
                    AppTheme.subheading.copyWith(color: Tokens.textMuted)),
            const SizedBox(height: 4),
            Text(
              'Scanned drawing files will appear here',
              style: AppTheme.caption,
            ),
          ],
        ),
      );
    }

    // Group by sheet number prefix (e.g. G0, G1, A1, etc.)
    final grouped = <String, List<DrawingMetadata>>{};
    for (final m in metas) {
      final sn = m.sheetNumber;
      final prefix = sn.length >= 2 ? sn.substring(0, 2).toUpperCase() : 'Other';
      (grouped[prefix] ??= []).add(m);
    }

    // Filter
    var filtered = _filter.isEmpty
        ? List<DrawingMetadata>.from(metas)
        : metas
            .where((m) =>
                m.file.name.toLowerCase().contains(_filter.toLowerCase()) ||
                m.sheetNumber.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    // Sort
    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'sheet':
          cmp = a.sheetNumber.compareTo(b.sheetNumber);
        case 'name':
          cmp = a.file.name.toLowerCase().compareTo(b.file.name.toLowerCase());
        case 'rfi':
          cmp = a.rfiCount.compareTo(b.rfiCount);
        case 'asi':
          cmp = a.asiCount.compareTo(b.asiCount);
        case 'add':
          cmp = a.addendumCount.compareTo(b.addendumCount);
        case 'size':
          cmp = a.file.sizeBytes.compareTo(b.file.sizeBytes);
        case 'modified':
          cmp = a.file.modified.compareTo(b.file.modified);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats + search
        Row(
          children: [
            _StatChip(
                label: '${metas.length} sheets',
                color: widget.accentColor),
            const SizedBox(width: 8),
            _StatChip(
                label: '${grouped.length} groups',
                color: Tokens.textMuted),
            const SizedBox(width: 8),
            if (metas.any((m) => m.rfiCount > 0))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatChip(
                    label: '${metas.fold<int>(0, (s, m) => s + m.rfiCount)} RFIs',
                    color: Tokens.chipYellow,
                    onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.rfis)),
              ),
            if (metas.any((m) => m.asiCount > 0))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatChip(
                    label: '${metas.fold<int>(0, (s, m) => s + m.asiCount)} ASIs',
                    color: Tokens.chipBlue,
                    onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.asis)),
              ),
            if (metas.any((m) => m.addendumCount > 0))
              _StatChip(
                  label: '${metas.fold<int>(0, (s, m) => s + m.addendumCount)} ADDs',
                  color: Tokens.chipIndigo,
                  onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.changeOrders)),
            const Spacer(),
            // Search
            SizedBox(
              width: 200,
              height: 32,
              child: TextField(
                onChanged: (v) => setState(() => _filter = v),
                style: AppTheme.body.copyWith(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filter drawings...',
                  hintStyle: AppTheme.caption
                      .copyWith(fontSize: 11, color: Tokens.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Tokens.textMuted),
                  filled: true,
                  fillColor: Tokens.bgDark,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide:
                        const BorderSide(color: Tokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide:
                        const BorderSide(color: Tokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.accent),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        // Table
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                // Sortable header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 36),
                      _SortHeader('SHEET', 'sheet', width: 80,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('FILE NAME', 'name', flex: 4,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('RFI', 'rfi', width: 56, center: true,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('ASI', 'asi', width: 56, center: true,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('ADD', 'add', width: 56, center: true,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('SIZE', 'size', width: 70,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('MODIFIED', 'modified', width: 90,
                          sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
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
                      final meta = filtered[i];
                      final file = meta.file;
                      final sheetNum = meta.sheetNumber;

                      return RepaintBoundary(
                        child: GestureDetector(
                          onSecondaryTapDown: (details) =>
                              showFileContextMenu(context, ref,
                                  details.globalPosition, file.fullPath),
                          child: InkWell(
                            onTap: () =>
                                FolderScanService.openFile(file.fullPath),
                            mouseCursor: SystemMouseCursors.click,
                            hoverColor: const Color(0x0AFFFFFF),
                            splashColor: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  // Folder icon
                                  SizedBox(
                                    width: 36,
                                    child: InkWell(
                                      onTap: () => FolderScanService
                                          .openContainingFolder(
                                              file.fullPath),
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
                                  // Sheet number
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      sheetNum.isNotEmpty
                                          ? sheetNum.toUpperCase()
                                          : '—',
                                      style: AppTheme.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.accentColor,
                                      ),
                                    ),
                                  ),
                                  // File name
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      file.name,
                                      style: AppTheme.body
                                          .copyWith(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // RFI — show actual number from folder
                                  SizedBox(
                                    width: 56,
                                    child: Center(
                                      child: meta.rfiCount > 0
                                          ? _DocBadge(
                                              label: meta.latestRfiLabel.isNotEmpty
                                                  ? meta.latestRfiLabel
                                                  : '${meta.rfiCount}',
                                              color: Tokens.chipYellow,
                                              tooltip: meta.rfiCount > 1
                                                  ? '${meta.rfiCount} RFIs — click to view'
                                                  : meta.latestRfiLabel,
                                              onTap: () => _showCrossRefPopup(
                                                  context, ref, meta.sheetKey,
                                                  'RFI', Tokens.chipYellow,
                                                  rfiBySheetProvider))
                                          : _emptyDash,
                                    ),
                                  ),
                                  // ASI — show actual number from folder
                                  SizedBox(
                                    width: 56,
                                    child: Center(
                                      child: meta.asiCount > 0
                                          ? _DocBadge(
                                              label: meta.latestAsiLabel.isNotEmpty
                                                  ? meta.latestAsiLabel
                                                  : '${meta.asiCount}',
                                              color: Tokens.chipBlue,
                                              tooltip: meta.asiCount > 1
                                                  ? '${meta.asiCount} ASIs — click to view'
                                                  : meta.latestAsiLabel,
                                              onTap: () => _showCrossRefPopup(
                                                  context, ref, meta.sheetKey,
                                                  'ASI', Tokens.chipBlue,
                                                  asiBySheetProvider))
                                          : _emptyDash,
                                    ),
                                  ),
                                  // Addendum — show actual number from folder
                                  SizedBox(
                                    width: 56,
                                    child: Center(
                                      child: meta.addendumCount > 0
                                          ? _DocBadge(
                                              label: meta.latestAddLabel.isNotEmpty
                                                  ? meta.latestAddLabel
                                                  : '${meta.addendumCount}',
                                              color: Tokens.chipIndigo,
                                              tooltip: meta.addendumCount > 1
                                                  ? '${meta.addendumCount} ADDs — click to view'
                                                  : meta.latestAddLabel,
                                              onTap: () => _showCrossRefPopup(
                                                  context, ref, meta.sheetKey,
                                                  'Addendum', Tokens.chipIndigo,
                                                  addendumBySheetProvider))
                                          : _emptyDash,
                                    ),
                                  ),
                                  // Size
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      file.sizeLabel,
                                      style: AppTheme.caption
                                          .copyWith(fontSize: 11),
                                    ),
                                  ),
                                  // Modified
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      _fmtDate(file.modified),
                                      style: AppTheme.caption
                                          .copyWith(fontSize: 10),
                                    ),
                                  ),
                                  // Open icon
                                  SizedBox(
                                    width: 40,
                                    child: Icon(Icons.open_in_new,
                                        size: 14,
                                        color: widget.accentColor),
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

  static final _emptyDash = Text('—',
      style: AppTheme.caption
          .copyWith(fontSize: 10, color: Tokens.textMuted.withValues(alpha: 0.3)));

  /// Show popup listing all cross-referenced files (RFI/ASI/ADD) for a sheet.
  void _showCrossRefPopup(
    BuildContext context,
    WidgetRef ref,
    String sheetKey,
    String label,
    Color color,
    FutureProvider<Map<String, List<ScannedFile>>> provider,
  ) {
    final mapAsync = ref.read(provider);
    final map = mapAsync.valueOrNull ?? {};
    final files = map[sheetKey] ?? [];
    if (files.isEmpty) return;

    // Sort newest first
    final sorted = List<ScannedFile>.from(files)
      ..sort((a, b) => b.modified.compareTo(a.modified));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(label,
                          style: AppTheme.caption.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                    ),
                    const SizedBox(width: 8),
                    Text('${sheetKey.toUpperCase()} — ${sorted.length} file${sorted.length == 1 ? '' : 's'}',
                        style: AppTheme.subheading.copyWith(fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Tokens.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Tokens.glassBorder, height: 1),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Tokens.glassBorder, height: 1),
                    itemBuilder: (_, i) {
                      final f = sorted[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.picture_as_pdf, size: 18, color: color),
                        title: Text(f.name,
                            style: AppTheme.body.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${f.sizeLabel}  •  ${_fmtDate(f.modified)}',
                            style: AppTheme.caption.copyWith(fontSize: 9)),
                        trailing: Icon(Icons.open_in_new, size: 14, color: color),
                        onTap: () {
                          FolderScanService.openFile(f.fullPath);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Document Badge (shows actual RFI/ASI/ADD number from folder) ──
class _DocBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  const _DocBadge(
      {required this.label, required this.color, this.tooltip = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: AppTheme.caption.copyWith(
                fontSize: 9, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    if (tooltip.isEmpty) return badge;
    return Tooltip(message: tooltip, child: badge);
  }
}

// ── Sortable Column Header ────────────────────────────────
class _SortHeader extends StatelessWidget {
  final String title;
  final String columnKey;
  final double? width;
  final int? flex;
  final bool center;
  final String sort;
  final bool asc;
  final ValueChanged<String> onTap;

  const _SortHeader(
    this.title,
    this.columnKey, {
    this.width,
    this.flex,
    this.center = false,
    required this.sort,
    required this.asc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sort == columnKey;
    final child = GestureDetector(
      onTap: () => onTap(columnKey),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              center ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.sidebarGroupLabel.copyWith(
                color: isActive ? Tokens.accent : null,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              Icon(
                asc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: Tokens.accent,
              ),
            ],
          ],
        ),
      ),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }
}

// ── Stat Chip ──────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _StatChip({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
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
    if (onTap == null) return chip;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}
