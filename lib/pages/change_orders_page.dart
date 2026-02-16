import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';

class ChangeOrdersPage extends ConsumerStatefulWidget {
  const ChangeOrdersPage({super.key});

  @override
  ConsumerState<ChangeOrdersPage> createState() => _ChangeOrdersPageState();
}

class _ChangeOrdersPageState extends ConsumerState<ChangeOrdersPage> {
  String? _statusFilter;
  String _sortColumn = 'number';
  bool _sortAsc = true;
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  List<dynamic> _applySortAndFilter(List<dynamic> items) {
    var filtered = _statusFilter == null
        ? List.of(items)
        : items.where((c) => c.status == _statusFilter).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'number':
          cmp = a.number.compareTo(b.number);
        case 'description':
          cmp = a.description.toLowerCase().compareTo(b.description.toLowerCase());
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
        case 'reason':
          cmp = (a.reason ?? '').compareTo(b.reason ?? '');
        case 'initiatedBy':
          cmp = (a.initiatedBy ?? '').compareTo(b.initiatedBy ?? '');
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
    final items = ref.watch(changeOrdersProvider);
    final approved = items.where((c) => c.status == 'Approved').length;
    final pending = items.where((c) => c.status == 'Pending').length;
    final rejected = items.where((c) => c.status == 'Rejected').length;
    final displayList = _applySortAndFilter(items);

    final totalApproved = items
        .where((c) => c.status == 'Approved')
        .fold<double>(0, (sum, c) => sum + c.amount);
    final totalPending = items
        .where((c) => c.status == 'Pending')
        .fold<double>(0, (sum, c) => sum + c.amount);

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
              const Icon(Icons.swap_horiz, color: Tokens.accent, size: 22),
              const SizedBox(width: 2),
              Text('Change Orders', style: AppTheme.heading),
              const SizedBox(width: 16),
              _CountChip(label: 'All', count: items.length, color: Tokens.chipBlue, isSelected: _statusFilter == null, onTap: () => _onFilterTap(null)),
              _CountChip(label: 'Approved', count: approved, color: Tokens.chipGreen, isSelected: _statusFilter == 'Approved', onTap: () => _onFilterTap('Approved')),
              _CountChip(label: 'Pending', count: pending, color: Tokens.chipYellow, isSelected: _statusFilter == 'Pending', onTap: () => _onFilterTap('Pending')),
              if (rejected > 0)
                _CountChip(label: 'Rejected', count: rejected, color: Tokens.chipRed, isSelected: _statusFilter == 'Rejected', onTap: () => _onFilterTap('Rejected')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryTile(label: 'Approved Total', value: _currencyFormat.format(totalApproved), color: Tokens.chipGreen),
              const SizedBox(width: 12),
              _SummaryTile(label: 'Pending Total', value: _currencyFormat.format(totalPending), color: Tokens.chipYellow),
              const SizedBox(width: 12),
              _SummaryTile(label: 'Net Change', value: _currencyFormat.format(totalApproved + totalPending), color: Tokens.accent),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _buildSortableHeader('CO #', 'number', width: 70),
                        _buildSortableHeader('DESCRIPTION', 'description', flex: 4),
                        _buildSortableHeader('AMOUNT', 'amount', width: 100),
                        _buildSortableHeader('REASON', 'reason', flex: 2),
                        _buildSortableHeader('INITIATED BY', 'initiatedBy', flex: 2),
                        _buildSortableHeader('DATE', 'date', width: 90),
                        _buildSortableHeader('STATUS', 'status', width: 80),
                      ],
                    ),
                  ),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  Expanded(
                    child: displayList.isEmpty
                        ? Center(
                            child: Text(
                              'No change orders match the current filter.',
                              style: AppTheme.caption.copyWith(color: Tokens.textMuted),
                            ),
                          )
                        : ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                      itemBuilder: (context, i) {
                        final co = displayList[i];
                        final statusColor = switch (co.status) {
                          'Approved' => Tokens.chipGreen,
                          'Pending' => Tokens.chipYellow,
                          'Rejected' => Tokens.chipRed,
                          _ => Tokens.textMuted,
                        };
                        final amountColor = co.amount >= 0 ? Tokens.chipRed : Tokens.chipGreen;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  co.number,
                                  style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Tokens.accent),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(co.description, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '${co.amount >= 0 ? '+' : ''}${_currencyFormat.format(co.amount)}',
                                  style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: amountColor),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(co.reason ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(co.initiatedBy ?? '\u2014', style: AppTheme.caption.copyWith(fontSize: 11)),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  '${co.dateSubmitted.month}/${co.dateSubmitted.day}/${co.dateSubmitted.year}',
                                  style: AppTheme.caption.copyWith(fontSize: 10),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                  ),
                                  child: Text(
                                    co.status,
                                    style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                                    textAlign: TextAlign.center,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.sidebarGroupLabel),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.heading.copyWith(fontSize: 18, color: color)),
          ],
        ),
      ),
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
