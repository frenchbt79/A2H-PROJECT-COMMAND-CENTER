import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class ContractPage extends ConsumerStatefulWidget {
  const ContractPage({super.key});

  static String _fmt(double v) {
    final neg = v < 0;
    final abs = v.abs();
    if (abs >= 1000000) return '${neg ? '-' : ''}\$${(abs / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '${neg ? '-' : ''}\$${(abs / 1000).toStringAsFixed(0)}K';
    return '${neg ? '-' : ''}\$${abs.toStringAsFixed(0)}';
  }

  @override
  ConsumerState<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends ConsumerState<ContractPage> {
  String? _typeFilter; // null means "All"
  String _sortColumn = 'title';
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

  List<ContractItem> _applySortAndFilter(List<ContractItem> contracts) {
    // Filter
    var result = _typeFilter == null
        ? List<ContractItem>.from(contracts)
        : contracts.where((c) => c.type == _typeFilter).toList();

    // Sort
    result.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'title':
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'type':
          cmp = a.type.compareTo(b.type);
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
        case 'status':
          cmp = a.status.compareTo(b.status);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final contracts = ref.watch(contractsProvider);

    // Summary tiles always reflect ALL contracts (unfiltered)
    final totalOriginal = contracts.where((c) => c.type == 'Original').fold(0.0, (s, c) => s + c.amount);
    final totalAmendments = contracts.where((c) => c.type == 'Amendment').fold(0.0, (s, c) => s + c.amount);
    final totalCOs = contracts.where((c) => c.type == 'Change Order').fold(0.0, (s, c) => s + c.amount);
    final grandTotal = totalOriginal + totalAmendments + totalCOs;

    // Apply filter + sort for the table
    final displayed = _applySortAndFilter(contracts);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTRACT', style: AppTheme.heading),
          const SizedBox(height: Tokens.spaceLg),
          // Summary row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final items = [
                _SummaryTile(label: 'Original Contract', value: ContractPage._fmt(totalOriginal), color: Tokens.chipGreen),
                _SummaryTile(label: 'Amendments', value: ContractPage._fmt(totalAmendments), color: Tokens.chipBlue),
                _SummaryTile(label: 'Change Orders', value: ContractPage._fmt(totalCOs), color: Tokens.chipYellow),
                _SummaryTile(label: 'Current Value', value: ContractPage._fmt(grandTotal), color: Tokens.accent),
              ];
              if (isWide) {
                return Row(children: items.map((t) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: t))).toList());
              }
              return Wrap(spacing: 12, runSpacing: 12, children: items.map((t) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: t)).toList());
            },
          ),
          const SizedBox(height: Tokens.spaceMd),
          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'All',
                color: Tokens.accent,
                selected: _typeFilter == null,
                onTap: () => setState(() => _typeFilter = null),
              ),
              _FilterChipButton(
                label: 'Original',
                color: Tokens.chipGreen,
                selected: _typeFilter == 'Original',
                onTap: () => setState(() => _typeFilter = 'Original'),
              ),
              _FilterChipButton(
                label: 'Amendment',
                color: Tokens.chipBlue,
                selected: _typeFilter == 'Amendment',
                onTap: () => setState(() => _typeFilter = 'Amendment'),
              ),
              _FilterChipButton(
                label: 'Change Order',
                color: Tokens.chipYellow,
                selected: _typeFilter == 'Change Order',
                onTap: () => setState(() => _typeFilter = 'Change Order'),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),
          // Contract list
          Expanded(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row — tappable for sorting
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _SortableHeader(
                            label: 'DESCRIPTION',
                            columnKey: 'title',
                            currentSort: _sortColumn,
                            ascending: _sortAsc,
                            onTap: () => _onSort('title'),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _SortableHeader(
                            label: 'TYPE',
                            columnKey: 'type',
                            currentSort: _sortColumn,
                            ascending: _sortAsc,
                            onTap: () => _onSort('type'),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _SortableHeader(
                            label: 'AMOUNT',
                            columnKey: 'amount',
                            currentSort: _sortColumn,
                            ascending: _sortAsc,
                            onTap: () => _onSort('amount'),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _SortableHeader(
                            label: 'STATUS',
                            columnKey: 'status',
                            currentSort: _sortColumn,
                            ascending: _sortAsc,
                            onTap: () => _onSort('status'),
                          ),
                        ),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  Expanded(
                    child: displayed.isEmpty
                        ? Center(
                            child: Text(
                              'No contracts match the current filter.',
                              style: AppTheme.caption.copyWith(color: Tokens.textMuted),
                            ),
                          )
                        : ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                      itemBuilder: (context, i) {
                        final c = displayed[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(c.title, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              Expanded(flex: 2, child: _TypeChip(type: c.type)),
                              Expanded(flex: 2, child: Text(ContractPage._fmt(c.amount), style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: c.amount < 0 ? Tokens.chipRed : Tokens.textPrimary))),
                              Expanded(flex: 1, child: _StatusDot(status: c.status)),
                              SizedBox(
                                width: 60,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => showContractDialog(context, ref, existing: c),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 15, color: Tokens.textMuted)),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        final ok = await showDeleteConfirmation(context, c.title);
                                        if (ok) ref.read(contractsProvider.notifier).remove(c.id);
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 15, color: Tokens.chipRed)),
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
          ),
        ],
      ),
    ),
    Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton(
        backgroundColor: Tokens.accent,
        onPressed: () => showContractDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ),
    ],
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────
class _FilterChipButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChipButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontSize: 10,
            color: selected ? color : Tokens.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Sortable Column Header ────────────────────────────────────
class _SortableHeader extends StatelessWidget {
  final String label;
  final String columnKey;
  final String currentSort;
  final bool ascending;
  final VoidCallback onTap;
  const _SortableHeader({
    required this.label,
    required this.columnKey,
    required this.currentSort,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == columnKey;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
  }
}

// ── Summary Tile ──────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.subheading.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Type Chip ─────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'Original' => Tokens.chipGreen,
      'Amendment' => Tokens.chipBlue,
      _ => Tokens.chipYellow,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
        ),
        child: Text(type, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
      ),
    );
  }
}

// ── Status Dot ────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Executed' => Tokens.chipGreen,
      'Pending' => Tokens.chipYellow,
      _ => Tokens.textMuted,
    };
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(status, style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
