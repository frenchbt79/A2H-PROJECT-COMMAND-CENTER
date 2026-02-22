import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';
import '../state/folder_scan_providers.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart' show FolderScanService, ExtractedContract;

class LocationMapPage extends ConsumerStatefulWidget {
  const LocationMapPage({super.key});

  @override
  ConsumerState<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends ConsumerState<LocationMapPage> {
  bool _autoLookupAttempted = false;
  bool _isSatellite = false;

  void _tryAutoLookup(String address, String city, double lat, double lng) {
    if (_autoLookupAttempted) return;
    if (lat != 0 || lng != 0) return;
    final query = address.isNotEmpty ? address : city.isNotEmpty ? city : '';
    if (query.isEmpty) return;
    _autoLookupAttempted = true;
    lookupAddressLocation(query).then((loc) {
      if (loc != null && mounted) {
        final notifier = ref.read(projectInfoProvider.notifier);
        if (loc.city.isNotEmpty) notifier.upsertByLabel('Site', 'City', '${loc.city}, ${loc.state}', source: 'city', confidence: 0.85);
        if (loc.county.isNotEmpty) notifier.upsertByLabel('Site', 'County', loc.county, source: 'city', confidence: 0.85);
        if (loc.lat != 0) notifier.upsertByLabel('Site', 'Latitude', loc.lat.toStringAsFixed(6), source: 'city', confidence: 0.9);
        if (loc.lon != 0) notifier.upsertByLabel('Site', 'Longitude', loc.lon.toStringAsFixed(6), source: 'city', confidence: 0.9);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectInfo = ref.watch(projectInfoProvider);
    final siteDocsAsync = ref.watch(scannedSiteDocsProvider);
    final contractMetaAsync = ref.watch(contractMetadataProvider);

    String projectName = 'Project Location';
    String projectAddress = '';
    String parcelNumber = '';
    String lotSize = '';
    String zoning = '';
    String existingUse = '';
    String city = '';
    String elevation = '';
    String utmZone = '';
    double lat = 0;
    double lng = 0;

    for (final entry in projectInfo) {
      switch (entry.label) {
        case 'Project Name': projectName = entry.value;
        case 'Project Address': projectAddress = entry.value;
        case 'Parcel Number': parcelNumber = entry.value;
        case 'Lot Size': lotSize = entry.value;
        case 'Zoning Classification': zoning = entry.value;
        case 'Existing Use': existingUse = entry.value;
        case 'Latitude': lat = double.tryParse(entry.value) ?? 0;
        case 'Longitude': lng = double.tryParse(entry.value) ?? 0;
        case 'City': city = entry.value;
        case 'Elevation': elevation = entry.value;
        case 'UTM Zone': utmZone = entry.value;
      }
    }

    _tryAutoLookup(projectAddress, city, lat, lng);

    final allContracts = contractMetaAsync.valueOrNull ?? <ExtractedContract>[];
    final scannedContracts = allContracts.where((c) =>
      c.fullPath.contains(r'\Executed\') || c.fullPath.contains('/Executed/')).toList();
    if (scannedContracts.isNotEmpty) {
      final original = scannedContracts.where((c) => c.type == 'Original').toList();
      if (original.isNotEmpty && (projectName == 'Project Location' || projectName.isEmpty)) {
        projectName = '${original.first.projectNumber} \u2014 ${original.first.description}';
      }
      for (final c in scannedContracts) {
        final addrMatch = RegExp(r'(\d+\s+\w+\s+(?:Road|Rd|Street|St|Avenue|Ave|Drive|Dr|Blvd|Boulevard|Lane|Ln|Way|Circle|Ct|Court)\b)', caseSensitive: false).firstMatch(c.description);
        if (addrMatch != null && projectAddress.isEmpty) {
          projectAddress = addrMatch.group(1)!;
          break;
        }
      }
    }

    final siteDocs = siteDocsAsync.valueOrNull ?? <ScannedFile>[];
    final hasCoords = lat != 0 || lng != 0;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.location_on, color: Tokens.accent, size: 22),
              const SizedBox(width: 8),
              Text('LOCATION MAP', style: AppTheme.heading),
              const Spacer(),
              _LookupLocationButton(ref: ref, address: projectAddress, city: city),
              const SizedBox(width: 8),
              _EditAllButton(ref: ref, projectInfo: projectInfo),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Geo location and site information for $projectName',
            style: AppTheme.caption.copyWith(color: Tokens.textMuted),
          ),
          const SizedBox(height: Tokens.spaceMd),
          // ═══ Main split: Map (left) | Info (right) ═══
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: Map ──
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: _MapPanel(
                          lat: lat, lng: lng,
                          address: projectAddress,
                          projectName: projectName,
                          city: city,
                          hasCoords: hasCoords,
                          isSatellite: _isSatellite,
                          onToggleSatellite: () => setState(() => _isSatellite = !_isSatellite),
                        ),
                      ),
                      if (siteDocs.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(height: 150, child: _SiteDocumentsCard(docs: siteDocs)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // ── RIGHT: Project Information ──
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: _ProjectInfoGrid(
                      ref: ref,
                      projectInfo: projectInfo,
                      projectName: projectName,
                      address: projectAddress,
                      city: city,
                      parcelNumber: parcelNumber,
                      lotSize: lotSize,
                      zoning: zoning,
                      existingUse: existingUse,
                      lat: lat, lng: lng,
                      elevation: elevation,
                      utmZone: utmZone,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAP PANEL — with satellite toggle
// ══════════════════════════════════════════════════════════════
class _MapPanel extends StatelessWidget {
  final double lat, lng;
  final String address, projectName, city;
  final bool hasCoords, isSatellite;
  final VoidCallback onToggleSatellite;

  const _MapPanel({
    required this.lat, required this.lng,
    required this.address, required this.projectName, required this.city,
    required this.hasCoords, required this.isSatellite,
    required this.onToggleSatellite,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.map, size: 16, color: Tokens.accent),
              const SizedBox(width: 6),
              Text('PROJECT SITE', style: AppTheme.caption),
              const Spacer(),
              // ── Satellite / Map toggle ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleChip(
                      label: 'Map',
                      active: !isSatellite,
                      onTap: isSatellite ? onToggleSatellite : null,
                    ),
                    _ToggleChip(
                      label: 'Satellite',
                      active: isSatellite,
                      onTap: !isSatellite ? onToggleSatellite : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (hasCoords)
                Text(
                  '${lat.toStringAsFixed(4)}°${lat >= 0 ? 'N' : 'S'}, ${lng.abs().toStringAsFixed(4)}°${lng >= 0 ? 'E' : 'W'}',
                  style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted, fontFamily: 'monospace'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
              child: hasCoords
                ? FlutterMap(
                    key: ValueKey('map_${lat}_${lng}_$isSatellite'),
                    options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15.0, minZoom: 3.0, maxZoom: 18.0),
                    children: [
                      TileLayer(
                        urlTemplate: isSatellite
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: isSatellite ? const [] : const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.a2h.project_command_center',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(lat, lng), width: 48, height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Tokens.accent.withValues(alpha: 0.2),
                              border: Border.all(color: Tokens.accent.withValues(alpha: 0.5), width: 2),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.location_on, color: Tokens.accent, size: 28),
                          ),
                        ),
                      ]),
                      SimpleAttributionWidget(
                        source: Text(
                          isSatellite ? 'Esri World Imagery' : 'OpenStreetMap / CARTO',
                          style: TextStyle(fontSize: 10, color: Tokens.textMuted.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  )
                : _NoCoordinatesPlaceholder(projectName: projectName),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place, size: 14, color: Tokens.chipRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.isNotEmpty ? address : 'No address set',
                  style: AppTheme.body.copyWith(fontSize: 12, color: address.isNotEmpty ? Tokens.textPrimary : Tokens.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _ToggleChip({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0x0AFFFFFF),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Tokens.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontSize: 10,
            color: active ? Tokens.accent : const Color(0x42FFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROJECT INFO GRID — 3-column compact layout
// ══════════════════════════════════════════════════════════════
class _ProjectInfoGrid extends StatelessWidget {
  final WidgetRef ref;
  final List<ProjectInfoEntry> projectInfo;
  final String projectName, address, city, parcelNumber, lotSize, zoning, existingUse, elevation, utmZone;
  final double lat, lng;

  const _ProjectInfoGrid({
    required this.ref, required this.projectInfo,
    required this.projectName, required this.address, required this.city,
    required this.parcelNumber, required this.lotSize, required this.zoning,
    required this.existingUse, required this.lat, required this.lng,
    required this.elevation, required this.utmZone,
  });

  @override
  Widget build(BuildContext context) {
    // Group by category
    final grouped = <String, List<ProjectInfoEntry>>{};
    for (final e in projectInfo) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }

    // Build all info tiles from real data
    final tiles = <_InfoTile>[];
    for (final cat in grouped.keys) {
      for (final e in grouped[cat]!) {
        if (e.value.isEmpty) continue;
        tiles.add(_InfoTile(
          label: e.label,
          value: e.value,
          category: cat,
          source: e.source,
          confidence: e.confidence,
        ));
      }
    }

    // Group tiles by category for section headers
    final sections = <String, List<_InfoTile>>{};
    for (final t in tiles) {
      sections.putIfAbsent(t.category, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Tokens.accent),
            const SizedBox(width: 6),
            Text('PROJECT INFORMATION', style: AppTheme.caption),
            const Spacer(),
            _InlineEditButton(onTap: () => _showEditSiteDialog(context, ref)),
          ],
        ),
        const SizedBox(height: 10),
        // Render each category section
        for (final cat in sections.keys) ...[
          _SectionHeader(
            label: cat,
            icon: _catIcon(cat),
          ),
          const SizedBox(height: 6),
          // 3-column wrap grid
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: sections[cat]!.map((t) => _InfoCell(tile: t)).toList(),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  static IconData _catIcon(String cat) => switch (cat) {
    'General' => Icons.business_outlined,
    'Codes & Standards' => Icons.gavel_outlined,
    'Zoning' => Icons.map_outlined,
    'Site' => Icons.terrain_outlined,
    'Contacts' => Icons.people_outlined,
    _ => Icons.folder_outlined,
  };
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border(bottom: BorderSide(color: Tokens.accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Tokens.accent),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTheme.caption.copyWith(fontSize: 9, letterSpacing: 1.0, color: Tokens.accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoTile {
  final String label, value, category, source;
  final double confidence;
  const _InfoTile({required this.label, required this.value, required this.category, required this.source, required this.confidence});
}

class _InfoCell extends StatelessWidget {
  final _InfoTile tile;
  const _InfoCell({required this.tile});

  @override
  Widget build(BuildContext context) {
    // Each cell is roughly 1/3 of the container minus spacing
    return LayoutBuilder(
      builder: (context, constraints) {
        // We're inside a Wrap, so we estimate 1/3 width.
        // Since LayoutBuilder inside Wrap gets the full parent width,
        // we can't reliably constrain here. Use a fixed-ish width.
        return SizedBox(
          width: 170,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Tokens.glassFill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Tokens.glassBorder.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tile.label,
                        style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tile.source != 'manual' && tile.value.isNotEmpty)
                      Tooltip(
                        message: '${tile.source} (${(tile.confidence * 100).toInt()}%)',
                        child: Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _sourceColor(tile.source)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tile.value,
                  style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
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

// ══════════════════════════════════════════════════════════════
// NO-COORDINATES PLACEHOLDER
// ══════════════════════════════════════════════════════════════
class _NoCoordinatesPlaceholder extends StatelessWidget {
  final String projectName;
  const _NoCoordinatesPlaceholder({required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: Tokens.glassBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Tokens.accent.withValues(alpha: 0.15),
                border: Border.all(color: Tokens.accent.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.location_off, color: Tokens.accent, size: 28),
            ),
            const SizedBox(height: 12),
            Text('No coordinates set', style: AppTheme.subheading.copyWith(color: Tokens.textMuted)),
            const SizedBox(height: 4),
            Text('Use "Lookup Location" or "Edit Site Info"',
              style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BUTTONS
// ══════════════════════════════════════════════════════════════
class _EditAllButton extends StatelessWidget {
  final WidgetRef ref;
  final List<ProjectInfoEntry> projectInfo;
  const _EditAllButton({required this.ref, required this.projectInfo});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showEditSiteDialog(context, ref),
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Tokens.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 14, color: Tokens.accent),
            const SizedBox(width: 4),
            Text('Edit Site Info', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.accent)),
          ],
        ),
      ),
    );
  }
}

class _LookupLocationButton extends StatefulWidget {
  final WidgetRef ref;
  final String address;
  final String city;
  const _LookupLocationButton({required this.ref, required this.address, required this.city});
  @override
  State<_LookupLocationButton> createState() => _LookupLocationButtonState();
}

class _LookupLocationButtonState extends State<_LookupLocationButton> {
  bool _loading = false;

  Future<void> _lookup() async {
    final query = widget.address.isNotEmpty ? widget.address : widget.city.isNotEmpty ? widget.city : '';
    if (query.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Enter a project address or city first'), backgroundColor: Tokens.chipRed.withValues(alpha: 0.9), duration: const Duration(seconds: 3)),
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final loc = await lookupAddressLocation(query);
      if (loc != null) {
        final notifier = widget.ref.read(projectInfoProvider.notifier);
        if (loc.city.isNotEmpty) notifier.upsertByLabel('Site', 'City', '${loc.city}, ${loc.state}');
        if (loc.county.isNotEmpty) notifier.upsertByLabel('Site', 'County', loc.county);
        if (loc.lat != 0) notifier.upsertByLabel('Site', 'Latitude', loc.lat.toStringAsFixed(6));
        if (loc.lon != 0) notifier.upsertByLabel('Site', 'Longitude', loc.lon.toStringAsFixed(6));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location updated: ${loc.city}, ${loc.state}'), backgroundColor: Tokens.accent.withValues(alpha: 0.9), duration: const Duration(seconds: 2)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Could not geocode that address'), backgroundColor: Tokens.chipRed.withValues(alpha: 0.9)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _loading ? null : _lookup,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Tokens.chipGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(color: Tokens.chipGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Tokens.chipGreen))
            else
              const Icon(Icons.my_location, size: 14, color: Tokens.chipGreen),
            const SizedBox(width: 4),
            Text('Lookup Location', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.chipGreen)),
          ],
        ),
      ),
    );
  }
}

class _InlineEditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InlineEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.edit_outlined, size: 13, color: Tokens.textMuted),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SITE DOCUMENTS CARD
// ══════════════════════════════════════════════════════════════
class _SiteDocumentsCard extends StatelessWidget {
  final List<ScannedFile> docs;
  const _SiteDocumentsCard({required this.docs});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 14, color: Tokens.chipYellow),
              const SizedBox(width: 6),
              Text('SITE DOCUMENTS', style: AppTheme.caption),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Tokens.chipYellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Text('${docs.length}', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.chipYellow, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final f = docs[i];
                final dateStr = '${_months[f.modified.month - 1]} ${f.modified.day}';
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () => FolderScanService.openFile(f.fullPath),
                    onSecondaryTap: () => FolderScanService.openContainingFolder(f.fullPath),
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                      child: Row(
                        children: [
                          Icon(_iconForExt(f.extension), size: 14, color: Tokens.accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f.name, style: AppTheme.body.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(dateStr, style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForExt(String ext) => switch (ext.toLowerCase()) {
    '.pdf' => Icons.picture_as_pdf,
    '.dwg' || '.dxf' => Icons.architecture,
    '.jpg' || '.jpeg' || '.png' || '.tif' || '.tiff' => Icons.image,
    '.xlsx' || '.xls' || '.csv' => Icons.table_chart,
    _ => Icons.insert_drive_file,
  };
}

// ═══════════════════════════════════════════════════════════
// EDIT DIALOGS
// ═══════════════════════════════════════════════════════════
void _showEditSiteDialog(BuildContext context, WidgetRef ref) {
  final projectInfo = ref.read(projectInfoProvider);

  String address = '', city = '', parcel = '', lot = '', zoning = '', use = '';
  String latStr = '', lngStr = '', elevation = '', utmZone = '';

  for (final entry in projectInfo) {
    switch (entry.label) {
      case 'Project Address': address = entry.value;
      case 'Parcel Number': parcel = entry.value;
      case 'Lot Size': lot = entry.value;
      case 'Zoning Classification': zoning = entry.value;
      case 'Existing Use': use = entry.value;
      case 'Latitude': latStr = entry.value;
      case 'Longitude': lngStr = entry.value;
      case 'City': city = entry.value;
      case 'Elevation': elevation = entry.value;
      case 'UTM Zone': utmZone = entry.value;
    }
  }

  final addressCtrl = TextEditingController(text: address);
  final cityCtrl = TextEditingController(text: city);
  final parcelCtrl = TextEditingController(text: parcel);
  final lotCtrl = TextEditingController(text: lot);
  final zoningCtrl = TextEditingController(text: zoning);
  final useCtrl = TextEditingController(text: use);
  final latCtrl = TextEditingController(text: latStr);
  final lngCtrl = TextEditingController(text: lngStr);
  final elevCtrl = TextEditingController(text: elevation);
  final utmCtrl = TextEditingController(text: utmZone);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd), side: const BorderSide(color: Tokens.glassBorder)),
      title: Row(children: [
        const Icon(Icons.edit_location_alt, size: 20, color: Tokens.accent),
        const SizedBox(width: 8),
        Text('Edit All Site Information', style: AppTheme.heading.copyWith(fontSize: 16)),
      ]),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOCATION', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.8, color: Tokens.accent)),
              const SizedBox(height: 8),
              _DialogField(controller: addressCtrl, label: 'Address', hint: 'Full street address'),
              const SizedBox(height: 10),
              _DialogField(controller: cityCtrl, label: 'City / Zip', hint: 'e.g. San Antonio, TX 78251'),
              const SizedBox(height: 16),
              Text('COORDINATES', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.8, color: Tokens.accent)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _DialogField(controller: latCtrl, label: 'Latitude', hint: '29.471000')),
                const SizedBox(width: 12),
                Expanded(child: _DialogField(controller: lngCtrl, label: 'Longitude', hint: '-98.713000')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _DialogField(controller: elevCtrl, label: 'Elevation', hint: '~980 ft')),
                const SizedBox(width: 12),
                Expanded(child: _DialogField(controller: utmCtrl, label: 'UTM Zone', hint: '14R ...')),
              ]),
              const SizedBox(height: 16),
              Text('SITE DETAILS', style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.8, color: Tokens.accent)),
              const SizedBox(height: 8),
              _DialogField(controller: parcelCtrl, label: 'Parcel Number', hint: 'County parcel ID'),
              const SizedBox(height: 10),
              _DialogField(controller: lotCtrl, label: 'Lot Size', hint: 'e.g. 4.2 acres'),
              const SizedBox(height: 10),
              _DialogField(controller: zoningCtrl, label: 'Zoning', hint: 'e.g. MF-33'),
              const SizedBox(height: 10),
              _DialogField(controller: useCtrl, label: 'Existing Use', hint: 'Prior land use'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Tokens.accent),
          onPressed: () {
            final notifier = ref.read(projectInfoProvider.notifier);
            notifier.upsertByLabel('General', 'Project Address', addressCtrl.text.trim());
            notifier.upsertByLabel('Site', 'City', cityCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Latitude', latCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Longitude', lngCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Elevation', elevCtrl.text.trim());
            notifier.upsertByLabel('Site', 'UTM Zone', utmCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Parcel Number', parcelCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Lot Size', lotCtrl.text.trim());
            notifier.upsertByLabel('Zoning', 'Zoning Classification', zoningCtrl.text.trim());
            notifier.upsertByLabel('Site', 'Existing Use', useCtrl.text.trim());
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Site information updated'), backgroundColor: Tokens.accent.withValues(alpha: 0.9), duration: const Duration(seconds: 2)),
            );
          },
          child: const Text('Save', style: TextStyle(color: Tokens.bgDark, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _DialogField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.body.copyWith(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
        hintText: hint,
        hintStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Tokens.bgDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm), borderSide: const BorderSide(color: Tokens.glassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm), borderSide: const BorderSide(color: Tokens.glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm), borderSide: const BorderSide(color: Tokens.accent)),
      ),
    );
  }
}
