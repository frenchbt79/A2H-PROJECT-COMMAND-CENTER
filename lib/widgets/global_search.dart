import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../state/nav_state.dart';

class SearchResult {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final NavRoute? route;
  const SearchResult({required this.title, required this.subtitle, required this.category, required this.icon, this.route});
}

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
    if (query.trim().length < 2) {
      _removeOverlay();
      setState(() => _results = []);
      return;
    }
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    // Search team
    for (final m in ref.read(teamProvider)) {
      if (m.name.toLowerCase().contains(q) || m.role.toLowerCase().contains(q) || m.company.toLowerCase().contains(q)) {
        results.add(SearchResult(title: m.name, subtitle: '${m.role} — ${m.company}', category: 'Team', icon: Icons.person_outline, route: NavRoute.projectTeam));
      }
    }

    // Search RFIs
    for (final r in ref.read(rfisProvider)) {
      if (r.number.toLowerCase().contains(q) || r.subject.toLowerCase().contains(q)) {
        results.add(SearchResult(title: r.number, subtitle: r.subject, category: 'RFI', icon: Icons.help_outline, route: NavRoute.rfis));
      }
    }

    // Search ASIs
    for (final a in ref.read(asisProvider)) {
      if (a.number.toLowerCase().contains(q) || a.subject.toLowerCase().contains(q)) {
        results.add(SearchResult(title: a.number, subtitle: a.subject, category: 'ASI', icon: Icons.assignment_outlined, route: NavRoute.asis));
      }
    }

    // Search drawing sheets
    for (final d in ref.read(drawingSheetsProvider)) {
      if (d.sheetNumber.toLowerCase().contains(q) || d.title.toLowerCase().contains(q)) {
        final route = switch (d.discipline) {
          'Architectural' => NavRoute.architectural,
          'Civil' => NavRoute.civil,
          'Landscape' => NavRoute.landscape,
          'Mechanical' => NavRoute.mechanical,
          'Electrical' => NavRoute.electrical,
          'Plumbing' => NavRoute.plumbing,
          _ => null,
        };
        results.add(SearchResult(title: d.sheetNumber, subtitle: '${d.title} (${d.discipline})', category: 'Drawing', icon: Icons.architecture, route: route));
      }
    }

    // Search documents
    for (final d in ref.read(phaseDocumentsProvider)) {
      if (d.name.toLowerCase().contains(q)) {
        results.add(SearchResult(title: d.name, subtitle: '${d.docType} — ${d.source}', category: 'Document', icon: Icons.description_outlined));
      }
    }

    // Search todos
    for (final t in ref.read(todosProvider)) {
      if (t.text.toLowerCase().contains(q)) {
        results.add(SearchResult(title: t.text, subtitle: t.assignee ?? 'Unassigned', category: 'Todo', icon: Icons.check_circle_outline, route: NavRoute.dashboard));
      }
    }

    // Search contracts
    for (final c in ref.read(contractsProvider)) {
      if (c.title.toLowerCase().contains(q)) {
        results.add(SearchResult(title: c.title, subtitle: c.type, category: 'Contract', icon: Icons.receipt_long_outlined, route: NavRoute.contract));
      }
    }

    // Search project info
    for (final p in ref.read(projectInfoProvider)) {
      if (p.label.toLowerCase().contains(q) || p.value.toLowerCase().contains(q)) {
        results.add(SearchResult(title: p.label, subtitle: p.value, category: p.category, icon: Icons.info_outline, route: NavRoute.projectInformationList));
      }
    }

    setState(() => _results = results.take(12).toList());
    if (_results.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (context) {
      return Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 44),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Tokens.bgMid,
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
                border: Border.all(color: Tokens.glassBorder),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return InkWell(
                      onTap: () {
                        if (r.route != null) {
                          ref.read(navProvider.notifier).selectPage(r.route!);
                        }
                        _controller.clear();
                        _removeOverlay();
                        _focusNode.unfocus();
                        setState(() => _results = []);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(r.icon, size: 18, color: Tokens.accent),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Tokens.glassFill,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(r.category, style: AppTheme.caption.copyWith(fontSize: 9)),
                            ),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 300,
        height: 38,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _search,
          style: AppTheme.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search everything...',
            hintStyle: AppTheme.caption.copyWith(fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 18, color: Tokens.textMuted),
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
