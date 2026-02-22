import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../models/ca_entry.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../services/file_ops_service.dart';

/// Unified Construction Admin page used by RFIs, ASIs, COs, Submittals, Punchlists.
/// Auto-populates from folder scan with consistent columns:
///   # | Description | Assigned To | Issued By | Affected Sheets | Date | Status | Files
class CaListPage extends ConsumerStatefulWidget {
  final String title;
  final IconData icon;
  final FutureProvider<List<CaEntry>> provider;
  final String caType;

  const CaListPage({
    super.key,
    required this.title,
    required this.icon,
    required this.provider,
    required this.caType,
  });

  @override
  ConsumerState<CaListPage> createState() => _CaListPageState();
}

class _CaListPageState extends ConsumerState<CaListPage> {
  String? _statusFilter;
  String _sortColumn = 'date';
  bool _sortAsc = false;
  String _searchQuery = '';
  CaEntry? _selectedEntry;

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

  void _onFilter(String? status) {
    setState(() {
      _statusFilter = _statusFilter == status ? null : status;
    });
  }

  List<CaEntry> _applyFilters(List<CaEntry> entries) {
    var filtered = entries;

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered.where((e) => e.status == _statusFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
        e.number.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q) ||
        (e.affectedSheets?.toLowerCase().contains(q) ?? false) ||
        (e.issuedBy?.toLowerCase().contains(q) ?? false) ||
        (e.assignedTo?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // Sort
    filtered = List.of(filtered)..sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'number':
          cmp = _naturalCompare(a.number, b.number);
        case 'description':
          cmp = a.description.toLowerCase().compareTo(b.description.toLowerCase());
        case 'assignedTo':
          cmp = (a.assignedTo ?? '').compareTo(b.assignedTo ?? '');
        case 'issuedBy':
          cmp = (a.issuedBy ?? '').compareTo(b.issuedBy ?? '');
        case 'sheets':
          cmp = (a.affectedSheets ?? '').compareTo(b.affectedSheets ?? '');
        case 'date':
          cmp = (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000));
        case 'status':
          cmp = a.status.compareTo(b.status);
        case 'files':
          cmp = a.files.length.compareTo(b.files.length);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

  static int _naturalCompare(String a, String b) {
    final aNum = RegExp(r'\d+').allMatches(a).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    final bNum = RegExp(r'\d+').allMatches(b).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    for (int i = 0; i < aNum.length && i < bNum.length; i++) {
      final cmp = aNum[i].compareTo(bNum[i]);
      if (cmp != 0) return cmp;
    }
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final asyncEntries = ref.watch(widget.provider);

    return asyncEntries.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Tokens.accent)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Tokens.chipRed),
            const SizedBox(height: 12),
            Text('Error scanning folder', style: AppTheme.body.copyWith(color: Tokens.chipRed)),
            Text('$e', style: AppTheme.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
      data: (entries) => _buildContent(entries),
    );
  }

  Widget _buildContent(List<CaEntry> entries) {
    // Collect unique statuses for filter chips
    final statusCounts = <String, int>{};
    for (final e in entries) {
      statusCounts[e.status] = (statusCounts[e.status] ?? 0) + 1;
    }

    final filtered = _applyFilters(entries);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────
          _buildHeader(entries, statusCounts),
          const SizedBox(height: 12),
          // ── SEARCH BAR ──────────────────────────────────
          _buildSearchBar(),
          const SizedBox(height: Tokens.spaceMd),
          // ── TABLE ───────────────────────────────────────
          Expanded(
            flex: _selectedEntry != null ? 2 : 1,
            child: _GlassContainer(
              child: _buildTable(filtered),
            ),
          ),
          // ── DETAIL PANEL ────────────────────────────────
          if (_selectedEntry != null) ...[
            const SizedBox(height: Tokens.spaceMd),
            Expanded(
              flex: 1,
              child: _GlassContainer(
                child: _buildDetailPanel(_selectedEntry!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── HEADER with filter chips ──────────────────────────────
  Widget _buildHeader(List<CaEntry> allEntries, Map<String, int> statusCounts) {
    // Assign colors to statuses
    Color statusColor(String status) {
      return switch (status.toLowerCase()) {
        'open' => Tokens.chipYellow,
        'closed' || 'responded' || 'executed' || 'approved' || 'no exception taken' => Tokens.chipGreen,
        'pending' || 'draft' => Tokens.chipBlue,
        'issued' || 'reviewed' || 'exception taken - noted' => Tokens.accent,
        'rejected' || 'void' || 'cancelled' => Tokens.chipRed,
        'revise & resubmit' || 'make corrections noted' => Tokens.chipOrange,
        _ => Tokens.textMuted,
      };
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(widget.icon, color: Tokens.accent, size: 22),
              Text(widget.title, style: AppTheme.heading),
              const SizedBox(width: 8),
              // "All" chip
              _CountChip(
                label: 'All',
                count: allEntries.length,
                color: Tokens.accent,
                isSelected: _statusFilter == null,
                onTap: () => _onFilter(null),
              ),
              // Status chips
              for (final entry in statusCounts.entries)
                _CountChip(
                  label: _abbreviateStatus(entry.key),
                  count: entry.value,
                  color: statusColor(entry.key),
                  isSelected: _statusFilter == entry.key,
                  onTap: () => _onFilter(entry.key),
                ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, size: 18, color: Tokens.textMuted),
          tooltip: 'Rescan folder',
          onPressed: () {
            ref.read(scanRefreshProvider.notifier).state++;
            setState(() => _selectedEntry = null);
          },
        ),
      ],
    );
  }

  static String _abbreviateStatus(String status) {
    return switch (status) {
      'No Exception Taken' => 'NET',
      'Exception Taken - Noted' => 'ETN',
      'Make Corrections Noted' => 'MCN',
      'Revise & Resubmit' => 'R&R',
      'Cancelled' => 'CANC',
      _ => status,
    };
  }

  // ── SEARCH BAR ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return SizedBox(
      height: 34,
      child: TextField(
        style: AppTheme.body.copyWith(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search ${widget.title.toLowerCase()}...',
          hintStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
          prefixIcon: const Icon(Icons.search, size: 16, color: Tokens.textMuted),
          filled: true,
          fillColor: Tokens.glassFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ── TABLE ────────────────────────────────────────────────
  Widget _buildTable(List<CaEntry> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth < 800 ? 800.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      _SortHeader('#', 'number', width: 90, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('DESCRIPTION', 'description', flex: 4, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('ASSIGNED TO', 'assignedTo', flex: 2, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('ISSUED BY', 'issuedBy', flex: 2, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('AFFECTED SHEETS', 'sheets', flex: 2, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('DATE', 'date', width: 90, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('STATUS', 'status', width: 100, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                      _SortHeader('FILES', 'files', width: 50, sort: _sortColumn, asc: _sortAsc, onTap: _onSort),
                    ],
                  ),
                ),
                const Divider(color: Tokens.glassBorder, height: 1),
                // Data rows
                Expanded(
                  child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, size: 40, color: Tokens.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _statusFilter != null
                                ? 'No items match "$_statusFilter" filter.'
                                : 'No ${widget.title.toLowerCase()} found in project folder.',
                              style: AppTheme.body.copyWith(color: Tokens.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 6),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                        itemBuilder: (context, i) => _buildRow(entries[i]),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TABLE ROW ────────────────────────────────────────────
  Widget _buildRow(CaEntry entry) {
    final isSelected = _selectedEntry?.id == entry.id;
    final statusColor = _statusColor(entry.status);
    final dateStr = entry.date != null
        ? '${entry.date!.month}/${entry.date!.day}/${entry.date!.year}'
        : '\u2014';

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedEntry = isSelected ? null : entry;
          });
        },
        onDoubleTap: () {
          // Open primary PDF on double-click
          final primary = entry.files.where((f) => f.isPrimary).firstOrNull
              ?? entry.files.where((f) => f.isPdf).firstOrNull;
          if (primary != null) {
            FolderScanService.openFile(primary.fullPath);
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: isSelected ? BoxDecoration(
            color: Tokens.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
          ) : null,
          child: Row(
            children: [
              // Number
              SizedBox(
                width: 90,
                child: Text(
                  entry.number,
                  style: AppTheme.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Tokens.accent,
                  ),
                ),
              ),
              // Description
              Expanded(
                flex: 4,
                child: Text(
                  entry.description,
                  style: AppTheme.body.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              // Assigned To
              Expanded(
                flex: 2,
                child: Text(
                  entry.assignedTo ?? '\u2014',
                  style: AppTheme.caption.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Issued By
              Expanded(
                flex: 2,
                child: Text(
                  entry.issuedBy ?? '\u2014',
                  style: AppTheme.caption.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Affected Sheets
              Expanded(
                flex: 2,
                child: Text(
                  entry.affectedSheets ?? '\u2014',
                  style: AppTheme.caption.copyWith(fontSize: 10, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Date
              SizedBox(
                width: 90,
                child: Text(
                  dateStr,
                  style: AppTheme.caption.copyWith(fontSize: 10),
                ),
              ),
              // Status
              SizedBox(
                width: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  ),
                  child: Text(
                    _abbreviateStatus(entry.status),
                    style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // File count
              SizedBox(
                width: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file, size: 12, color: Tokens.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${entry.files.length}',
                      style: AppTheme.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'open' => Tokens.chipYellow,
      'closed' || 'responded' || 'executed' || 'approved' || 'no exception taken' => Tokens.chipGreen,
      'pending' || 'draft' => Tokens.chipBlue,
      'issued' || 'reviewed' || 'exception taken - noted' => Tokens.accent,
      'rejected' || 'void' || 'cancelled' => Tokens.chipRed,
      'revise & resubmit' || 'make corrections noted' || 'filed' => Tokens.chipOrange,
      _ => Tokens.textMuted,
    };
  }

  // ── DETAIL PANEL ─────────────────────────────────────────
  Widget _buildDetailPanel(CaEntry entry) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(widget.icon, size: 16, color: Tokens.accent),
              const SizedBox(width: 8),
              Text(
                '${entry.number}',
                style: AppTheme.subheading.copyWith(color: Tokens.accent, fontSize: 14),
              ),
              if (entry.description.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('\u2014', style: AppTheme.caption),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.description,
                    style: AppTheme.body.copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              // Open folder button
              IconButton(
                icon: const Icon(Icons.folder_open, size: 16, color: Tokens.accent),
                tooltip: 'Open folder',
                onPressed: () => FolderScanService.openFile(entry.folderPath),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Tokens.textMuted),
                tooltip: 'Close',
                onPressed: () => setState(() => _selectedEntry = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Tokens.glassBorder, height: 1),
          const SizedBox(height: 8),
          // File list
          Expanded(
            child: ListView.builder(
              itemCount: entry.files.length,
              itemBuilder: (context, i) {
                final f = entry.files[i];
                final iconData = f.isPdf
                    ? Icons.picture_as_pdf
                    : f.extension == '.docx' || f.extension == '.doc'
                        ? Icons.description
                        : f.extension == '.xls' || f.extension == '.xlsx'
                            ? Icons.table_chart
                            : Icons.insert_drive_file;
                final iconColor = f.isPrimary
                    ? Tokens.accent
                    : f.isPdf
                        ? Tokens.chipRed
                        : Tokens.textMuted;

                return GestureDetector(
                  onSecondaryTapDown: (details) => showFileContextMenu(context, ref, details.globalPosition, f.fullPath),
                  child: InkWell(
                  onTap: () => FolderScanService.openFile(f.fullPath),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: const Color(0x0AFFFFFF),
                  splashColor: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        // Folder icon — opens containing folder in Explorer
                        InkWell(
                          onTap: () => FolderScanService.openContainingFolder(f.fullPath),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.folder_open_outlined, size: 14, color: Tokens.textMuted),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(iconData, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.name,
                            style: AppTheme.body.copyWith(
                              fontSize: 11,
                              fontWeight: f.isPrimary ? FontWeight.w600 : FontWeight.w400,
                              color: f.isPrimary ? Tokens.textPrimary : Tokens.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (f.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Tokens.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('PRIMARY', style: AppTheme.caption.copyWith(fontSize: 8, color: Tokens.accent, fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(width: 8),
                        Text(f.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 9)),
                        const SizedBox(width: 8),
                        Text(
                          '${f.modified.month}/${f.modified.day}/${f.modified.year}',
                          style: AppTheme.caption.copyWith(fontSize: 9),
                        ),
                      ],
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
  }
}

// ═══════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════

/// Sortable column header.
class _SortHeader extends StatelessWidget {
  final String label;
  final String columnKey;
  final double? width;
  final int? flex;
  final String sort;
  final bool asc;
  final ValueChanged<String> onTap;

  const _SortHeader(
    this.label,
    this.columnKey, {
    this.width,
    this.flex,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.sidebarGroupLabel.copyWith(
              color: isActive ? Tokens.accent : Tokens.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 3),
          if (isActive)
            Icon(asc ? Icons.arrow_upward : Icons.arrow_downward, size: 11, color: Tokens.accent)
          else
            const Icon(Icons.unfold_more, size: 11, color: Tokens.textMuted),
        ],
      ),
    );

    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }
}

/// Count/filter chip.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.28) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 4),
            Text(label, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Glass-styled container without BackdropFilter.
/// BackdropFilter breaks when combined with SingleChildScrollView
/// (creates a washed-out white layer). This provides the same visual
/// appearance using an opaque dark background instead.
class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131829),
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
        border: Border.all(color: Tokens.glassBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Tokens.spaceMd),
      child: child,
    );
  }
}
