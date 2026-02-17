import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../widgets/crud_dialogs.dart';

class RfiPage extends ConsumerStatefulWidget {
  const RfiPage({super.key});

  @override
  ConsumerState<RfiPage> createState() => _RfiPageState();
}

class _RfiPageState extends ConsumerState<RfiPage> {
  String? _statusFilter; // null = "All"
  String _sortColumn = 'number';
  bool _sortAsc = true;

  void _onFilterTap(String? status) {
    setState(() {
      _statusFilter = _statusFilter == status ? null : status;
    });
  }

  void _onSortTap(String column) {
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
    final rfis = ref.watch(rfisProvider);
    final open = rfis.where((r) => r.status == 'Open').length;
    final pending = rfis.where((r) => r.status == 'Pending').length;
    final closed = rfis.where((r) => r.status == 'Closed').length;

    // Apply filter
    final filtered = _statusFilter == null
        ? rfis
        : rfis.where((r) => r.status == _statusFilter).toList();

    // Apply sort
    final sorted = List.of(filtered)
      ..sort((a, b) {
        int cmp;
        switch (_sortColumn) {
          case 'number':
            cmp = a.number.compareTo(b.number);
          case 'subject':
            cmp = a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
          case 'assignee':
            cmp = (a.assignee ?? '').toLowerCase().compareTo((b.assignee ?? '').toLowerCase());
          case 'opened':
            cmp = a.dateOpened.compareTo(b.dateOpened);
          case 'status':
            cmp = a.status.compareTo(b.status);
          default:
            cmp = 0;
        }
        return _sortAsc ? cmp : -cmp;
      });

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('RFIs', style: AppTheme.heading),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Tokens.accent),
                tooltip: 'New RFI',
                onPressed: () => showRfiDialog(context, ref),
              ),
              _CountChip(
                label: 'All',
                count: rfis.length,
                color: Tokens.accent,
                isSelected: _statusFilter == null,
                onTap: () => _onFilterTap(null),
              ),
              _CountChip(
                label: 'Open',
                count: open,
                color: Tokens.chipYellow,
                isSelected: _statusFilter == 'Open',
                onTap: () => _onFilterTap('Open'),
              ),
              _CountChip(
                label: 'Pending',
                count: pending,
                color: Tokens.chipBlue,
                isSelected: _statusFilter == 'Pending',
                onTap: () => _onFilterTap('Pending'),
              ),
              _CountChip(
                label: 'Closed',
                count: closed,
                color: Tokens.chipGreen,
                isSelected: _statusFilter == 'Closed',
                onTap: () => _onFilterTap('Closed'),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: GlassCard(
              child: LayoutBuilder(
                builder: (context, outerConstraints) {
                  final minTableWidth = outerConstraints.maxWidth < 600 ? 600.0 : outerConstraints.maxWidth;
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
                                _SortableHeader(
                                  label: 'RFI #',
                                  columnKey: 'number',
                                  width: 80,
                                  currentSort: _sortColumn,
                                  ascending: _sortAsc,
                                  onTap: _onSortTap,
                                ),
                                _SortableHeader(
                                  label: 'SUBJECT',
                                  columnKey: 'subject',
                                  flex: 4,
                                  currentSort: _sortColumn,
                                  ascending: _sortAsc,
                                  onTap: _onSortTap,
                                ),
                                _SortableHeader(
                                  label: 'ASSIGNEE',
                                  columnKey: 'assignee',
                                  flex: 2,
                                  currentSort: _sortColumn,
                                  ascending: _sortAsc,
                                  onTap: _onSortTap,
                                ),
                                _SortableHeader(
                                  label: 'OPENED',
                                  columnKey: 'opened',
                                  width: 90,
                                  currentSort: _sortColumn,
                                  ascending: _sortAsc,
                                  onTap: _onSortTap,
                                ),
                                _SortableHeader(
                                  label: 'STATUS',
                                  columnKey: 'status',
                                  width: 70,
                                  currentSort: _sortColumn,
                                  ascending: _sortAsc,
                                  onTap: _onSortTap,
                                ),
                                const SizedBox(width: 50),
                              ],
                            ),
                          ),
                          const Divider(color: Tokens.glassBorder, height: 1),
                          Expanded(
                            child: sorted.isEmpty
                                ? Center(
                                    child: Text(
                                      'No RFIs match the current filter.',
                                      style: AppTheme.caption.copyWith(color: Tokens.textMuted),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(top: 8),
                                    itemCount: sorted.length,
                                    separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                                    itemBuilder: (context, i) {
                                      final rfi = sorted[i];
                                      final statusColor = switch (rfi.status) {
                                        'Open' => Tokens.chipYellow,
                                        'Pending' => Tokens.chipBlue,
                                        _ => Tokens.chipGreen,
                                      };
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: Text(rfi.number, style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Tokens.accent)),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Text(rfi.subject, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(rfi.assignee ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                                            ),
                                            SizedBox(
                                              width: 90,
                                              child: Text(
                                                '${rfi.dateOpened.month}/${rfi.dateOpened.day}/${rfi.dateOpened.year}',
                                                style: AppTheme.caption.copyWith(fontSize: 10),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                                ),
                                                child: Text(rfi.status, style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor), textAlign: TextAlign.center),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => showRfiDialog(context, ref, existing: rfi),
                                                    child: const Icon(Icons.edit_outlined, size: 14, color: Tokens.textMuted),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final confirmed = await showDeleteConfirmation(context, rfi.number);
                                                      if (confirmed) ref.read(rfisProvider.notifier).remove(rfi.id);
                                                    },
                                                    child: const Icon(Icons.delete_outline, size: 14, color: Tokens.textMuted),
                                                  ),
                                                ],
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
}

// ── Sortable Column Header ────────────────────────────────────
class _SortableHeader extends StatelessWidget {
  final String label;
  final String columnKey;
  final double? width;
  final int? flex;
  final String currentSort;
  final bool ascending;
  final ValueChanged<String> onTap;

  const _SortableHeader({
    required this.label,
    required this.columnKey,
    this.width,
    this.flex,
    required this.currentSort,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == columnKey;
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
            ),
          ),
          const SizedBox(width: 4),
          if (isActive)
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: Tokens.accent,
            )
          else
            Icon(
              Icons.unfold_more,
              size: 12,
              color: Tokens.textMuted,
            ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }
}

// ── Count / Filter Chip ───────────────────────────────────────
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
