import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/crud_dialogs.dart';
import '../models/project_models.dart';
import '../models/scanned_file.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../services/folder_scan_service.dart' show FolderScanService, ExtractedContract;
import '../widgets/folder_files_section.dart';

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
    var result = _typeFilter == null
        ? List<ContractItem>.from(contracts)
        : contracts.where((c) => c.type == _typeFilter).toList();

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
    final asyncContractDocs = ref.watch(scannedContractDocsProvider);
    final asyncContractMeta = ref.watch(contractMetadataProvider);

    // Summary tiles always reflect ALL contracts (unfiltered)
    final totalOriginal = contracts.where((c) => c.type == 'Original').fold(0.0, (s, c) => s + c.amount);
    final totalAmendments = contracts.where((c) => c.type == 'Amendment').fold(0.0, (s, c) => s + c.amount);
    final totalCOs = contracts.where((c) => c.type == 'Change Order').fold(0.0, (s, c) => s + c.amount);
    final grandTotal = totalOriginal + totalAmendments + totalCOs;

    // Count scanned contracts
    final scannedMeta = asyncContractMeta.valueOrNull ?? [];
    final scannedOriginal = scannedMeta.where((c) => c.type == 'Original').length;
    final scannedAmendments = scannedMeta.where((c) => c.type == 'Amendment').length;
    final scannedConsultant = scannedMeta.where((c) => c.type == 'Consultant').length;
    final scannedTotal = scannedMeta.length;

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
          // Summary row — show scanned counts when available, dollar amounts when manually entered
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final items = scannedTotal > 0 ? [
                _SummaryTile(label: 'Original Contract', value: '$scannedOriginal', color: Tokens.chipGreen),
                _SummaryTile(label: 'Amendments', value: '$scannedAmendments', color: Tokens.chipBlue),
                _SummaryTile(label: 'Consultant', value: '$scannedConsultant', color: Tokens.chipYellow),
                _SummaryTile(label: 'Total Documents', value: '$scannedTotal', color: Tokens.accent),
              ] : [
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

          // ── Discovered contracts from filename scanning ──
          _DiscoveredContractsSection(asyncContractMeta: asyncContractMeta),

          // ── Description — key contract documents from scanned folders ──
          _ContractDescriptionSection(asyncContractDocs: asyncContractDocs),
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
            flex: 3,
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
                        return RepaintBoundary(child: InkWell(
                          onTap: () {
                            final scannedFiles = ref.read(scannedContractsProvider).valueOrNull ?? [];
                            final match = scannedFiles.where((f) => f.name.toLowerCase().contains(c.title.toLowerCase())).toList();
                            if (match.isNotEmpty) {
                              FolderScanService.openFile(match.first.fullPath);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('No document found for ${c.title}'), duration: const Duration(seconds: 2)),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                          ),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.spaceMd),
          Expanded(
            flex: 1,
            child: FolderFilesSection(
              sectionTitle: 'EXECUTED CONTRACTS',
              provider: scannedContractsProvider,
              accentColor: Tokens.accent,
              destinationFolder: r'0 Project Management\Contracts\Executed',
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

// ── Contract Description Section ─────────────────────────────
class _ContractDescriptionSection extends StatelessWidget {
  final AsyncValue<List<ScannedFile>> asyncContractDocs;
  const _ContractDescriptionSection({required this.asyncContractDocs});

  static const _categories = <String, List<String>>{
    'Contract': ['contract', 'agreement'],
    'Scope': ['scope'],
    'Value Engineering': ['value engineering'],
    'Services Agreement': ['services agreement', 'services'],
    'Proposal': ['proposal', 'fee'],
    'Amendment': ['amendment', 'addendum'],
    'Change Order': ['change order'],
    'Exhibit': ['exhibit'],
  };

  static const _categoryColors = <String, Color>{
    'Contract': Tokens.chipGreen,
    'Scope': Tokens.chipBlue,
    'Value Engineering': Tokens.chipYellow,
    'Services Agreement': Tokens.chipIndigo,
    'Proposal': Tokens.accent,
    'Amendment': Tokens.chipOrange,
    'Change Order': Tokens.chipRed,
    'Exhibit': Tokens.textSecondary,
  };

  static const _categoryIcons = <String, IconData>{
    'Contract': Icons.description_outlined,
    'Scope': Icons.assignment_outlined,
    'Value Engineering': Icons.engineering_outlined,
    'Services Agreement': Icons.handshake_outlined,
    'Proposal': Icons.request_page_outlined,
    'Amendment': Icons.edit_document,
    'Change Order': Icons.swap_horiz_outlined,
    'Exhibit': Icons.attach_file_outlined,
  };

  /// Categorize files by matching keywords in filename, return newest per category.
  Map<String, ScannedFile> _categorize(List<ScannedFile> files) {
    final result = <String, ScannedFile>{};
    for (final entry in _categories.entries) {
      final category = entry.key;
      final keywords = entry.value;
      // Find all files matching this category
      final matches = files.where((f) {
        final lower = f.name.toLowerCase();
        return keywords.any((kw) => lower.contains(kw));
      }).toList();
      if (matches.isNotEmpty) {
        // Keep the most recently modified
        matches.sort((a, b) => b.modified.compareTo(a.modified));
        result[category] = matches.first;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return asyncContractDocs.when(
      loading: () => GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: Tokens.accent)),
            const SizedBox(width: 10),
            Text('Scanning for contract documents...', style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (files) {
        if (files.isEmpty) return const SizedBox.shrink();

        final categorized = _categorize(files);
        if (categorized.isEmpty) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_outlined, size: 16, color: Tokens.accent),
                  const SizedBox(width: 8),
                  Text('DESCRIPTION', style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2)),
                  const Spacer(),
                  Text(
                    '${categorized.length} categories \u2022 ${files.length} documents',
                    style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categorized.entries.map((entry) {
                  final category = entry.key;
                  final file = entry.value;
                  final color = _categoryColors[category] ?? Tokens.textSecondary;
                  final icon = _categoryIcons[category] ?? Icons.insert_drive_file_outlined;
                  return _ContractDocChip(
                    category: category,
                    file: file,
                    color: color,
                    icon: icon,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Contract Document Chip — clickable, right-clickable ──────
class _ContractDocChip extends StatelessWidget {
  final String category;
  final ScannedFile file;
  final Color color;
  final IconData icon;
  const _ContractDocChip({
    required this.category,
    required this.file,
    required this.color,
    required this.icon,
  });

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xFF1E2A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          value: 'open',
          child: Row(children: [
            const Icon(Icons.open_in_new, size: 16, color: Tokens.textPrimary),
            const SizedBox(width: 8),
            Text('Open File', style: const TextStyle(color: Tokens.textPrimary, fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'folder',
          child: Row(children: [
            const Icon(Icons.folder_open, size: 16, color: Tokens.textPrimary),
            const SizedBox(width: 8),
            Text('Open in Explorer', style: const TextStyle(color: Tokens.textPrimary, fontSize: 13)),
          ]),
        ),
      ],
    ).then((value) {
      if (value == 'open') {
        FolderScanService.openFile(file.fullPath);
      } else if (value == 'folder') {
        FolderScanService.openContainingFolder(file.fullPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      onDoubleTap: () => FolderScanService.openFile(file.fullPath),
      child: Tooltip(
        message: '${file.name}\n${file.sizeLabel} \u2022 ${_months[file.modified.month - 1]} ${file.modified.day}, ${file.modified.year}\n\nDouble-click to open \u2022 Right-click for options',
        child: InkWell(
          onTap: () => FolderScanService.openFile(file.fullPath),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                    ),
                    Text(
                      _truncateName(file.name, 30),
                      style: AppTheme.caption.copyWith(fontSize: 8, color: Tokens.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.open_in_new, size: 10, color: color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _truncateName(String name, int maxLen) {
    if (name.length <= maxLen) return name;
    return '${name.substring(0, maxLen - 3)}...';
  }
}

// ── Discovered Contracts Section — auto-extracted from PDF filenames ──
class _DiscoveredContractsSection extends StatelessWidget {
  final AsyncValue<List<ExtractedContract>> asyncContractMeta;
  const _DiscoveredContractsSection({required this.asyncContractMeta});

  @override
  Widget build(BuildContext context) {
    return asyncContractMeta.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: Tokens.spaceMd),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: Tokens.accent)),
              const SizedBox(width: 10),
              Text('Scanning contract documents...', style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();

        final fmt = DateFormat('MMM d, yyyy');

        return Padding(
          padding: const EdgeInsets.only(bottom: Tokens.spaceMd),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Tokens.chipGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 14, color: Tokens.chipGreen),
                    ),
                    const SizedBox(width: 8),
                    Text('DISCOVERED FROM PROJECT FILES',
                        style: AppTheme.sidebarGroupLabel.copyWith(fontSize: 10, letterSpacing: 0.8)),
                    const Spacer(),
                    Text('${contracts.length} contract${contracts.length == 1 ? '' : 's'}',
                        style: AppTheme.caption.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Tokens.glassBorder, height: 1),
                const SizedBox(height: 6),
                ...contracts.map((c) {
                  final typeColor = switch (c.type) {
                    'Original' => Tokens.chipGreen,
                    'Amendment' => Tokens.chipBlue,
                    'Consultant' => Tokens.chipYellow,
                    _ => Tokens.textMuted,
                  };
                  return InkWell(
                    onTap: () => FolderScanService.openFile(c.fullPath),
                    onSecondaryTap: () => FolderScanService.openContainingFolder(c.fullPath),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(Tokens.radiusSm),
                            ),
                            child: Text(
                              c.type == 'Amendment' && c.amendmentNumber != null
                                  ? 'AMD #${c.amendmentNumber}'
                                  : c.type == 'Consultant' && c.amendmentNumber != null
                                      ? 'CST #${c.amendmentNumber}'
                                      : c.type.substring(0, 3).toUpperCase(),
                              style: AppTheme.caption.copyWith(fontSize: 9, color: typeColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.parties,
                                  style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  c.description,
                                  style: AppTheme.caption.copyWith(fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.displayStatus == 'Executed'
                                  ? Tokens.chipGreen.withValues(alpha: 0.12)
                                  : Tokens.chipYellow.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(Tokens.radiusSm),
                            ),
                            child: Text(
                              c.displayStatus,
                              style: AppTheme.caption.copyWith(
                                fontSize: 9,
                                color: c.displayStatus == 'Executed' ? Tokens.chipGreen : Tokens.chipYellow,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fmt.format(c.date),
                            style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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
