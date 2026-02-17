import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../state/project_providers.dart';

class SubmittalsPage extends ConsumerStatefulWidget {
  const SubmittalsPage({super.key});

  @override
  ConsumerState<SubmittalsPage> createState() => _SubmittalsPageState();
}

class _SubmittalsPageState extends ConsumerState<SubmittalsPage> {
  String? _statusFilter;
  String _sortColumn = 'number';
  bool _sortAsc = true;

  List<dynamic> _applySortAndFilter(List<dynamic> items) {
    var filtered = _statusFilter == null
        ? List.of(items)
        : items.where((s) => s.status == _statusFilter).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'number':
          cmp = a.number.compareTo(b.number);
        case 'title':
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'specSection':
          cmp = a.specSection.compareTo(b.specSection);
        case 'submittedBy':
          cmp = (a.submittedBy ?? '').compareTo(b.submittedBy ?? '');
        case 'assignedTo':
          cmp = (a.assignedTo ?? '').compareTo(b.assignedTo ?? '');
        case 'date':
          cmp = a.dateSubmitted.compareTo(b.dateSubmitted);
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
    final items = ref.watch(submittalsProvider);
    final approved = items.where((s) => s.status == 'Approved' || s.status == 'Approved as Noted').length;
    final pending = items.where((s) => s.status == 'Pending').length;
    final revise = items.where((s) => s.status == 'Revise & Resubmit').length;
    final rejected = items.where((s) => s.status == 'Rejected').length;
    final displayList = _applySortAndFilter(items);

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
                  const Icon(Icons.fact_check_outlined, color: Tokens.accent, size: 22),
                  const SizedBox(width: 2),
                  Text('Submittals', style: AppTheme.heading),
                  const SizedBox(width: 16),
                  _CountChip(label: 'All', count: items.length, color: Tokens.chipBlue, isSelected: _statusFilter == null, onTap: () => _onFilterTap(null)),
                  _CountChip(label: 'Approved', count: approved, color: Tokens.chipGreen, isSelected: _statusFilter == 'Approved', onTap: () => _onFilterTap('Approved')),
                  _CountChip(label: 'Pending', count: pending, color: Tokens.chipYellow, isSelected: _statusFilter == 'Pending', onTap: () => _onFilterTap('Pending')),
                  if (revise > 0)
                    _CountChip(label: 'Revise', count: revise, color: Tokens.chipOrange, isSelected: _statusFilter == 'Revise & Resubmit', onTap: () => _onFilterTap('Revise & Resubmit')),
                  if (rejected > 0)
                    _CountChip(label: 'Rejected', count: rejected, color: Tokens.chipRed, isSelected: _statusFilter == 'Rejected', onTap: () => _onFilterTap('Rejected')),
                ],
              ),
              const SizedBox(height: Tokens.spaceLg),
              Expanded(
                child: GlassCard(
                  child: LayoutBuilder(
                    builder: (context, outerConstraints) {
                      final minTableWidth = outerConstraints.maxWidth < 700 ? 700.0 : outerConstraints.maxWidth;
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
                            _buildSortableHeader('SUB #', 'number', width: 75),
                            _buildSortableHeader('TITLE', 'title', flex: 3),
                            _buildSortableHeader('SPEC', 'specSection', width: 80),
                            _buildSortableHeader('SUBMITTED BY', 'submittedBy', flex: 2),
                            _buildSortableHeader('REVIEWER', 'assignedTo', flex: 2),
                            _buildSortableHeader('DATE', 'date', width: 90),
                            _buildSortableHeader('STATUS', 'status', width: 120),
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
                                    const Icon(Icons.fact_check_outlined, size: 40, color: Tokens.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No submittals match the current filter.',
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
                            final sub = displayList[i];
                            final statusColor = switch (sub.status) {
                              'Approved' => Tokens.chipGreen,
                              'Approved as Noted' => Tokens.chipGreen,
                              'Pending' => Tokens.chipYellow,
                              'Revise & Resubmit' => Tokens.chipOrange,
                              'Rejected' => Tokens.chipRed,
                              _ => Tokens.textMuted,
                            };
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 75,
                                    child: Text(
                                      sub.number,
                                      style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Tokens.accent),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(sub.title, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(sub.specSection, style: AppTheme.caption.copyWith(fontSize: 11, fontFamily: 'monospace')),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(sub.submittedBy ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(sub.assignedTo ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      '${sub.dateSubmitted.month}/${sub.dateSubmitted.day}/${sub.dateSubmitted.year}',
                                      style: AppTheme.caption.copyWith(fontSize: 10),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                      ),
                                      child: Text(
                                        sub.status,
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
                                          onTap: () => showSubmittalDialog(context, ref, existing: sub),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.edit_outlined, size: 15, color: Tokens.textMuted),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            final ok = await showDeleteConfirmation(context, sub.number);
                                            if (ok) ref.read(submittalsProvider.notifier).remove(sub.id);
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
            onPressed: () => showSubmittalDialog(context, ref),
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
      child: Container(
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
