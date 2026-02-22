import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../models/project_models.dart';
import '../services/folder_scan_service.dart' show FolderScanService;
import '../widgets/folder_files_section.dart';

class ProjectInfoPage extends ConsumerWidget {
  const ProjectInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(projectInfoProvider);

    // Group by category
    final grouped = <String, List<ProjectInfoEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    final categories = grouped.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('PROJECT INFORMATION', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            flex: 3,
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final isMedium = constraints.maxWidth > 500;
              if (!isMedium) {
                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _CategoryCard(
                    category: categories[i],
                    entries: grouped[categories[i]]!,
                  ),
                );
              }
              // 3-column masonry layout for wide, 2-column for medium
              final colCount = isWide ? 3 : 2;
              final cols = List.generate(colCount, (_) => <String>[]);
              for (var i = 0; i < categories.length; i++) {
                cols[i % colCount].add(categories[i]);
              }
              return SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < colCount; c++) ...[
                      if (c > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: cols[c].map((cat) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryCard(category: cat, entries: grouped[cat]!),
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: Tokens.spaceMd),
          // ── Auto-discovered project info from contracts ──
          _DiscoveredProjectInfoSection(),
          const SizedBox(height: Tokens.spaceMd),
          Expanded(
            flex: 1,
            child: FolderFilesSection(
              sectionTitle: 'PROJECT CONTRACTS FOLDER',
              provider: scannedProjectInfoProvider,
              accentColor: Tokens.accent,
              destinationFolder: r'0 Project Management\Contracts',
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerStatefulWidget {
  final String category;
  final List<ProjectInfoEntry> entries;
  const _CategoryCard({required this.category, required this.entries});

  @override
  ConsumerState<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends ConsumerState<_CategoryCard> {
  bool _lookingUp = false;

  Future<void> _lookupZoning() async {
    final entries = ref.read(projectInfoProvider);
    final addressEntry = entries.where((e) => e.label == 'Project Address');
    final cityEntry = entries.where((e) => e.label == 'City');
    final address = addressEntry.isNotEmpty ? addressEntry.first.value : '';
    final city = cityEntry.isNotEmpty ? cityEntry.first.value : '';
    final query = address.isNotEmpty ? address : city;
    if (query.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set a Project Address or City first (Location Map page)'), backgroundColor: Tokens.chipRed),
        );
      }
      return;
    }

    setState(() => _lookingUp = true);
    final result = await lookupAddressLocation(query);
    if (!mounted) return;
    setState(() => _lookingUp = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not geocode address'), backgroundColor: Tokens.chipRed),
      );
      return;
    }

    final notifier = ref.read(projectInfoProvider.notifier);
    if (result.city.isNotEmpty) {
      notifier.upsertByLabel('Site', 'City', '${result.city}, ${result.state}',
          source: 'city', confidence: 0.85);
    }
    if (result.county.isNotEmpty) {
      notifier.upsertByLabel('Site', 'County', result.county,
          source: 'city', confidence: 0.85);
    }
    notifier.upsertByLabel('Site', 'Latitude', result.lat.toStringAsFixed(6),
        source: 'city', confidence: 0.9);
    notifier.upsertByLabel('Site', 'Longitude', result.lon.toStringAsFixed(6),
        source: 'city', confidence: 0.9);

    // Open the municipality zoning map search
    final zoningQuery = Uri.encodeComponent('${result.city} ${result.state} zoning map');
    final zoningUrl = Uri.parse('https://www.google.com/search?q=$zoningQuery');
    launchUrl(zoningUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated: ${result.city}, ${result.county}, ${result.state}'),
          backgroundColor: Tokens.chipGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryIcon = switch (widget.category) {
      'General' => Icons.business_outlined,
      'Codes & Standards' => Icons.gavel_outlined,
      'Zoning' => Icons.map_outlined,
      'Site' => Icons.terrain_outlined,
      'Contacts' => Icons.people_outlined,
      _ => Icons.folder_outlined,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(categoryIcon, size: 18, color: Tokens.accent),
              const SizedBox(width: 8),
              Text(
                widget.category.toUpperCase(),
                style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2),
              ),
              const Spacer(),
              if (widget.category == 'Zoning')
                _lookingUp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.accent))
                    : InkWell(
                        onTap: _lookupZoning,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.travel_explore, size: 14, color: Tokens.accent),
                              const SizedBox(width: 4),
                              Text('Lookup Zoning', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent)),
                            ],
                          ),
                        ),
                      ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Tokens.glassBorder, height: 1),
          const SizedBox(height: 8),
          ...widget.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(e.label, style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted)),
                ),
                Expanded(
                  child: Text(e.value, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                ),
                if (e.source != 'manual' && e.value.isNotEmpty)
                  Tooltip(
                    message: '${e.source} (${(e.confidence * 100).toInt()}%)',
                    child: Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(left: 6, top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sourceColor(e.source),
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static Color _sourceColor(String source) => switch (source) {
    'sheet' => Tokens.chipGreen,
    'city' => Tokens.chipBlue,
    'contract' => Tokens.chipYellow,
    'inferred' => Tokens.chipOrange,
    _ => Tokens.textMuted,
  };
}

// ── Auto-discovered info from contract filenames ──────────────
class _DiscoveredProjectInfoSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractMetadataProvider);
    final infoFormsAsync = ref.watch(infoFormsProvider);
    final contactsAsync = ref.watch(scannedContactsProvider);

    return contractsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();

        // Extract project info from the first (original) contract
        final original = contracts.firstWhere(
          (c) => c.type == 'Original',
          orElse: () => contracts.first,
        );

        final fmt = DateFormat('MMM d, yyyy');
        final infoForms = infoFormsAsync.valueOrNull;
        final contactFiles = contactsAsync.valueOrNull ?? [];

        // Build discovered data items
        final items = <(String, String, IconData, Color)>[
          ('Project Number', original.projectNumber, Icons.tag, Tokens.accent),
          ('Parties', original.parties, Icons.handshake_outlined, Tokens.chipBlue),
          ('Original Contract', fmt.format(original.date), Icons.calendar_today, Tokens.chipGreen),
          ('Amendments', '${contracts.where((c) => c.type == "Amendment").length} executed', Icons.edit_document, Tokens.chipBlue),
          ('Consultant Agreements', '${contracts.where((c) => c.type == "Consultant").length} executed', Icons.engineering_outlined, Tokens.chipYellow),
          if (contracts.length > 1)
            ('Latest Document', fmt.format(contracts.last.date), Icons.update, Tokens.chipOrange),
          if (infoForms != null && infoForms.count > 0)
            ('Project Change Forms', '${infoForms.count} forms (${infoForms.earliest != null ? fmt.format(infoForms.earliest!) : '?'} \u2013 ${infoForms.latest != null ? fmt.format(infoForms.latest!) : '?'})', Icons.change_circle_outlined, Tokens.chipIndigo),
          if (contactFiles.isNotEmpty)
            ('Contact Files', '${contactFiles.length} file${contactFiles.length == 1 ? '' : 's'}', Icons.contacts_outlined, Tokens.chipGreen),
        ];

        return GlassCard(
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
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(item.$3, size: 14, color: item.$4),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 160,
                      child: Text(item.$1, style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted)),
                    ),
                    Expanded(
                      child: Text(item.$2, style: AppTheme.body.copyWith(fontSize: 12)),
                    ),
                  ],
                ),
              )),
              if (contactFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...contactFiles.map((f) => InkWell(
                  onTap: () => FolderScanService.openFile(f.fullPath),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 12, color: Tokens.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.name, style: AppTheme.body.copyWith(fontSize: 11, color: Tokens.accent)),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}
