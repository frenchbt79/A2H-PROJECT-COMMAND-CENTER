import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing_metadata.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../state/nav_state.dart';

/// A single search hit — can navigate to a page, open a file, or both.
class SearchResult {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color? iconColor;
  final NavRoute? route;
  final String? filePath; // if non-null, opens this file on tap

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.iconColor,
    this.route,
    this.filePath,
  });
}

/// Bump this provider to request focus on the global search bar.
final searchFocusRequestProvider = StateProvider<int>((ref) => 0);

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<SearchResult> _results = [];

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _search(String query) {
    if (query.trim().length < 1) {
      _removeOverlay();
      setState(() => _results = []);
      return;
    }
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    // ── 1. Page navigation — match sidebar route names ──
    for (final route in NavRoute.values) {
      if (route == NavRoute.importProjectInformation) continue;
      final label = route.label;
      if (label.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: label,
          subtitle: 'Go to page',
          category: 'Page',
          icon: Icons.arrow_forward_rounded,
          iconColor: Tokens.accent,
          route: route,
        ));
      }
    }

    // ── 2. Scanned drawings (metadata layer) ──
    final metaAsync = ref.read(drawingMetadataProvider);
    final metaList = metaAsync.valueOrNull ?? <DrawingMetadata>[];
    for (final m in metaList) {
      if (m.sheetNumber.toLowerCase().contains(q) ||
          m.file.name.toLowerCase().contains(q) ||
          m.discipline.toLowerCase().contains(q)) {
        final route = switch (m.disciplinePrefix.toUpperCase()) {
          'G' => NavRoute.general,
          'S' => NavRoute.structural,
          'A' => NavRoute.architectural,
          'C' => NavRoute.civil,
          'L' => NavRoute.landscape,
          'M' => NavRoute.mechanical,
          'E' => NavRoute.electrical,
          'P' => NavRoute.plumbing,
          'FP' => NavRoute.fireProtection,
          _ => null,
        };
        results.add(SearchResult(
          title: m.sheetNumber,
          subtitle: '${m.discipline} \u2022 ${m.file.name}',
          category: 'Drawing',
          icon: Icons.architecture,
          iconColor: Tokens.accent,
          route: route,
          filePath: m.file.fullPath,
        ));
      }
      if (results.length >= 20) break;
    }

    // ── 3. Scanned CA files — RFIs, ASIs, Change Orders, Submittals, Punchlists ──
    _searchScannedFiles(q, results, ref.read(scannedRfisProvider).valueOrNull, 'RFI', Icons.help_outline, Tokens.chipYellow, NavRoute.rfis);
    _searchScannedFiles(q, results, ref.read(scannedAsisProvider).valueOrNull, 'ASI', Icons.assignment_outlined, Tokens.chipOrange, NavRoute.asis);
    _searchScannedFiles(q, results, ref.read(scannedChangeOrdersProvider).valueOrNull, 'Change Order', Icons.swap_horiz, Tokens.chipRed, NavRoute.changeOrders);
    _searchScannedFiles(q, results, ref.read(scannedSubmittalsProvider).valueOrNull, 'Submittal', Icons.send_outlined, Tokens.chipGreen, NavRoute.submittals);
    _searchScannedFiles(q, results, ref.read(scannedPunchlistsProvider).valueOrNull, 'Punchlist', Icons.checklist, Tokens.chipRed, NavRoute.punchlists);

    // ── 4. Scanned project files — Contracts, Client Provided, Specs ──
    _searchScannedFiles(q, results, ref.read(scannedContractsProvider).valueOrNull, 'Contract', Icons.receipt_long_outlined, Tokens.chipGreen, NavRoute.contract);
    _searchScannedFiles(q, results, ref.read(scannedClientProvidedProvider).valueOrNull, 'Client Provided', Icons.folder_shared_outlined, Tokens.textMuted, NavRoute.clientProvided);
    _searchScannedFiles(q, results, ref.read(scannedSpecsProvider).valueOrNull, 'Spec', Icons.menu_book_outlined, Tokens.textMuted, NavRoute.specs);

    // ── 5. Project info entries ──
    for (final p in ref.read(projectInfoProvider)) {
      if (p.label.toLowerCase().contains(q) || p.value.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: p.label,
          subtitle: p.value.isEmpty ? p.category : p.value,
          category: 'Info',
          icon: Icons.info_outline,
          route: NavRoute.projectInformationList,
        ));
      }
      if (results.length >= 20) break;
    }

    // ── 6. Team members ──
    for (final m in ref.read(teamProvider)) {
      if (m.name.toLowerCase().contains(q) || m.role.toLowerCase().contains(q) || m.company.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: m.name,
          subtitle: '${m.role} \u2014 ${m.company}',
          category: 'Team',
          icon: Icons.person_outline,
          route: NavRoute.projectTeam,
        ));
      }
    }

    // ── 7. Todos ──
    for (final t in ref.read(todosProvider)) {
      if (t.text.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: t.text,
          subtitle: t.assignee ?? 'Unassigned',
          category: 'Todo',
          icon: Icons.check_circle_outline,
          route: NavRoute.dashboard,
        ));
      }
    }

    // ── 8. Schedule phases ──
    for (final p in ref.read(scheduleProvider)) {
      if (p.name.toLowerCase().contains(q) || p.status.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: p.name,
          subtitle: '${p.status} · ${(p.progress * 100).toInt()}%',
          category: 'Schedule',
          icon: Icons.timeline,
          iconColor: Tokens.chipBlue,
          route: NavRoute.schedule,
        ));
      }
    }

    // ── 9. Budget lines ──
    for (final b in ref.read(budgetProvider)) {
      if (b.category.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: b.category,
          subtitle: 'Budget: \$${b.budgeted.toStringAsFixed(0)} · Spent: \$${b.spent.toStringAsFixed(0)}',
          category: 'Budget',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Tokens.chipGreen,
          route: NavRoute.budget,
        ));
      }
    }

    // ── 10. All project files (comprehensive file system search) ──
    if (results.length < 25) {
      final allFilesAsync = ref.read(allProjectFilesProvider);
      final allFiles = allFilesAsync.valueOrNull ?? [];
      for (final f in allFiles) {
        if (f.name.toLowerCase().contains(q)) {
          // Skip if already matched by a more specific provider
          if (results.any((r) => r.filePath == f.fullPath)) continue;
          results.add(SearchResult(
            title: f.name,
            subtitle: f.relativePath,
            category: 'File',
            icon: Icons.insert_drive_file_outlined,
            iconColor: Tokens.textMuted,
            filePath: f.fullPath,
          ));
        }
        if (results.length >= 30) break;
      }
    }

    setState(() => _results = results.take(20).toList());
    if (_results.isNotEmpty) {
      _showOverlay();
    } else {
      _showOverlay(); // show "no results" state
    }
  }

  /// Search a list of scanned files by filename and add matches to results.
  void _searchScannedFiles(
    String query,
    List<SearchResult> results,
    List<ScannedFile>? files,
    String category,
    IconData icon,
    Color color,
    NavRoute route,
  ) {
    if (files == null || results.length >= 20) return;
    for (final f in files) {
      if (f.name.toLowerCase().contains(query)) {
        results.add(SearchResult(
          title: f.name,
          subtitle: f.relativePath,
          category: category,
          icon: icon,
          iconColor: color,
          route: route,
          filePath: f.fullPath,
        ));
      }
      if (results.length >= 20) break;
    }
  }

  void _onResultTap(SearchResult r) {
    if (r.filePath != null) {
      FolderScanService.openFile(r.filePath!);
    } else if (r.route != null) {
      ref.read(navProvider.notifier).selectPage(r.route!);
    }
    _controller.clear();
    _removeOverlay();
    _focusNode.unfocus();
    setState(() => _results = []);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (context) {
      return Positioned(
        width: 440,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 44),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 440),
              decoration: BoxDecoration(
                color: Tokens.bgMid,
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
                border: Border.all(color: Tokens.glassBorder),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search_off, size: 18, color: Tokens.textMuted),
                            const SizedBox(width: 10),
                            Text('No results found', style: AppTheme.caption.copyWith(fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          return InkWell(
                            onTap: () => _onResultTap(r),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(r.icon, size: 18, color: r.iconColor ?? Tokens.accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: AppTheme.body.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(r.subtitle, style: AppTheme.caption.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Tokens.glassFill,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(r.category, style: AppTheme.caption.copyWith(fontSize: 9)),
                                  ),
                                  if (r.filePath != null) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        if (r.route != null) {
                                          ref.read(navProvider.notifier).selectPage(r.route!);
                                        }
                                        _controller.clear();
                                        _removeOverlay();
                                        _focusNode.unfocus();
                                        setState(() => _results = []);
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: Tokens.textMuted),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      );
    });
    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for focus requests from keyboard shortcut (Ctrl+K)
    ref.listen<int>(searchFocusRequestProvider, (_, __) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 300,
        height: 38,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _search,
          onTapOutside: (_) {
            // Delay to allow result tap to register before removing overlay
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!_focusNode.hasFocus) {
                _removeOverlay();
                setState(() => _results = []);
              }
            });
          },
          style: AppTheme.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search everything...   Ctrl+K',
            hintStyle: AppTheme.caption.copyWith(fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 18, color: Tokens.textMuted),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Tokens.textMuted),
                    onPressed: () {
                      _controller.clear();
                      _removeOverlay();
                      setState(() => _results = []);
                    },
                  )
                : null,
            filled: true,
            fillColor: Tokens.glassFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              borderSide: BorderSide(color: Tokens.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              borderSide: BorderSide(color: Tokens.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              borderSide: const BorderSide(color: Tokens.accent, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
