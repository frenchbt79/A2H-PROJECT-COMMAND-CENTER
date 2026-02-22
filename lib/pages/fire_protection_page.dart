import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'discipline_page.dart';
import '../services/file_ops_service.dart';

/// Fire Protection page with two tabs: Drawings (the standard discipline view)
/// and Full Set (sheets ordered by the G0.01 sheet index).
class FireProtectionPage extends ConsumerStatefulWidget {
  const FireProtectionPage({super.key});

  @override
  ConsumerState<FireProtectionPage> createState() => _FireProtectionPageState();
}

class _FireProtectionPageState extends ConsumerState<FireProtectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row with icon + title + tabs
        Padding(
          padding: const EdgeInsets.only(
            left: Tokens.spaceLg,
            right: Tokens.spaceLg,
            top: Tokens.spaceLg,
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_outlined,
                  color: Color(0xFFEF5350), size: 22),
              const SizedBox(width: 10),
              Text('FIRE PROTECTION',
                  style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              const Spacer(),
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Tokens.glassFill,
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(color: Tokens.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Tokens.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    border: Border.all(color: Tokens.accent.withValues(alpha: 0.5)),
                  ),
                  labelColor: Tokens.accent,
                  unselectedLabelColor: Tokens.textMuted,
                  labelStyle: AppTheme.caption
                      .copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  unselectedLabelStyle:
                      AppTheme.caption.copyWith(fontSize: 11),
                  dividerHeight: 0,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.all(2),
                  tabs: const [
                    Tab(
                      height: 30,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Drawings'),
                      ),
                    ),
                    Tab(
                      height: 30,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Full Set'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Standard discipline drawings view
              const DisciplinePage(
                disciplineName: 'Fire Protection',
                icon: Icons.local_fire_department_outlined,
                accentColor: Color(0xFFEF5350),
                showHeader: false,
              ),
              // Tab 2: Full Set — all sheets in G0.01 index order
              const _FullSetView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Full Set View ────────────────────────────────────────────
class _FullSetView extends ConsumerStatefulWidget {
  const _FullSetView();

  @override
  ConsumerState<_FullSetView> createState() => _FullSetViewState();
}

class _FullSetViewState extends ConsumerState<_FullSetView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final fullSetAsync = ref.watch(fullSetProvider);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: fullSetAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Tokens.accent)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Tokens.chipRed),
              const SizedBox(height: 12),
              Text('Error loading sheet index', style: AppTheme.subheading),
              const SizedBox(height: 4),
              Text('$err',
                  style: AppTheme.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt,
                      size: 48,
                      color: Tokens.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No sheet index found',
                      style: AppTheme.subheading
                          .copyWith(color: Tokens.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    'Place a G0.01 cover sheet PDF in the Scanned Drawings folder',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            );
          }

          // Filter entries
          final filtered = _filter.isEmpty
              ? entries
              : entries
                  .where((e) =>
                      e.entry.sheetNumber
                          .toLowerCase()
                          .contains(_filter.toLowerCase()) ||
                      e.entry.title
                          .toLowerCase()
                          .contains(_filter.toLowerCase()))
                  .toList();

          final foundCount =
              filtered.where((e) => e.file != null).length;
          final missingCount =
              filtered.where((e) => e.file == null).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle + stats + search
              Row(
                children: [
                  Text(
                    'Sheet index from G0.01 cover sheet',
                    style: AppTheme.caption
                        .copyWith(fontSize: 10, color: Tokens.textMuted),
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                      label: '$foundCount found',
                      color: Tokens.chipGreen),
                  if (missingCount > 0) ...[
                    const SizedBox(width: 6),
                    _StatChip(
                        label: '$missingCount missing',
                        color: Tokens.chipRed),
                  ],
                  const Spacer(),
                  // Search filter
                  SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      onChanged: (v) => setState(() => _filter = v),
                      style: AppTheme.body.copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Filter sheets...',
                        hintStyle: AppTheme.caption
                            .copyWith(fontSize: 11, color: Tokens.textMuted),
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: Tokens.textMuted),
                        filled: true,
                        fillColor: Tokens.bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Tokens.radiusSm),
                          borderSide:
                              const BorderSide(color: Tokens.glassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Tokens.radiusSm),
                          borderSide:
                              const BorderSide(color: Tokens.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Tokens.radiusSm),
                          borderSide:
                              const BorderSide(color: Tokens.accent),
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
                      // Header row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const SizedBox(width: 36),
                            SizedBox(
                              width: 44,
                              child: Text('#',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text('SHEET',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('TITLE (FROM INDEX)',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('FILE NAME',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text('SIZE',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text('MODIFIED',
                                  style: AppTheme.sidebarGroupLabel),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const Divider(
                          color: Tokens.glassBorder, height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                              color: Tokens.glassBorder, height: 1),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final entry = item.entry;
                            final file = item.file;
                            final hasFile = file != null;

                            return RepaintBoundary(
                              child: GestureDetector(
                                onSecondaryTapDown: hasFile
                                    ? (details) => showFileContextMenu(context, ref, details.globalPosition, file.fullPath)
                                    : null,
                                child: InkWell(
                                  onTap: hasFile
                                      ? () => FolderScanService.openFile(
                                          file.fullPath)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      children: [
                                        // Folder icon
                                        SizedBox(
                                          width: 36,
                                          child: hasFile
                                              ? InkWell(
                                                  onTap: () =>
                                                      FolderScanService
                                                          .openContainingFolder(
                                                              file.fullPath),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(2),
                                                    child: Icon(
                                                        Icons
                                                            .folder_open_outlined,
                                                        size: 16,
                                                        color: Tokens
                                                            .textMuted),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        // Row number
                                        SizedBox(
                                          width: 44,
                                          child: Text(
                                            '${i + 1}',
                                            style: AppTheme.caption
                                                .copyWith(
                                                    fontSize: 10,
                                                    color:
                                                        Tokens.textMuted),
                                          ),
                                        ),
                                        // Sheet number
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            entry.sheetNumber.toUpperCase(),
                                            style: AppTheme.body.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: hasFile
                                                  ? const Color(0xFFEF5350)
                                                  : Tokens.textMuted,
                                            ),
                                          ),
                                        ),
                                        // Title from index
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            entry.title,
                                            style: AppTheme.caption
                                                .copyWith(
                                                    fontSize: 11,
                                                    color:
                                                        Tokens.textMuted),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // File name
                                        Expanded(
                                          flex: 3,
                                          child: hasFile
                                              ? Text(
                                                    file.name,
                                                    style: AppTheme.body
                                                        .copyWith(
                                                            fontSize: 12),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  )
                                              : Text(
                                                  'Not found',
                                                  style: AppTheme.caption
                                                      .copyWith(
                                                    fontSize: 11,
                                                    color: Tokens.chipRed
                                                        .withValues(
                                                            alpha: 0.7),
                                                    fontStyle:
                                                        FontStyle.italic,
                                                  ),
                                                ),
                                        ),
                                        // Size
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            hasFile ? file.sizeLabel : '—',
                                            style: AppTheme.caption
                                                .copyWith(fontSize: 11),
                                          ),
                                        ),
                                        // Modified
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            hasFile
                                                ? _fmtDate(file.modified)
                                                : '—',
                                            style: AppTheme.caption
                                                .copyWith(fontSize: 10),
                                          ),
                                        ),
                                        // Open icon
                                        SizedBox(
                                          width: 40,
                                          child: hasFile
                                              ? Icon(Icons.open_in_new,
                                                  size: 14,
                                                  color: hasFile
                                                      ? const Color(
                                                          0xFFEF5350)
                                                      : Tokens.textMuted)
                                              : const SizedBox.shrink(),
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
        },
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

// ── Stat Chip ──────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}
