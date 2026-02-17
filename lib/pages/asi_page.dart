import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../state/project_providers.dart';

class AsiPage extends ConsumerStatefulWidget {
  const AsiPage({super.key});

  @override
  ConsumerState<AsiPage> createState() => _AsiPageState();
}

class _AsiPageState extends ConsumerState<AsiPage> {
  String? _statusFilter; // null = "All"
  String _sortColumn = 'number';
  bool _sortAsc = true;

  List<dynamic> _applySortAndFilter(List<dynamic> asis) {
    // Filter
    var filtered = _statusFilter == null
        ? List.of(asis)
        : asis.where((a) => a.status == _statusFilter).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'number':
          cmp = a.number.compareTo(b.number);
        case 'subject':
          cmp = a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
        case 'affectedSheets':
          cmp = (a.affectedSheets ?? '').compareTo(b.affectedSheets ?? '');
        case 'issuedBy':
          cmp = (a.issuedBy ?? '').compareTo(b.issuedBy ?? '');
        case 'date':
          cmp = a.dateIssued.compareTo(b.dateIssued);
        case 'status':
          cmp = a.status.compareTo(b.status);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return filtered;
  }

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

  void _onFilterTap(String? status) {
    setState(() {
      _statusFilter = status;
    });
  }

  Widget _buildSortableHeader(String label, String column, {double? width, int? flex}) {
    final isActive = _sortColumn == column;
    final arrow = isActive
        ? Icon(
            _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: Tokens.accent,
          )
        : const SizedBox.shrink();

    final content = InkWell(
      onTap: () => _onSort(column),
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
            const SizedBox(width: 4),
            arrow,
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return Expanded(flex: flex ?? 1, child: content);
  }

  @override
  Widget build(BuildContext context) {
    final asis = ref.watch(asisProvider);
    final issued = asis.where((a) => a.status == 'Issued').length;
    final draft = asis.where((a) => a.status == 'Draft').length;
    final displayList = _applySortAndFilter(asis);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, color: Tokens.accent, size: 22),
                  Text("ASI's", style: AppTheme.heading),
                  _CountChip(
                    label: 'All',
                    count: asis.length,
                    color: Tokens.chipBlue,
                    isSelected: _statusFilter == null,
                    onTap: () => _onFilterTap(null),
                  ),
                  _CountChip(
                    label: 'Issued',
                    count: issued,
                    color: Tokens.chipGreen,
                    isSelected: _statusFilter == 'Issued',
                    onTap: () => _onFilterTap('Issued'),
                  ),
                  _CountChip(
                    label: 'Draft',
                    count: draft,
                    color: Tokens.chipYellow,
                    isSelected: _statusFilter == 'Draft',
                    onTap: () => _onFilterTap('Draft'),
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
                                  _buildSortableHeader('ASI #', 'number', width: 80),
                                  _buildSortableHeader('SUBJECT', 'subject', flex: 4),
                                  _buildSortableHeader('AFFECTED SHEETS', 'affectedSheets', flex: 2),
                                  _buildSortableHeader('ISSUED BY', 'issuedBy', flex: 2),
                                  _buildSortableHeader('DATE', 'date', width: 90),
                                  _buildSortableHeader('STATUS', 'status', width: 70),
                                  const SizedBox(width: 60),
                                ],
                              ),
                            ),
                            const Divider(color: Tokens.glassBorder, height: 1),
                            Expanded(
                              child: displayList.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.assignment_outlined, size: 40, color: Tokens.textMuted),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No ASIs match the current filter.',
                                            style: AppTheme.body.copyWith(color: Tokens.textMuted),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                padding: const EdgeInsets.only(top: 8),
                                itemCount: displayList.length,
                                separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                                itemBuilder: (context, i) {
                                  final asi = displayList[i];
                                  final statusColor = switch (asi.status) {
                                    'Issued' => Tokens.chipGreen,
                                    'Draft' => Tokens.chipYellow,
                                    _ => Tokens.chipRed,
                                  };
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            asi.number,
                                            style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Tokens.accent),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(asi.subject, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(asi.affectedSheets ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(asi.issuedBy ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            '${asi.dateIssued.month}/${asi.dateIssued.day}/${asi.dateIssued.year}',
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
                                            child: Text(
                                              asi.status,
                                              style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              InkWell(
                                                onTap: () => showAsiDialog(context, ref, existing: asi),
                                                borderRadius: BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(Icons.edit_outlined, size: 15, color: Tokens.textMuted),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  final ok = await showDeleteConfirmation(context, asi.number);
                                                  if (ok) ref.read(asisProvider.notifier).remove(asi.id);
                                                },
                                                borderRadius: BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(Icons.delete_outline, size: 15, color: Tokens.chipRed),
                                                ),
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
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Tokens.accent,
            onPressed: () => showAsiDialog(context, ref),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.3),
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
