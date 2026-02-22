import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import '../models/scanned_file.dart';
import '../models/project_models.dart';
import '../models/drawing_metadata.dart';
import '../services/folder_scan_service.dart' show FolderScanService, DiscoveredMilestone, PhaseFileActivity, ExtractedContract, ExtractedFeeWorksheet;
import '../services/drawing_metadata_service.dart';
import '../services/sheet_name_parser.dart';
import '../services/storage_service.dart';
import '../services/spreadsheet_parser_service.dart';
import '../services/code_lookup_service.dart';
import '../services/jurisdiction_enricher.dart';
import '../main.dart' show storageServiceProvider, scanCacheServiceProvider;
import 'project_providers.dart' show projectInfoProvider;

// ── Pre-compiled RegExp patterns (avoid recompilation in loops) ──
final _sheetIndexPattern = RegExp(
  r'\b([A-Z]{1,3}\d+[.\-]\d[\d.\-]*[A-Za-z]?)\b\s*(.*?)(?:\r?\n|$)',
  caseSensitive: false,
);
final _sheetNumberPattern = RegExp(r'[A-Za-z]{1,3}\d+[.\-][\d.\-]*\d[A-Za-z]?');
final _titleExtractPattern = RegExp(r'^[A-Za-z]{1,3}\d+[.\-][\d.\-]*[A-Za-z]?\s*[-–—]\s*(.+)$');
final _gSheetPattern = RegExp(r'^g\d+[.\-]\d', caseSensitive: false);

// ═══════════════════════════════════════════════════════════
// PROJECT PATH — configurable base path
// ═══════════════════════════════════════════════════════════

final projectPathProvider = StateProvider<String>((ref) => r'I:\2024\24402');

/// Bump this to force all scan providers to re-fetch.
final scanRefreshProvider = StateProvider<int>((ref) => 0);

/// The scan service, derived from the current project path.
final folderScanServiceProvider = Provider<FolderScanService>((ref) {
  return FolderScanService(ref.watch(projectPathProvider));
});

// ═══════════════════════════════════════════════════════════
// PROJECTS LIST — multi-project support
// ═══════════════════════════════════════════════════════════

/// The list of saved projects.
final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ProjectsNotifier(storage);
});

/// The currently active project ID.
final activeProjectIdProvider = StateProvider<String?>((ref) => null);

/// The currently active project (derived).
final activeProjectProvider = Provider<ProjectEntry?>((ref) {
  final projects = ref.watch(projectsProvider);
  final activeId = ref.watch(activeProjectIdProvider);
  if (activeId == null || projects.isEmpty) return null;
  try {
    return projects.firstWhere((p) => p.id == activeId);
  } catch (_) {
    return projects.isNotEmpty ? projects.first : null;
  }
});

class ProjectsNotifier extends StateNotifier<List<ProjectEntry>> {
  final StorageService _storage;

  ProjectsNotifier(this._storage) : super(_storage.loadProjects());

  void add(ProjectEntry project) {
    state = [...state, project];
    _storage.saveProjects(state);
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
    _storage.saveProjects(state);
  }

  void update(ProjectEntry updated) {
    state = [
      for (final p in state)
        p.id == updated.id ? updated : p,
    ];
    _storage.saveProjects(state);
  }

  void togglePin(String id) {
    state = [
      for (final p in state)
        p.id == id ? p.copyWith(isPinned: !p.isPinned) : p,
    ];
    _storage.saveProjects(state);
  }
}

/// Pinned projects (derived from projectsProvider).
final pinnedProjectsProvider = Provider<List<ProjectEntry>>((ref) {
  return ref.watch(projectsProvider).where((p) => p.isPinned).toList();
});

// ═══════════════════════════════════════════════════════════
// ROOT PATH CHECK — verify project folder is accessible
// ═══════════════════════════════════════════════════════════

/// True when the project root (e.g. I:\2024\24402) exists and is reachable.
final rootAccessibleProvider = FutureProvider<bool>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.watch(projectPathProvider);
  ref.keepAlive();
  final svc = ref.watch(folderScanServiceProvider);
  final accessible = await svc.isRootAccessible();
  return accessible;
});

/// Whether the app is currently running in offline/cached mode.
/// Set to false once background sync pushes live data, or manually on project switch.
final offlineModeProvider = StateProvider<bool>((ref) {
  final liveData = ref.watch(backgroundFileDataProvider);
  // If background sync has pushed live data, we're online
  if (liveData != null && liveData.isNotEmpty) return false;
  // Otherwise check root accessibility
  final rootOk = ref.watch(rootAccessibleProvider).valueOrNull ?? false;
  return !rootOk;
});

// ═══════════════════════════════════════════════════════════
// PROJECT NAME — auto-extracted from contract PDF filenames
// ═══════════════════════════════════════════════════════════

/// Extracts the project name from the most recent contract PDF filename.
/// Returns null if no contract is found or name can't be parsed.
final contractProjectNameProvider = FutureProvider.family<String?, String>((ref, basePath) {
  if (basePath.isEmpty) return null;
  final svc = FolderScanService(basePath);
  return svc.extractProjectNameFromContracts();
});

// ═══════════════════════════════════════════════════════════
// DISCIPLINE SCANS — from Scanned Drawings, filtered by prefix
// ═══════════════════════════════════════════════════════════

const _scannedDrawingsPath = r'0 Project Management\Construction Documents\Scanned Drawings';

/// Map discipline names to their sheet prefix filter.
const disciplinePrefixes = <String, String>{
  'General': 'g',
  'Structural': 's',
  'Architectural': 'a',
  'Civil': 'c',
  'Landscape': 'l',
  'Mechanical': 'm',
  'Electrical': 'e',
  'Plumbing': 'p',
  'Fire Protection': 'fp',
};

/// All PDFs from Scanned Drawings — derived from allProjectFilesProvider.
/// Zero additional network I/O. Individual discipline providers derive from this.
final _allDrawingsProvider = _deriveRecursive(_scannedDrawingsPath, extensions: ['.pdf']);

/// Filter the shared scan results by discipline prefix, keeping only the
/// most recent file per sheet number.
FutureProvider<List<ScannedFile>> _disciplineProvider(String prefix) {
  return FutureProvider<List<ScannedFile>>((ref) async {
    // No keepAlive — auto-dispose when discipline page navigates away
    final allFiles = await ref.watch(_allDrawingsProvider.future);
    // Filter to files matching this discipline prefix
    final matching = allFiles.where(
      (f) => FolderScanService.matchesSheetPrefix(f.name, prefix),
    ).toList();
    // Keep only latest per sheet
    return FolderScanService.keepLatestPerSheet(matching);
  });
}

final scannedGeneralProvider = _disciplineProvider('g');
final scannedStructuralProvider = _disciplineProvider('s');
final scannedArchitecturalProvider = _disciplineProvider('a');
final scannedCivilProvider = _disciplineProvider('c');
final scannedLandscapeProvider = _disciplineProvider('l');
final scannedMechanicalProvider = _disciplineProvider('m');
final scannedElectricalProvider = _disciplineProvider('e');
final scannedPlumbingProvider = _disciplineProvider('p');
final scannedFireProtectionProvider = _disciplineProvider('fp');

// ═══════════════════════════════════════════════════════════
// FULL SET — sheet index extracted from G0.01 cover sheet
// ═══════════════════════════════════════════════════════════

/// Parsed entry from the G0.01 sheet index.
class SheetIndexEntry {
  final String sheetNumber; // e.g. "A1.01"
  final String title;       // e.g. "FLOOR PLAN - LEVEL 1"
  const SheetIndexEntry({required this.sheetNumber, required this.title});
}

/// Extracts the sheet index from the latest G0.01 PDF using pdfrx text extraction.
/// Returns an ordered list of sheet numbers + titles as listed on the cover sheet.
final sheetIndexProvider = FutureProvider<List<SheetIndexEntry>>((ref) async {
  ref.keepAlive();
  final gSheets = await ref.watch(scannedGeneralProvider.future);
  if (gSheets.isEmpty) return [];

  // Find the cover sheet / sheet index — typically G0-0, G0.0, G0.01, or G0-1
  // Prefer the one whose filename contains "COVER" or is the first G-sheet
  ScannedFile? coverSheet;
  for (final f in gSheets) {
    if (f.name.toUpperCase().contains('COVER')) {
      coverSheet = f;
      break;
    }
  }
  // Fallback: use the first G-sheet by sheet number order
  if (coverSheet == null && gSheets.isNotEmpty) {
    final sorted = List<ScannedFile>.from(gSheets)
      ..sort((a, b) => FolderScanService.sheetNumber(a.name)
          .compareTo(FolderScanService.sheetNumber(b.name)));
    coverSheet = sorted.first;
  }
  if (coverSheet == null) return [];

  try {
    final doc = await PdfDocument.openFile(coverSheet.fullPath);
    final entries = <SheetIndexEntry>[];
    final seen = <String>{};
    // Sheet index pattern: letter prefix + digits + separator + digits, then title
    for (final page in doc.pages) {
      final pageText = await page.loadText();
      final text = pageText.fullText;
      for (final m in _sheetIndexPattern.allMatches(text)) {
        final sheet = m.group(1)!.trim().toUpperCase();
        var title = (m.group(2) ?? '').trim();
        // Clean up trailing junk
        title = title.replaceAll(RegExp(r'\s{2,}.*$'), '');
        // Deduplicate by sheet number
        if (!seen.contains(sheet)) {
          seen.add(sheet);
          entries.add(SheetIndexEntry(sheetNumber: sheet, title: title));
        }
      }
    }
    doc.dispose();
    return entries;
  } catch (e) {
    return [];
  }
});

/// Full Set provider — for each sheet listed in the G0.01 index, finds the
/// latest matching PDF from Scanned Drawings. Returns them in index order.
/// If no sheet index is found (e.g. scanned image PDF without text layer),
/// falls back to showing all drawings sorted by sheet number.
final fullSetProvider = FutureProvider<List<({SheetIndexEntry entry, ScannedFile? file})>>((ref) async {
  // No keepAlive — only needed on print sets page
  final index = await ref.watch(sheetIndexProvider.future);
  final allFiles = await ref.watch(_allDrawingsProvider.future);

  // Build a map of normalized sheet number → latest file
  final latestBySheet = <String, ScannedFile>{};
  for (final f in allFiles) {
    final sn = FolderScanService.sheetNumber(f.name);
    final existing = latestBySheet[sn];
    if (existing == null || f.modified.isAfter(existing.modified)) {
      latestBySheet[sn] = f;
    }
  }

  if (index.isNotEmpty) {
    // Use the parsed sheet index — match each entry to its latest file
    return index.map((entry) {
      final normalized = FolderScanService.sheetNumber('${entry.sheetNumber}.pdf');
      final file = latestBySheet[normalized];
      return (entry: entry, file: file);
    }).toList();
  }

  // Fallback: no text index found — show all latest-per-sheet drawings in order
  final sorted = latestBySheet.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return sorted.map((e) {
    // Extract a title from the filename (after the sheet number portion)
    final name = e.value.name;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    // Try to extract title after the sheet number and separators
    final titleMatch = _titleExtractPattern.firstMatch(base);
    final title = titleMatch?.group(1)?.trim() ?? base;
    return (
      entry: SheetIndexEntry(
        sheetNumber: e.key.toUpperCase(),
        title: title,
      ),
      file: e.value as ScannedFile?,
    );
  }).toList();
});

/// Lookup helper: discipline name → its scanned provider.
final Map<String, FutureProvider<List<ScannedFile>>> disciplineScanProviders = {
  'General': scannedGeneralProvider,
  'Structural': scannedStructuralProvider,
  'Architectural': scannedArchitecturalProvider,
  'Civil': scannedCivilProvider,
  'Landscape': scannedLandscapeProvider,
  'Mechanical': scannedMechanicalProvider,
  'Electrical': scannedElectricalProvider,
  'Plumbing': scannedPlumbingProvider,
  'Fire Protection': scannedFireProtectionProvider,
};

// ═══════════════════════════════════════════════════════════
// CLOSEOUT DOCUMENTS — cached, aggregated latest-per-sheet from all disciplines
// ═══════════════════════════════════════════════════════════

/// Ordered discipline list matching G0.01 sheet index order.
const _closeoutDisciplineOrder = [
  'General', 'Architectural', 'Structural', 'Civil', 'Landscape',
  'Mechanical', 'Electrical', 'Plumbing', 'Fire Protection',
];

/// CACHE-FIRST: Closeout documents = latest drawing per sheet from all disciplines.
/// Returns from cache instantly; live data replaces cache when available.
/// Also corrects stale fullPath values when project path changes.
final closeoutDocumentsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  ref.watch(scanRefreshProvider);
  final cache = ref.watch(scanCacheServiceProvider);
  final projectPath = ref.watch(projectPathProvider);

  // ── Try live data first (all discipline providers) ──
  bool allReady = true;
  final liveFiles = <ScannedFile>[];
  for (final discipline in _closeoutDisciplineOrder) {
    final provider = disciplineScanProviders[discipline];
    if (provider == null) continue;
    final asyncVal = ref.watch(provider);
    if (asyncVal.hasValue) {
      final files = asyncVal.value!;
      final sorted = List<ScannedFile>.from(files)
        ..sort((a, b) => FolderScanService.sheetNumber(a.name)
            .compareTo(FolderScanService.sheetNumber(b.name)));
      liveFiles.addAll(sorted);
    } else {
      allReady = false;
    }
  }

  if (allReady && liveFiles.isNotEmpty) {
    // Correct fullPath: ensure it matches current project path
    final corrected = _correctPaths(liveFiles, projectPath);
    // Persist to cache for offline use
    await cache.saveFiles('closeoutDocuments', corrected);
    return corrected;
  }

  // ── Fall back to cache (instant) ──
  final cached = cache.loadFiles('closeoutDocuments');
  if (cached != null && cached.isNotEmpty) {
    return _correctPaths(cached, projectPath);
  }

  // ── Still loading — wait for all disciplines ──
  for (final discipline in _closeoutDisciplineOrder) {
    final provider = disciplineScanProviders[discipline];
    if (provider == null) continue;
    final files = await ref.watch(provider.future);
    final sorted = List<ScannedFile>.from(files)
      ..sort((a, b) => FolderScanService.sheetNumber(a.name)
          .compareTo(FolderScanService.sheetNumber(b.name)));
    liveFiles.addAll(sorted);
  }
  final corrected = _correctPaths(liveFiles, projectPath);
  await cache.saveFiles('closeoutDocuments', corrected);
  return corrected;
});

/// Ensure every ScannedFile.fullPath matches the current project path.
/// If a cached file has `I:\2019\19201\...\file.pdf` but we're now at
/// `I:\2024\24402`, rebuild the fullPath from projectPath + relativePath.
List<ScannedFile> _correctPaths(List<ScannedFile> files, String projectPath) {
  if (projectPath.isEmpty) return files;
  final normalizedProject = projectPath.replaceAll('/', r'\').toLowerCase();
  return files.map((f) {
    final normalizedFull = f.fullPath.replaceAll('/', r'\').toLowerCase();
    if (normalizedFull.startsWith(normalizedProject)) return f;
    // Rebuild fullPath from project root + relative path
    final newFull = '$projectPath\\${f.relativePath}';
    return ScannedFile(
      name: f.name,
      fullPath: newFull,
      relativePath: f.relativePath,
      sizeBytes: f.sizeBytes,
      modified: f.modified,
      extension: f.extension,
    );
  }).toList();
}

// ═══════════════════════════════════════════════════════════
// SHEET VALIDATION — background validation across all disciplines
// ═══════════════════════════════════════════════════════════

/// Validates all scanned drawings across all disciplines and returns issues.
final sheetValidationProvider = FutureProvider<List<SheetValidationIssue>>((ref) async {
  // No keepAlive — only needed when validation page is open
  final allIssues = <SheetValidationIssue>[];

  for (final entry in disciplinePrefixes.entries) {
    final name = entry.key;
    final prefix = entry.value;
    final provider = disciplineScanProviders[name];
    if (provider == null) continue;

    final files = await ref.watch(provider.future);
    final fileRecords = files
        .map((f) => (name: f.name, fullPath: f.fullPath))
        .toList();
    allIssues.addAll(
      SheetNameParser.validate(fileRecords, expectedPrefix: prefix),
    );
  }

  return allIssues;
});

// ═══════════════════════════════════════════════════════════
// DISCIPLINE CROSS-REFERENCE: RFI & ASI PDFs indexed by sheet number
// ═══════════════════════════════════════════════════════════

/// All PDFs found recursively under the RFIs folder — derived from master (0 network I/O).
final scannedRfiPdfsProvider = _deriveRecursive(
  r'0 Project Management\Construction Admin\RFIs',
  extensions: ['.pdf'],
);

/// All PDFs found recursively under the ASIs folder — derived from master (0 network I/O).
final scannedAsiPdfsProvider = _deriveRecursive(
  r'0 Project Management\Construction Admin\ASIs',
  extensions: ['.pdf'],
);

/// All PDFs related to addendums — derived from master (0 network I/O).
/// Combines three sources via in-memory filtering:
/// 1. Scanned Drawings (filenames containing "ADD")
/// 2. Construction Admin\ASIs (filenames containing "ADD")
/// 3. Construction Documents\Addendums (recursive — primary source)
final scannedAddendumPdfsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  ref.keepAlive();
  final allFiles = await ref.watch(allProjectFilesProvider.future);
  final addendumsFolderPath = r'0 Project Management\Construction Documents\Addendums'.toLowerCase();
  final asiPath = r'0 Project Management\Construction Admin\ASIs'.toLowerCase();
  final drawingsPath = _scannedDrawingsPath.toLowerCase();

  final map = <String, ScannedFile>{};
  for (final f in allFiles) {
    final rel = f.relativePath.toLowerCase();
    final ext = f.extension.toLowerCase();
    // Source 1: Scanned Drawings PDFs with "ADD" in name
    if (rel.startsWith(drawingsPath) && ext == '.pdf' && f.name.toLowerCase().contains('add')) {
      map[f.fullPath] = f;
    }
    // Source 2: ASIs folder PDFs with "ADD" in name
    if (rel.startsWith(asiPath) && ext == '.pdf' && f.name.toLowerCase().contains('add')) {
      map[f.fullPath] = f;
    }
    // Source 3: Addendums folder — all PDFs
    if (rel.startsWith(addendumsFolderPath) && ext == '.pdf') {
      map[f.fullPath] = f;
    }
  }
  final combined = map.values.toList()
    ..sort((a, b) => b.modified.compareTo(a.modified));
  return combined;
});

/// Maps normalized sheet numbers → list of Addendum PDFs that reference that sheet.
final addendumBySheetProvider = FutureProvider<Map<String, List<ScannedFile>>>((ref) async {
  final files = await ref.watch(scannedAddendumPdfsProvider.future);
  return _indexBySheetNumber(files);
});

/// Maps normalized sheet numbers → list of RFI PDFs that reference that sheet.
/// A file references a sheet if its filename contains the sheet number pattern.
final rfiBySheetProvider = FutureProvider<Map<String, List<ScannedFile>>>((ref) async {
  final files = await ref.watch(scannedRfiPdfsProvider.future);
  return _indexBySheetNumber(files);
});

/// Maps normalized sheet numbers → list of ASI PDFs that reference that sheet.
final asiBySheetProvider = FutureProvider<Map<String, List<ScannedFile>>>((ref) async {
  final files = await ref.watch(scannedAsiPdfsProvider.future);
  return _indexBySheetNumber(files);
});

/// Index a list of files by every sheet number pattern found in the filename.
Map<String, List<ScannedFile>> _indexBySheetNumber(List<ScannedFile> files) {
  final map = <String, List<ScannedFile>>{};
  final sheetPattern = _sheetNumberPattern;
  for (final f in files) {
    // Remove extension for matching
    final dot = f.name.lastIndexOf('.');
    final base = dot > 0 ? f.name.substring(0, dot) : f.name;
    // Find all sheet number references in the filename
    for (final match in sheetPattern.allMatches(base)) {
      final raw = match.group(0)!;
      final normalized = FolderScanService.sheetNumber('$raw.pdf');
      map.putIfAbsent(normalized, () => []).add(f);
    }
    // Also index by the primary sheet number of the file itself
    final primary = FolderScanService.sheetNumber(f.name);
    map.putIfAbsent(primary, () => []).add(f);
  }
  // Deduplicate entries and sort newest-first within each sheet group
  for (final key in map.keys) {
    final seen = <String>{};
    map[key] = map[key]!.where((f) => seen.add(f.fullPath)).toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
  }
  return map;
}

// ═══════════════════════════════════════════════════════════
// DRAWING METADATA — enriched intelligence layer
// ═══════════════════════════════════════════════════════════

/// All drawings enriched with cross-ref counts, phase tags, and parsed sheet info.
/// This is the single source of truth for structured drawing intelligence.
///
/// CACHE-FIRST: Returns cached metadata instantly (including RFI/ASI/ADD file
/// names per sheet). Background sync will refresh and update.
final drawingMetadataProvider = FutureProvider<List<DrawingMetadata>>((ref) async {
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);

  // ── Cache-first: return cached metadata instantly ──
  final cachedMeta = cache.loadDrawingMetadata('drawingMeta');
  final bool hasCachedMeta = cachedMeta != null && cachedMeta.isNotEmpty;

  // Check if we have live file data or are still on cache
  final liveData = ref.watch(backgroundFileDataProvider);
  final bool hasLiveData = liveData != null && liveData.isNotEmpty;

  // If we only have cached file data (no live scan yet), return cached metadata
  // immediately — don't wait for the slow I: drive scan
  if (hasCachedMeta && !hasLiveData) {
    debugPrint('[CACHE-FIRST] Returning ${cachedMeta.length} cached drawing metadata entries');
    return cachedMeta;
  }

  // Live data available (or first run) — do full enrichment
  try {
    final allFiles = await ref.watch(_allDrawingsProvider.future);
    final addMap = await ref.watch(addendumBySheetProvider.future);
    final rfiMap = await ref.watch(rfiBySheetProvider.future);
    final asiMap = await ref.watch(asiBySheetProvider.future);
    final phaseDates = ref.watch(phaseFileDatesProvider).valueOrNull ?? {};

    final result = DrawingMetadataService.enrich(
      files: allFiles,
      addMap: addMap,
      rfiMap: rfiMap,
      asiMap: asiMap,
      phaseActivity: phaseDates,
    );
    await cache.saveDrawingMetadata('drawingMeta', result);
    return result;
  } catch (_) {
    // Fallback to cache on any error
    return cachedMeta ?? [];
  }
});

/// Filter metadata by discipline prefix and keep latest per sheet.
FutureProvider<List<DrawingMetadata>> _disciplineMetaProvider(String prefix) {
  return FutureProvider<List<DrawingMetadata>>((ref) async {
    // No keepAlive — discipline meta only needed when discipline page is open
    final all = await ref.watch(drawingMetadataProvider.future);
    final matching = all.where(
      (m) => m.disciplinePrefix.toLowerCase() == prefix.toLowerCase(),
    ).toList();
    // Keep latest per sheetKey
    final latest = <String, DrawingMetadata>{};
    for (final m in matching) {
      final existing = latest[m.sheetKey];
      if (existing == null || m.file.modified.isAfter(existing.file.modified)) {
        latest[m.sheetKey] = m;
      }
    }
    return latest.values.toList();
  });
}

final metaGeneralProvider = _disciplineMetaProvider('g');
final metaStructuralProvider = _disciplineMetaProvider('s');
final metaArchitecturalProvider = _disciplineMetaProvider('a');
final metaCivilProvider = _disciplineMetaProvider('c');
final metaLandscapeProvider = _disciplineMetaProvider('l');
final metaMechanicalProvider = _disciplineMetaProvider('m');
final metaElectricalProvider = _disciplineMetaProvider('e');
final metaPlumbingProvider = _disciplineMetaProvider('p');
final metaFireProtectionProvider = _disciplineMetaProvider('fp');

/// Lookup: discipline name → metadata provider.
final Map<String, FutureProvider<List<DrawingMetadata>>> disciplineMetaProviders = {
  'General': metaGeneralProvider,
  'Structural': metaStructuralProvider,
  'Architectural': metaArchitecturalProvider,
  'Civil': metaCivilProvider,
  'Landscape': metaLandscapeProvider,
  'Mechanical': metaMechanicalProvider,
  'Electrical': metaElectricalProvider,
  'Plumbing': metaPlumbingProvider,
  'Fire Protection': metaFireProtectionProvider,
};

// ═══════════════════════════════════════════════════════════
// DERIVE-FROM-MASTER FACTORIES — zero network I/O
// ═══════════════════════════════════════════════════════════
//
// PERFORMANCE: allProjectFilesProvider does ONE network traversal of the
// entire project tree. Every other file list is derived by in-memory
// filtering — no additional network hops to the slow VPN/I: drive.

/// Derives a file list by filtering allProjectFilesProvider by relative path
/// prefix. Recursive: matches any file whose relativePath starts with [path].
FutureProvider<List<ScannedFile>> _deriveRecursive(
  String path, {
  List<String>? extensions,
}) {
  final normalizedPath = path.isEmpty ? '' : path.toLowerCase().replaceAll('/', r'\');
  return FutureProvider<List<ScannedFile>>((ref) async {
    // No keepAlive — auto-dispose when page navigates away
    final allFiles = await ref.watch(allProjectFilesProvider.future);
    var result = normalizedPath.isEmpty
        ? allFiles
        : allFiles.where((f) => f.relativePath.toLowerCase().startsWith(normalizedPath)).toList();
    if (extensions != null && extensions.isNotEmpty) {
      final exts = extensions.map((e) => e.toLowerCase()).toSet();
      result = result.where((f) => exts.contains(f.extension.toLowerCase())).toList();
    }
    return result;
  });
}

/// Derives a file list by filtering for files directly IN [path] (not recursive).
/// Matches files whose relativePath starts with [path]\ but contains no
/// additional path separators after the prefix.
FutureProvider<List<ScannedFile>> _deriveFlat(
  String path, {
  List<String>? extensions,
}) {
  final normalizedPath = path.toLowerCase().replaceAll('/', r'\');
  final prefix = '$normalizedPath\\';
  return FutureProvider<List<ScannedFile>>((ref) async {
    // No keepAlive — auto-dispose when page navigates away
    final allFiles = await ref.watch(allProjectFilesProvider.future);
    var result = allFiles.where((f) {
      final rel = f.relativePath.toLowerCase();
      if (!rel.startsWith(prefix)) return false;
      // No further path separators → file is directly in the folder (flat)
      return !rel.substring(prefix.length).contains(r'\');
    }).toList();
    if (extensions != null && extensions.isNotEmpty) {
      final exts = extensions.map((e) => e.toLowerCase()).toSet();
      result = result.where((f) => exts.contains(f.extension.toLowerCase())).toList();
    }
    return result;
  });
}

/// Derives a file list by matching filenames against keyword list.
/// Zero network I/O — filters allProjectFilesProvider in memory.
FutureProvider<List<ScannedFile>> _deriveByKeyword(List<String> keywords) {
  final lowerKeywords = keywords.map((k) => k.toLowerCase()).toList();
  return FutureProvider<List<ScannedFile>>((ref) async {
    // No keepAlive — auto-dispose when page navigates away
    final allFiles = await ref.watch(allProjectFilesProvider.future);
    return allFiles.where((f) {
      final lower = f.name.toLowerCase();
      return lowerKeywords.any((kw) => lower.contains(kw));
    }).toList();
  });
}

// ═══════════════════════════════════════════════════════════
// CONSTRUCTION ADMIN SCANS — derived from master (0 network I/O)
// ═══════════════════════════════════════════════════════════

final scannedRfisProvider = _deriveFlat(r'0 Project Management\Construction Admin\RFIs');
final scannedAsisProvider = _deriveFlat(r'0 Project Management\Construction Admin\ASIs');
final scannedChangeOrdersProvider = _deriveFlat(r'0 Project Management\Construction Admin\Change Orders');
final scannedSubmittalsProvider = _deriveFlat(r'0 Project Management\Construction Admin\Submittals');
final scannedPunchlistsProvider = _deriveFlat(r'0 Project Management\Construction Admin\Punchlist Documents');

// ═══════════════════════════════════════════════════════════
// PROJECT DETAILS SCANS — derived from master (0 network I/O)
// ═══════════════════════════════════════════════════════════

final scannedClientProvidedProvider = _deriveRecursive(r'Common\Client Provided Information');
final scannedPhotosProvider = _deriveRecursive(r'0 Project Management\Photos');
final scannedProjectInfoProvider = _deriveRecursive(r'0 Project Management\Contracts');

// ═══════════════════════════════════════════════════════════
// PROJECT ADMIN SCANS — derived from master (0 network I/O)
// ═══════════════════════════════════════════════════════════

final scannedContractsProvider = _deriveRecursive(r'0 Project Management\Contracts\Executed');

// Schedule — derived from master: Schedule folder + Contracts\Executed (0 network I/O)
final scannedScheduleProvider = FutureProvider<List<ScannedFile>>((ref) async {
  final allFiles = await ref.watch(allProjectFilesProvider.future);
  final schedPath = r'0 Project Management\Schedule'.toLowerCase();
  final contractPath = r'0 Project Management\Contracts\Executed'.toLowerCase();
  final combined = allFiles.where((f) {
    final rel = f.relativePath.toLowerCase();
    return rel.startsWith(schedPath) || rel.startsWith(contractPath);
  }).toList()
    ..sort((a, b) => b.modified.compareTo(a.modified));
  return combined;
});

// Budget — derived from master: Fee Worksheets + Contracts\Executed (0 network I/O)
final scannedBudgetProvider = FutureProvider<List<ScannedFile>>((ref) async {
  final allFiles = await ref.watch(allProjectFilesProvider.future);
  final feePath = r'0 Project Management\Contracts\Fee Worksheets'.toLowerCase();
  final contractPath = r'0 Project Management\Contracts\Executed'.toLowerCase();
  final combined = allFiles.where((f) {
    final rel = f.relativePath.toLowerCase();
    return rel.startsWith(feePath) || rel.startsWith(contractPath);
  }).toList()
    ..sort((a, b) => b.modified.compareTo(a.modified));
  return combined;
});

// ═══════════════════════════════════════════════════════════
// DELIVERABLES & MEDIA SCANS
// ═══════════════════════════════════════════════════════════

final scannedProgressPrintsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  final allFiles = await ref.watch(_allDrawingsProvider.future);
  // Filter for files in Progress subfolder from the shared scan
  final result = allFiles.where((f) {
    final rel = f.relativePath.toLowerCase();
    return rel.contains('\\progress\\') || rel.contains('/progress/');
  }).toList();
  result.sort((a, b) => b.modified.compareTo(a.modified));
  return result;
});

final scannedSignedPrintsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  final allFiles = await ref.watch(_allDrawingsProvider.future);
  // Filter for files in Signed subfolder from the shared scan
  final result = allFiles.where((f) {
    final rel = f.relativePath.toLowerCase();
    return rel.contains('\\signed\\') || rel.contains('/signed/');
  }).toList();
  result.sort((a, b) => b.modified.compareTo(a.modified));
  return result;
});

final scannedSpecsProvider = _deriveRecursive(r'0 Project Management\Construction Documents\Front End-Specs');

final scannedRenderingsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  final allFiles = await ref.watch(_allDrawingsProvider.future);
  // Filter for rendering/view files from the shared scan — zero extra I/O
  final result = allFiles.where((f) {
    final lower = f.name.toLowerCase();
    return lower.contains('view') || lower.contains('render');
  }).toList();
  result.sort((a, b) => b.modified.compareTo(a.modified));
  return result;
});

// ═══════════════════════════════════════════════════════════
// KEYWORD SCANS — derived from master (0 network I/O)
// ═══════════════════════════════════════════════════════════

final scannedContractDocsProvider = _deriveByKeyword([
  'contract', 'scope', 'value engineering', 'services agreement',
  'proposal', 'fee', 'agreement', 'amendment', 'change order',
  'addendum', 'exhibit',
]);

final scannedSiteDocsProvider = _deriveByKeyword([
  'survey', 'site', 'geotech', 'alta', 'topo', 'boundary', 'plat', 'environmental',
]);

final scannedProgrammingProvider = _deriveByKeyword(['program', 'planning']);

// ═══════════════════════════════════════════════════════════
// DISCOVERED MILESTONES — auto-derived from folder/file names
// ═══════════════════════════════════════════════════════════

/// CACHE-FIRST: milestones return from cache instantly, scan in background.
final discoveredMilestonesProvider = FutureProvider<List<DiscoveredMilestone>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);
  final liveData = ref.watch(backgroundFileDataProvider);
  final cached = cache.loadMilestones('milestones');
  // Return cache if no live scan data yet
  if (cached != null && cached.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    return cached;
  }
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.scanForMilestones();
    await cache.saveMilestones('milestones', result);
    return result;
  } catch (_) {
    return cached ?? [];
  }
});

/// CACHE-FIRST: phase dates return from cache instantly.
final phaseFileDatesProvider = FutureProvider<Map<String, PhaseFileActivity>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);
  final liveData = ref.watch(backgroundFileDataProvider);
  final cached = cache.loadPhaseActivity('phaseFileDates');
  if (cached != null && cached.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    return cached;
  }
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.scanPhaseFileDates();
    await cache.savePhaseActivity('phaseFileDates', result);
    return result;
  } catch (_) {
    return cached ?? {};
  }
});

// ═══════════════════════════════════════════════════════════
// CONTRACT METADATA — auto-extracted from contract PDF filenames
// ═══════════════════════════════════════════════════════════

/// CACHE-FIRST: contract metadata returns from cache instantly.
final contractMetadataProvider = FutureProvider<List<ExtractedContract>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);
  final liveData = ref.watch(backgroundFileDataProvider);
  final cached = cache.loadContracts('contractMeta');
  if (cached != null && cached.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    return cached;
  }
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.extractContractMetadata();
    await cache.saveContracts('contractMeta', result);
    return result;
  } catch (_) {
    return cached ?? [];
  }
});

/// CACHE-FIRST: fee worksheets return from cache instantly.
final feeWorksheetsProvider = FutureProvider<List<ExtractedFeeWorksheet>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);
  final liveData = ref.watch(backgroundFileDataProvider);
  final cached = cache.loadFeeWorksheets('feeWorksheets');
  if (cached != null && cached.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    return cached;
  }
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.extractFeeWorksheets();
    await cache.saveFeeWorksheets('feeWorksheets', result);
    return result;
  } catch (_) {
    return cached ?? [];
  }
});

/// CACHE-FIRST: info forms return from cache instantly.
final infoFormsProvider = FutureProvider<({int count, DateTime? earliest, DateTime? latest})>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);
  final liveData = ref.watch(backgroundFileDataProvider);
  final cached = cache.loadInfoForms('infoForms');
  if (cached != null && (liveData == null || liveData.isEmpty)) {
    return cached;
  }
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.scanInfoForms();
    await cache.saveInfoForms('infoForms', result);
    return result;
  } catch (_) {
    return cached ?? (count: 0, earliest: null, latest: null);
  }
});

/// Scanned contacts files — derived from master (0 network I/O).
final scannedContactsProvider = _deriveRecursive(r'0 Project Management\Contacts');

// ═══════════════════════════════════════════════════════════
// FEE WORKSHEETS — dedicated scan of Contracts\Fee Worksheets
// ═══════════════════════════════════════════════════════════

final scannedFeeWorksheetsProvider = _deriveRecursive(r'0 Project Management\Contracts\Fee Worksheets');

// ═══════════════════════════════════════════════════════════
// SHEET INDEX PDF — find latest Gx.xx Sheet Index from Scanned Drawings
// ═══════════════════════════════════════════════════════════

/// Finds the latest Gx.xx - Sheet Index PDF from Scanned Drawings.
/// Scans for PDFs whose filename starts with G and contains "Sheet Index"
/// or matches the Gx.xx pattern, then returns the most recent one.
final latestSheetIndexPdfProvider = FutureProvider<ScannedFile?>((ref) async {
  ref.keepAlive();
  final allDrawings = await ref.watch(_allDrawingsProvider.future);
  final cache = ref.watch(scanCacheServiceProvider);

  // Filter for Gx.xx sheet index candidates
  final candidates = allDrawings.where((f) {
    final lower = f.name.toLowerCase();
    // Match patterns like "G0.00", "G0.01", "G0-00", etc. that are sheet indexes
    final isGSheet = _gSheetPattern.hasMatch(lower);
    final isSheetIndex = lower.contains('sheet index') ||
        lower.contains('cover') ||
        lower.contains('sheet list') ||
        lower.contains('drawing index') ||
        lower.contains('drawing list');
    return isGSheet || isSheetIndex;
  }).toList();

  if (candidates.isEmpty) {
    // Fallback: try to find from cache
    final cached = cache.loadFiles('sheetIndexPdf');
    return cached != null && cached.isNotEmpty ? cached.first : null;
  }

  // Prefer files explicitly labeled as sheet index
  final explicit = candidates.where((f) {
    final lower = f.name.toLowerCase();
    return lower.contains('sheet index') || lower.contains('drawing index') ||
        lower.contains('sheet list') || lower.contains('drawing list');
  }).toList();

  ScannedFile? best;
  if (explicit.isNotEmpty) {
    explicit.sort((a, b) => b.modified.compareTo(a.modified));
    best = explicit.first;
  } else {
    // Fall back to lowest G-sheet number (G0.00 or G0.01 is typically the index)
    candidates.sort((a, b) {
      final snA = FolderScanService.sheetNumber(a.name);
      final snB = FolderScanService.sheetNumber(b.name);
      final cmp = snA.compareTo(snB);
      if (cmp != 0) return cmp;
      return b.modified.compareTo(a.modified); // newest first for same sheet
    });
    best = candidates.first;
  }

  // Cache for offline
  await cache.saveFiles('sheetIndexPdf', [best]);
  return best;
});

// ═══════════════════════════════════════════════════════════
// ALL PROJECT FILES — CACHE-FIRST with background refresh
// ═══════════════════════════════════════════════════════════

/// Live file data pushed by background sync after a scan completes.
/// When this has data, allProjectFilesProvider returns it instantly.
final backgroundFileDataProvider = StateProvider<List<ScannedFile>?>((ref) => null);

// ═══════════════════════════════════════════════════════════
// SYNC STATUS — reactive state for UI indicators
// ═══════════════════════════════════════════════════════════

enum SyncState { idle, syncing, done, error }

class SyncStatus {
  final SyncState state;
  final String message;
  final double progress; // 0.0 – 1.0
  final DateTime? lastSync;

  const SyncStatus({
    this.state = SyncState.idle,
    this.message = '',
    this.progress = 0.0,
    this.lastSync,
  });

  SyncStatus copyWith({
    SyncState? state,
    String? message,
    double? progress,
    DateTime? lastSync,
  }) => SyncStatus(
    state: state ?? this.state,
    message: message ?? this.message,
    progress: progress ?? this.progress,
    lastSync: lastSync ?? this.lastSync,
  );
}

final syncStatusProvider = StateProvider<SyncStatus>((ref) => const SyncStatus());

/// Whether the initial cache has been loaded (used by splash to skip waiting).
/// Derived: true once allProjectFilesProvider has resolved (cache or live).
final cacheReadyProvider = Provider<bool>((ref) {
  final async = ref.watch(allProjectFilesProvider);
  return async.hasValue;
});

/// CACHE-FIRST: Returns cached data instantly, background sync updates later.
///
/// Priority:
///   1. backgroundFileDataProvider (live data from sync) — instant
///   2. ScanCacheService (persisted cache) — instant
///   3. Live scan (first-ever launch only) — slow
final allProjectFilesProvider = FutureProvider<List<ScannedFile>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);

  // ── Priority 1: Live data from background sync ──
  final liveData = ref.watch(backgroundFileDataProvider);
  if (liveData != null && liveData.isNotEmpty) {
    return liveData;
  }

  // ── Priority 2: Persisted cache (instant) ──
  final cached = cache.loadFiles('allProjectFiles');
  if (cached != null && cached.isNotEmpty) {
    debugPrint('[CACHE-FIRST] Loaded ${cached.length} files from cache');
    return cached;
  }

  // ── Priority 3: First-ever launch — must scan (slow) ──
  debugPrint('[CACHE-FIRST] No cache, performing initial scan...');
  final svc = ref.watch(folderScanServiceProvider);
  try {
    final result = await svc.scanFolderRecursive('');
    await cache.saveFiles('allProjectFiles', result);
    return result;
  } catch (_) {
    return [];
  }
});

// ═══════════════════════════════════════════════════════════
// SPREADSHEET SCANNER — discover .xlsx/.csv in project folders
// ═══════════════════════════════════════════════════════════

/// Spreadsheets from key project folders — derived from master (0 network I/O).
final scannedSpreadsheetsProvider = FutureProvider<List<ScannedFile>>((ref) async {
  ref.keepAlive();
  final allFiles = await ref.watch(allProjectFilesProvider.future);
  final exts = {'.xlsx', '.xls', '.csv'};
  final paths = [
    r'0 Project Management'.toLowerCase(),
    r'Common\Client Provided Information'.toLowerCase(),
  ];
  // Flat scan of 0 Project Management + recursive of Contracts + Client Provided
  final results = allFiles.where((f) {
    if (!exts.contains(f.extension.toLowerCase())) return false;
    final rel = f.relativePath.toLowerCase();
    // Match files in 0 Project Management (flat) or under Contracts / Client Provided (recursive)
    return paths.any((p) => rel.startsWith(p));
  }).toList()
    ..sort((a, b) => b.modified.compareTo(a.modified));
  return results;
});

// ═══════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════
// EXTRACT PROJECT DATA FROM G0-1 (PROJECT DATA AND NOTES) PDF
// ═══════════════════════════════════════════════════════════

/// Title-case helper: "SOMERVILLE" → "Somerville", "NEW YORK" → "New York"
String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(RegExp(r'\s+')).map((w) {
    if (w.isEmpty) return w;
    // Keep short words like "of", "the", "and" lowercase unless first word
    if (w.length <= 2 && RegExp(r'^(of|or|to|in|on|at|by|an|a)$', caseSensitive: false).hasMatch(w)) {
      return w.toLowerCase();
    }
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');
}

// ═══════════════════════════════════════════════════════════
// CODES & STANDARDS — extracted from ALL G-series sheets
// ═══════════════════════════════════════════════════════════

/// Common building code / standard patterns found on A2H G-series sheets.
/// Each pattern maps a regex to a human-readable label.
final _codePatterns = <(RegExp, String)>[
  (RegExp(r'IBC\s*(\d{4})', caseSensitive: false), 'Building Code (IBC)'),
  (RegExp(r'International Building Code,?\s*(\d{4})', caseSensitive: false), 'Building Code (IBC)'),
  (RegExp(r'IECC\s*(\d{4})', caseSensitive: false), 'Energy Code (IECC)'),
  (RegExp(r'International Energy Conservation Code,?\s*(\d{4})', caseSensitive: false), 'Energy Code (IECC)'),
  (RegExp(r'IFC\s*(\d{4})', caseSensitive: false), 'Fire Code (IFC)'),
  (RegExp(r'International Fire Code,?\s*(\d{4})', caseSensitive: false), 'Fire Code (IFC)'),
  (RegExp(r'IPC\s*(\d{4})', caseSensitive: false), 'Plumbing Code (IPC)'),
  (RegExp(r'International Plumbing Code,?\s*(\d{4})', caseSensitive: false), 'Plumbing Code (IPC)'),
  (RegExp(r'IMC\s*(\d{4})', caseSensitive: false), 'Mechanical Code (IMC)'),
  (RegExp(r'International Mechanical Code,?\s*(\d{4})', caseSensitive: false), 'Mechanical Code (IMC)'),
  (RegExp(r'IFGC\s*(\d{4})', caseSensitive: false), 'Fuel Gas Code (IFGC)'),
  (RegExp(r'NEC\s*(\d{4})', caseSensitive: false), 'Electrical Code (NEC)'),
  (RegExp(r'NFPA\s*70\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Electrical Code (NFPA 70)'),
  (RegExp(r'NFPA\s*101\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Life Safety Code (NFPA 101)'),
  (RegExp(r'NFPA\s*13\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Sprinkler Systems (NFPA 13)'),
  (RegExp(r'NFPA\s*72\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Fire Alarm (NFPA 72)'),
  (RegExp(r'NFPA\s*80\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Fire Doors (NFPA 80)'),
  (RegExp(r'NFPA\s*90A\s*[-–]?\s*(\d{4})', caseSensitive: false), 'HVAC (NFPA 90A)'),
  (RegExp(r'NFPA\s*99\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Healthcare Facilities (NFPA 99)'),
  (RegExp(r'NFPA\s*110\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Emergency Power (NFPA 110)'),
  (RegExp(r'ASCE\s*7\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Structural Loads (ASCE 7)'),
  (RegExp(r'ACI\s*318\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Concrete (ACI 318)'),
  (RegExp(r'ACI\s*530\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Masonry (ACI 530)'),
  (RegExp(r'AISC\s*360\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Steel (AISC 360)'),
  (RegExp(r'AISC\s*341\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Seismic Steel (AISC 341)'),
  (RegExp(r'TMS\s*402\s*[-–]?\s*(\d{2,4})', caseSensitive: false), 'Masonry (TMS 402)'),
  (RegExp(r'AWC\s*NDS\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Wood (AWC NDS)'),
  (RegExp(r'ADA\w*\s*(2010)?', caseSensitive: false), 'Accessibility (ADA)'),
  (RegExp(r'ICC\s*A117\.1\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Accessible Design (ICC A117.1)'),
  (RegExp(r'ANSI\s*A117\.1', caseSensitive: false), 'Accessible Design (ANSI A117.1)'),
  (RegExp(r'ASHRAE\s*90\.1\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Energy Standard (ASHRAE 90.1)'),
  (RegExp(r'ASHRAE\s*62\.1\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Ventilation (ASHRAE 62.1)'),
  (RegExp(r'ASHRAE\s*170\s*[-–]?\s*(\d{4})', caseSensitive: false), 'Healthcare Ventilation (ASHRAE 170)'),
  (RegExp(r'FGI\s*(\d{4})', caseSensitive: false), 'Healthcare Guidelines (FGI)'),
  (RegExp(r'Facility Guidelines Institute', caseSensitive: false), 'Healthcare Guidelines (FGI)'),
  (RegExp(r'TN\s*State\s*Fire\s*Marshal', caseSensitive: false), 'TN State Fire Marshal'),
  (RegExp(r'TN\s*Dept\.?\s*of\s*Health', caseSensitive: false), 'TN Dept. of Health'),
  (RegExp(r'TDEC', caseSensitive: false), 'TN Dept. of Environment & Conservation'),
];

/// Scans ALL G-series PDFs and extracts every code/standard reference found.
/// Returns a map of label → value (e.g. "Building Code (IBC)" → "IBC 2021").
/// CACHE-FIRST: G-series codes return from cache instantly.
/// PDF text extraction is expensive — only re-run when background sync detects changes.
final gSeriesCodesProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);

  // Cache-first: return cached codes instantly if no live scan yet
  final liveData = ref.watch(backgroundFileDataProvider);
  final cachedCodes = cache.loadStringMap('gSeriesCodes');
  if (cachedCodes != null && cachedCodes.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    debugPrint('[CACHE-FIRST] Returning ${cachedCodes.length} cached G-series codes');
    return cachedCodes;
  }

  // Even with live data, skip re-extraction if G-sheets haven't changed since last cache
  if (cachedCodes != null && cachedCodes.isNotEmpty) {
    final lastCodesScan = cache.lastCacheTime('gSeriesCodes');
    if (lastCodesScan != null) {
      final gSheets = await ref.watch(scannedGeneralProvider.future);
      final anyNewer = gSheets.any((f) => f.modified.isAfter(lastCodesScan));
      if (!anyNewer) {
        debugPrint('[CACHE-FIRST] G-sheets unchanged since last scan, returning cached codes');
        return cachedCodes;
      }
    }
  }

  final gSheets = await ref.watch(scannedGeneralProvider.future);
  if (gSheets.isEmpty) {
    return cachedCodes ?? {};
  }

  final codes = <String, String>{};
  try {
    // Scan each G-series PDF for code references
    for (final f in gSheets) {
      try {
        final doc = await PdfDocument.openFile(f.fullPath);
        final sb = StringBuffer();
        for (final page in doc.pages) {
          final pt = await page.loadText();
          sb.writeln(pt.fullText);
        }
        doc.dispose();
        final text = sb.toString();
        if (text.trim().isEmpty) continue;

        // Check every code pattern
        for (final (pattern, label) in _codePatterns) {
          if (codes.containsKey(label)) continue; // First match wins
          final m = pattern.firstMatch(text);
          if (m != null) {
            // Build the value from the full match
            final fullMatch = m.group(0)!.trim();
            final year = m.groupCount >= 1 ? m.group(1) ?? '' : '';
            codes[label] = year.isNotEmpty ? fullMatch : label;
          }
        }

        // Also extract construction type and occupancy if found
        // Construction Type: "TYPE I-A", "TYPE II-B", "TYPE V-A OVER TYPE I-A PODIUM", "TYPE VA", etc.
        final ctRe = RegExp(
          r'(?:CONSTRUCTION\s*TYPE|TYPE\s*OF\s*CONSTRUCTION)[:\s]*'
          r'(TYPE\s+[IV]+\s*[-]?\s*[AB]?(?:\s+(?:OVER|AND|WITH|\/)\s+TYPE\s+[IV]+\s*[-]?\s*[AB]?)*)',
          caseSensitive: false,
        );
        final ctMatch = ctRe.firstMatch(text);
        if (ctMatch != null && !codes.containsKey('Construction Type')) {
          codes['Construction Type'] = ctMatch.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
        }
        // Fallback: "TYPE I-A" or "TYPE VA" without the "CONSTRUCTION TYPE" prefix  
        if (!codes.containsKey('Construction Type')) {
          final ctFallback = RegExp(
            r'\bTYPE\s+([IV]+\s*[-]?\s*[AB])\b',
            caseSensitive: false,
          );
          final ctFbMatch = ctFallback.firstMatch(text);
          if (ctFbMatch != null) {
            codes['Construction Type'] = 'Type ${ctFbMatch.group(1)!.trim().toUpperCase()}';
          }
        }

        // Occupancy Classification: "I-2", "B", "A-2, B, E", "Group I-2 (Condition 1)", etc.
        final occPatterns = [
          // "OCCUPANCY GROUP: I-2" or "OCCUPANCY CLASSIFICATION: B, I-2"
          RegExp(r'OCCUPANCY\s*(?:GROUP|CLASSIFICATION|TYPE)?[:\s]+'
              r'((?:(?:GROUP\s+)?[A-ISU]-?\d?\s*(?:\([\w\s]+\))?\s*[,/&\s]*)+)',
              caseSensitive: false),
          // "USE GROUP: I-2" or "USE AND OCCUPANCY: B"
          RegExp(r'USE\s*(?:GROUP|AND\s*OCCUPANCY)[:\s]+'
              r'((?:(?:GROUP\s+)?[A-ISU]-?\d?\s*(?:\([\w\s]+\))?\s*[,/&\s]*)+)',
              caseSensitive: false),
        ];
        for (final occRe in occPatterns) {
          if (codes.containsKey('Occupancy Classification')) break;
          final occMatch = occRe.firstMatch(text);
          if (occMatch != null) {
            var raw = occMatch.group(1)!.trim();
            // Clean trailing commas/spaces
            raw = raw.replaceAll(RegExp(r'[,/&\s]+$'), '').trim();
            if (raw.isNotEmpty) {
              codes['Occupancy Classification'] = raw.replaceAll(RegExp(r'\s+'), ' ');
            }
          }
        }
        // Sprinklered
        if (text.toUpperCase().contains('FULLY SPRINKLERED') && !codes.containsKey('Sprinklered')) {
          codes['Sprinklered'] = 'Fully Sprinklered';
        } else if (text.toUpperCase().contains('SPRINKLERED') && !codes.containsKey('Sprinklered')) {
          codes['Sprinklered'] = 'Yes';
        }
        // Building area
        final areaRe = RegExp(r'(?:BUILDING|TOTAL|GROSS)\s*(?:FLOOR\s*)?AREA[:\s]*([\d,]+)\s*(?:SF|SQ|S\.?F\.?)', caseSensitive: false);
        final areaMatch = areaRe.firstMatch(text);
        if (areaMatch != null && !codes.containsKey('Building Area')) {
          codes['Building Area'] = '${areaMatch.group(1)!} SF';
        }
        // Allowable Area
        final allowAreaRe = RegExp(r'ALLOWABLE\s*(?:BUILDING\s*)?AREA[:\s]*([\d,]+)\s*(?:SF|SQ|S\.?F\.?)?', caseSensitive: false);
        final allowAreaMatch = allowAreaRe.firstMatch(text);
        if (allowAreaMatch != null && !codes.containsKey('Allowable Area')) {
          codes['Allowable Area'] = '${allowAreaMatch.group(1)!} SF';
        }
        // Stories
        final storiesRe = RegExp(r'(?:NUMBER\s*OF\s*)?STORIES[:\s]*(\d+)', caseSensitive: false);
        final storiesMatch = storiesRe.firstMatch(text);
        if (storiesMatch != null && !codes.containsKey('Number of Stories')) {
          codes['Number of Stories'] = storiesMatch.group(1)!;
        }
        // Allowable Stories / Height
        final allowStoriesRe = RegExp(r'ALLOWABLE\s*(?:NUMBER\s*OF\s*)?STORIES[:\s]*(\d+)', caseSensitive: false);
        final allowStoriesMatch = allowStoriesRe.firstMatch(text);
        if (allowStoriesMatch != null && !codes.containsKey('Allowable Stories')) {
          codes['Allowable Stories'] = allowStoriesMatch.group(1)!;
        }
        final allowHeightRe = RegExp(r"ALLOWABLE\s*(?:BUILDING\s*)?HEIGHT[:\s]*([\d,]+)\s*(?:FT|FEET|')?", caseSensitive: false);
        final allowHeightMatch = allowHeightRe.firstMatch(text);
        if (allowHeightMatch != null && !codes.containsKey('Allowable Height')) {
          codes['Allowable Height'] = '${allowHeightMatch.group(1)!} FT';
        }
        // Separated / Non-separated mixed uses
        if (text.toUpperCase().contains('NON-SEPARATED') && !codes.containsKey('Mixed Use')) {
          codes['Mixed Use'] = 'Non-separated';
        } else if (text.toUpperCase().contains('SEPARATED USES') && !codes.containsKey('Mixed Use')) {
          codes['Mixed Use'] = 'Separated';
        }
        // Fire alarm system type
        final fireAlarmRe = RegExp(r'FIRE\s*ALARM[:\s]*(.+?)(?:\n|$)', caseSensitive: false);
        final fireAlarmMatch = fireAlarmRe.firstMatch(text);
        if (fireAlarmMatch != null && !codes.containsKey('Fire Alarm System')) {
          final val = fireAlarmMatch.group(1)!.trim();
          if (val.length > 2 && val.length < 80) {
            codes['Fire Alarm System'] = val;
          }
        }
      } catch (_) {
        // Single file failure — continue
      }
    }

    // Cache for offline
    await cache.saveStringMap('gSeriesCodes', codes);
    return codes;
  } catch (_) {
    return cache.loadStringMap('gSeriesCodes') ?? {};
  }
});

/// Finds and reads the G0-1 / G0.1 "PROJECT DATA AND NOTES" sheet from
/// Scanned Drawings, extracting key-value pairs (address, city, owner, etc.)
final projectDataSheetProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final cache = ref.watch(scanCacheServiceProvider);

  // Cache-first: return cached data if no live scan yet
  final liveData = ref.watch(backgroundFileDataProvider);
  final cachedData = cache.loadStringMap('projectDataSheet');
  if (cachedData != null && cachedData.isNotEmpty && (liveData == null || liveData.isEmpty)) {
    debugPrint('[CACHE-FIRST] Returning ${cachedData.length} cached project data fields');
    return cachedData;
  }

  final gSheets = await ref.watch(scannedGeneralProvider.future);
  debugPrint('[PROJECT-DATA] scannedGeneralProvider returned ${gSheets.length} G-sheets');
  for (final f in gSheets) {
    debugPrint('[PROJECT-DATA]   ${f.name}  sheet=${FolderScanService.sheetNumber(f.name)}  mod=${f.modified}  path=${f.fullPath}');
  }
  if (gSheets.isEmpty) return {};

  // Find the G0-1 "PROJECT DATA AND NOTES" sheet
  ScannedFile? dataSheet;
  for (final f in gSheets) {
    final upper = f.name.toUpperCase();
    if (upper.contains('PROJECT DATA') || upper.contains('PROJECT INFORMATION')) {
      dataSheet = f;
      break;
    }
  }
  // Fallback: look for G0-1, G0.1, G0-1A, G0.1A by sheet number
  if (dataSheet == null) {
    for (final f in gSheets) {
      final sn = FolderScanService.sheetNumber(f.name).toLowerCase();
      if (sn == 'g0.1' || sn == 'g0-1' || sn == 'g0.01' ||
          sn.startsWith('g0.1') || sn.startsWith('g0-1')) {
        // Skip the cover sheet (G0.0 / G0-0)
        final upper = f.name.toUpperCase();
        if (!upper.contains('COVER') && !upper.contains('SHEET INDEX')) {
          dataSheet = f;
          break;
        }
      }
    }
  }

  if (dataSheet == null) {
    debugPrint('[PROJECT-DATA] ERROR: No G0.1 / G0-1 data sheet found among ${gSheets.length} G-sheets');
    return {};
  }
  debugPrint('[PROJECT-DATA] Selected: ${dataSheet.name}  →  ${dataSheet.fullPath}');

  try {
    final doc = await PdfDocument.openFile(dataSheet.fullPath);
    final allText = StringBuffer();
    for (final page in doc.pages) {
      final pageText = await page.loadText();
      allText.writeln(pageText.fullText);
    }
    doc.dispose();
    final text = allText.toString();
    debugPrint('[PROJECT-DATA] Extracted ${text.length} chars from ${doc.pages.length} pages');
    if (text.trim().isEmpty) {
      debugPrint('[PROJECT-DATA] WARNING: PDF text is EMPTY (likely scanned image without text layer)');
      return {};
    }
    // Dump first 1500 chars for debug
    debugPrint('[PROJECT-DATA] === RAW TEXT (first 1500 chars) ===');
    debugPrint(text.substring(0, text.length > 1500 ? 1500 : text.length));
    debugPrint('[PROJECT-DATA] === END RAW TEXT ===');

    final result = <String, String>{};

    // ── De-duplicate Revit title block text ──
    // Revit PDFs render text twice (overlapping regions in the title block).
    // Clean by splitting lines and removing exact consecutive duplicates.
    final rawLines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final cleanLines = <String>[];
    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (cleanLines.isNotEmpty && line == cleanLines.last) continue;
      if (line.length > 6 && line.length.isEven) {
        final half = line.length ~/ 2;
        if (line.substring(0, half) == line.substring(half)) {
          cleanLines.add(line.substring(0, half));
          continue;
        }
      }
      cleanLines.add(line);
    }

    // ══════════════════════════════════════════════════════
    // LINE-BASED EXTRACTION — anchored on City, ST ZIP
    // ══════════════════════════════════════════════════════
    // Revit title blocks have a predictable layout:
    //   Line N-2: project number (e.g. "24402")
    //   Line N-1: owner short name (e.g. "BAPTIST")
    //   Line N  : street address  (e.g. "11225 HIGHWAY 64")
    //   Line N+1: city, ST ZIP    (e.g. "SOMERVILLE, TN 38068")
    //   Line N+2..N+5: project name split across lines
    //   Then: sheet number (e.g. "G0.1")
    //
    // We also extract the project name from the Autodesk Docs path
    // (e.g. "24402 - Baptist Micro Hospital/...").
    //
    // A2H's office address (65 GERMANTOWN CT, MEMPHIS TN 38018) must be skipped.

    final cityStZipRe = RegExp(
      r'^([A-Za-z]+(?:\s[A-Za-z]+)*)\s*,\s*([A-Z]{2})\s+(\d{5}(?:\-\d{4})?)$',
    );

    // ── Known A2H office zip codes to skip ──
    // A2H has had multiple offices over the years:
    //   65 GERMANTOWN CT SUITE 300, MEMPHIS, TN 38018  (current)
    //   3009 DAVIES PLANTATION ROAD, LAKELAND, TN 38002 (previous)
    final a2hOfficeZips = {'38018', '38002'};

    // ── Step 1: Find City, ST ZIP lines (searching line by line) ──
    for (var i = 0; i < cleanLines.length; i++) {
      final m = cityStZipRe.firstMatch(cleanLines[i]);
      if (m == null) continue;

      final city = m.group(1)!.trim();
      final state = m.group(2)!.trim();
      final zip = m.group(3)!.trim();

      // Skip A2H office addresses — check known zips AND look for "A2H" nearby
      if (a2hOfficeZips.contains(zip)) {
        debugPrint('[PROJECT-DATA] Skipping A2H office: ${cleanLines[i]}');
        continue;
      }
      // Also skip if "A2H" appears within 5 lines above this match
      bool isA2hAddress = false;
      for (var k = (i - 5).clamp(0, i); k < i; k++) {
        if (cleanLines[k].toUpperCase().contains('A2H')) {
          isA2hAddress = true;
          break;
        }
      }
      if (isA2hAddress) {
        debugPrint('[PROJECT-DATA] Skipping A2H-associated address: ${cleanLines[i]}');
        continue;
      }

      // ── Street address: line immediately before ──
      if (i > 0) {
        final prevLine = cleanLines[i - 1];
        // Validate it looks like a street address (starts with digits)
        if (RegExp(r'^\d+\s+\w').hasMatch(prevLine)) {
          result['Project Address'] = _titleCase(prevLine);
        }
      }
      result['City'] = _titleCase(city);
      result['State'] = state;
      result['Zip'] = zip;

      // ── Project number: search lines above the address for a number like "24402" or "19514.01" ──
      for (var k = (i - 1).clamp(0, i); k >= 0 && k >= i - 6; k--) {
        final numCandidate = cleanLines[k].trim();
        if (RegExp(r'^\d{4,6}(\.\d{1,3})?$').hasMatch(numCandidate)) {
          result['Project Number'] = numCandidate;
          break;
        }
      }

      // ── Project name: lines AFTER city/state/zip, before sheet ID ──
      // In A2H title blocks: project name follows the address block.
      final nameParts = <String>[];
      for (var j = i + 1; j < cleanLines.length && j <= i + 6; j++) {
        final line = cleanLines[j];
        // Stop at sheet number (e.g. "G0.1"), date, or "CONSTRUCTION DOCUMENTS"
        if (RegExp(r'^[A-Z]\d+[\.\-]').hasMatch(line)) break;
        if (line == 'CONSTRUCTION') break;
        if (line == 'DOCUMENTS') break;
        if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(line)) break;
        // Collect short ALL-CAPS lines as name parts
        if (line.length <= 50 && line.toUpperCase() == line) {
          nameParts.add(line);
        } else {
          break;
        }
      }
      if (nameParts.isNotEmpty) {
        final rawName = nameParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        // Clean trailing dashes: "HOSPITAL -" → "HOSPITAL"
        final cleaned = rawName.replaceAll(RegExp(r'\s*-\s*$'), '').trim();
        if (cleaned.length > 3) {
          result['Project Name'] = _titleCase(cleaned);
        }
      }

      break; // Found the project address, stop searching
    }

    // ── Autodesk Docs / BIM 360 path — fallback project name ──
    // Patterns:
    //   "Autodesk Docs://24402 - Baptist Micro Hospital/..."
    //   "BIM 360://19514 - HR - Main/..."
    if (!result.containsKey('Project Name')) {
      final docsPathMatch = RegExp(
        r'(?:Autodesk Docs|BIM 360)://\d+(?:\.\d+)?\s*-\s*(.+?)/',
        caseSensitive: false,
      ).firstMatch(text);
      if (docsPathMatch != null) {
        final name = docsPathMatch.group(1)!.trim();
        if (name.length > 3) {
          result['Project Name'] = _titleCase(name);
        }
      }
    }

    // ── Project number fallback from Autodesk Docs / BIM 360 path ──
    if (!result.containsKey('Project Number')) {
      final numMatch = RegExp(
        r'(?:Autodesk Docs|BIM 360)://(\d{4,6}(?:\.\d+)?)\s*-',
      ).firstMatch(text);
      if (numMatch != null) {
        result['Project Number'] = numMatch.group(1)!;
      }
    }

    // ── Architect: look for "A2H" as a standalone line near title block ──
    if (!result.containsKey('Architect')) {
      for (final line in cleanLines) {
        if (line.trim() == 'A2H, INC.' || line.trim() == 'A2H') {
          result['Architect'] = 'A2H';
          break;
        }
      }
    }

    debugPrint('[PROJECT-DATA] === EXTRACTION RESULTS ===');
    for (final e in result.entries) {
      debugPrint('[PROJECT-DATA]   ${e.key}: ${e.value}');
    }
    if (result.isEmpty) {
      debugPrint('[PROJECT-DATA] WARNING: No data extracted from PDF text');
      debugPrint('[PROJECT-DATA] Clean lines (${cleanLines.length}):');
      for (var i = 0; i < cleanLines.length && i < 40; i++) {
        debugPrint('[PROJECT-DATA]   [$i] "${cleanLines[i]}"');
      }
    }
    // Cache for offline use
    if (result.isNotEmpty) {
      await cache.saveStringMap('projectDataSheet', result);
    }
    return result;
  } catch (e, stack) {
    debugPrint('[PROJECT-DATA] ERROR: $e\n$stack');
    return cachedData ?? {};
  }
});

// ═══════════════════════════════════════════════════════════
// ENRICH PROJECT INFO — G0-1 PDF + contracts + geocoding + sheets + codes
// ═══════════════════════════════════════════════════════════

final enrichProjectInfoProvider = FutureProvider<void>((ref) async {
  ref.watch(scanRefreshProvider);
  ref.keepAlive();
  final activeProject = ref.watch(activeProjectProvider);
  final projectPath = ref.watch(projectPathProvider);
  if (projectPath.isEmpty) return;

  // ── Parallel fetch: all independent data sources at once ──
  final results = await Future.wait([
    ref.watch(contractMetadataProvider.future),       // [0]
    ref.watch(projectDataSheetProvider.future),        // [1]
    ref.watch(gSeriesCodesProvider.future),             // [2]
    ref.watch(scannedSpreadsheetsProvider.future),      // [3]
  ]);
  final allContracts = results[0] as List<ExtractedContract>;
  final pdfData = results[1] as Map<String, String>;
  final gCodes = results[2] as Map<String, String>;
  final spreadsheets = results[3] as List<ScannedFile>;

  final contracts = allContracts.where((c) =>
    c.fullPath.contains(r'\Executed\') || c.fullPath.contains('/Executed/')).toList();

  await Future.microtask(() {});

  final notifier = ref.read(projectInfoProvider.notifier);

  // Clear stale automated fields so garbage from previous parses doesn't persist
  notifier.clearAutomatedFields();

  // ── Contract-based enrichment ──
  final projectNumber = activeProject?.number ??
      projectPath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).lastOrNull ?? '';
  final projectName = activeProject?.name ?? '';
  if (projectNumber.isNotEmpty) {
    notifier.upsertByLabel('General', 'Project Number', projectNumber,
        source: 'contract', confidence: 0.9);
  }
  if (projectName.isNotEmpty) {
    notifier.upsertByLabel('General', 'Project Name', projectName,
        source: 'contract', confidence: 0.9);
  }

  // ── Extract data from G0-1 PROJECT DATA AND NOTES PDF ──
  // Already fetched in parallel above as `pdfData`
  String pdfAddress = '';
  String pdfCity = '';
  String pdfState = '';
  try {
    if (pdfData.isNotEmpty) {
      // Map extracted fields to project info entries
      final pdfMappings = <String, (String, String)>{
        'Project Name':       ('General', 'Project Name'),
        'Project Number':     ('General', 'Project Number'),
        'Owner':              ('General', 'Client'),
        'Project Address':    ('General', 'Project Address'),
        'Construction Type':  ('Codes & Standards', 'Construction Type'),
        'Occupancy':          ('Codes & Standards', 'Occupancy Classification'),
        'Building Area':      ('General', 'Building Area (SF)'),
        'Stories':            ('General', 'Number of Stories'),
        'Sprinklered':        ('Codes & Standards', 'Sprinklered'),
        'Zoning':             ('Zoning', 'Zoning Classification'),
        'Jurisdiction':       ('Codes & Standards', 'Jurisdiction / AHJ'),
        'Architect':          ('General', 'Architect'),
      };
      for (final entry in pdfMappings.entries) {
        final val = pdfData[entry.key];
        if (val != null && val.isNotEmpty) {
          notifier.upsertByLabel(entry.value.$1, entry.value.$2, val,
              source: 'sheet', confidence: 0.9);
        }
      }
      pdfAddress = pdfData['Project Address'] ?? '';
      pdfCity = pdfData['City'] ?? '';
      pdfState = pdfData['State'] ?? '';
      // Store city/state from PDF directly
      if (pdfCity.isNotEmpty) {
        final cityState = pdfState.isNotEmpty ? '$pdfCity, $pdfState' : pdfCity;
        notifier.upsertByLabel('Site', 'City', cityState,
            source: 'sheet', confidence: 0.9);
      }
      if (pdfData['Zip'] != null && pdfData['Zip']!.isNotEmpty) {
        notifier.upsertByLabel('Site', 'Zip Code', pdfData['Zip']!,
            source: 'sheet', confidence: 0.9);
      }
    }
  } catch (_) {
    // PDF parsing is best-effort
  }

  // ── Contract filename address extraction (fallback) ──
  // Search BOTH executed contracts AND fee worksheets for street addresses.
  String contractAddress = '';
  final _streetRe = RegExp(
    r'(\d+\s+[\w\s]+?(?:Road|Rd|Street|St|Avenue|Ave|Drive|Dr|Blvd|Boulevard|Lane|Ln|Way|Circle|Ct|Court|Pike|Pkwy|Parkway|Highway|Hwy|Place|Pl|Terrace|Ter|Trail|Tr|Run|Pass|Loop|Cove|Cv)\b)',
    caseSensitive: false);
  if (contracts.isNotEmpty) {
    final original = contracts.firstWhere(
      (c) => c.type == 'Original', orElse: () => contracts.first);
    if (original.parties.isNotEmpty) {
      notifier.upsertByLabel('General', 'Client', original.parties,
          source: 'contract', confidence: 0.7);
    }
    // Search executed contract descriptions for street address
    for (final c in contracts) {
      final m = _streetRe.firstMatch(c.description);
      if (m != null) { contractAddress = m.group(1)!.trim(); break; }
    }
  }

  // Also search ALL contract folder files (Fee Worksheets, Executed, etc.)
  // for address patterns in filenames — fee worksheets often contain the address.
  if (contractAddress.isEmpty) {
    try {
      final svc = FolderScanService(projectPath);
      final allContractFiles = await svc.listContractFolderFiles();
      for (final filename in allContractFiles) {
        final m = _streetRe.firstMatch(filename);
        if (m != null) { contractAddress = m.group(1)!.trim(); break; }
      }
    } catch (_) {}
  }

  // ── Address & geocoding ──
  // Priority: PDF data > contract filename > current stored address
  final currentInfo = ref.read(projectInfoProvider);
  final curAddr = currentInfo.where((e) => e.label == 'Project Address')
      .map((e) => e.value).firstOrNull ?? '';
  final curLat = currentInfo.where((e) => e.label == 'Latitude')
      .map((e) => double.tryParse(e.value) ?? 0).firstOrNull ?? 0.0;

  // Build the best address for geocoding
  String bestAddress = pdfAddress.isNotEmpty ? pdfAddress : contractAddress;
  if (bestAddress.isEmpty) bestAddress = curAddr;

  // If we got city/state from PDF, build a geocode query with them
  String geocodeQuery = bestAddress;
  if (pdfCity.isNotEmpty || pdfState.isNotEmpty) {
    final cityState = [pdfCity, pdfState].where((s) => s.isNotEmpty).join(', ');
    if (geocodeQuery.isNotEmpty && !geocodeQuery.toLowerCase().contains(pdfCity.toLowerCase())) {
      geocodeQuery = '$geocodeQuery, $cityState';
    } else if (geocodeQuery.isEmpty) {
      geocodeQuery = cityState;
    }
  }

  // Fallback: use project name for geocoding if nothing else
  if (geocodeQuery.isEmpty && projectName.isNotEmpty) {
    geocodeQuery = projectName;
  }

  // Store best address if better than what we have
  if (bestAddress.isNotEmpty && bestAddress != curAddr) {
    notifier.upsertByLabel('General', 'Project Address', bestAddress,
        source: pdfAddress.isNotEmpty ? 'sheet' : 'contract', confidence: 0.7);
  }

  // Always geocode if: no coords, or address changed, or city doesn't match PDF
  bool needsGeocode = curLat == 0 || (bestAddress.isNotEmpty && bestAddress != curAddr);
  if (pdfCity.isNotEmpty) {
    final curCity = currentInfo.where((e) => e.label == 'City')
        .map((e) => e.value).firstOrNull ?? '';
    if (!curCity.toLowerCase().contains(pdfCity.toLowerCase())) {
      needsGeocode = true;
    }
  }

  String geocodedState = pdfState;
  if (geocodeQuery.isNotEmpty && needsGeocode) {
    final loc = await lookupAddressLocation(geocodeQuery);
    if (loc != null) {
      final cityName = pdfCity.isNotEmpty ? pdfCity : loc.city;
      final stateName = pdfState.isNotEmpty ? pdfState : loc.state;
      if (pdfCity.isEmpty) {
        notifier.upsertByLabel('Site', 'City', '$cityName, $stateName',
            source: 'city', confidence: 0.85);
      }
      notifier.upsertByLabel('Site', 'County', loc.county,
          source: 'city', confidence: 0.85);
      if (loc.lat != 0) notifier.upsertByLabel('Site', 'Latitude', loc.lat.toStringAsFixed(6),
          source: 'city', confidence: 0.9);
      if (loc.lon != 0) notifier.upsertByLabel('Site', 'Longitude', loc.lon.toStringAsFixed(6),
          source: 'city', confidence: 0.9);
      geocodedState = stateName;
      if (bestAddress.isEmpty && loc.displayName.isNotEmpty) {
        notifier.upsertByLabel('General', 'Project Address', loc.displayName,
            source: 'city', confidence: 0.6);
      }
    }
  } else if (geocodedState.isEmpty) {
    final cityVal = currentInfo.where((e) => e.label == 'City')
        .map((e) => e.value).firstOrNull ?? '';
    final parts = cityVal.split(',');
    if (parts.length >= 2) geocodedState = parts.last.trim();
  }

  // ── Spreadsheet enrichment ──
  // Already fetched in parallel above as `spreadsheets`
  try {
    if (spreadsheets.isNotEmpty) {
      await Future.microtask(() {});
      for (final file in spreadsheets) {
        List<(String, String, String)> discovered;
        final ext = file.extension.toLowerCase();
        if (ext == '.csv') {
          discovered = SpreadsheetParserService.parseCsv(file.fullPath);
        } else {
          discovered = SpreadsheetParserService.parseXlsx(file.fullPath);
        }
        for (final (category, label, value) in discovered) {
          notifier.upsertByLabel(category, label, value,
              source: 'sheet', confidence: 0.85);
        }
      }
    }
  } catch (_) {
    // Spreadsheet parsing is best-effort
  }

  // ── Code inference from state (baseline — low confidence) ──
  if (geocodedState.isNotEmpty) {
    await Future.microtask(() {});
    final codes = CodeLookupService.inferCodesForState(geocodedState);
    for (final (label, value, confidence) in codes) {
      notifier.upsertByLabel('Codes & Standards', label, value,
          source: 'inferred', confidence: confidence);
    }
  }

  // ── Codes & Standards from G-series sheets (high confidence — overrides inferred) ──
  // Already fetched in parallel above as `gCodes`
  try {
    await Future.microtask(() {});
    for (final entry in gCodes.entries) {
      // Map certain keys to General category
      if (entry.key == 'Construction Type' || entry.key == 'Occupancy Classification' ||
          entry.key == 'Sprinklered' || entry.key == 'Allowable Area' ||
          entry.key == 'Allowable Stories' || entry.key == 'Allowable Height' ||
          entry.key == 'Mixed Use' || entry.key == 'Fire Alarm System') {
        notifier.upsertByLabel('Codes & Standards', entry.key, entry.value,
            source: 'sheet', confidence: 0.95);
      } else if (entry.key == 'Building Area') {
        notifier.upsertByLabel('General', 'Building Area (SF)', entry.value,
            source: 'sheet', confidence: 0.95);
      } else if (entry.key == 'Number of Stories') {
        notifier.upsertByLabel('General', entry.key, entry.value,
            source: 'sheet', confidence: 0.95);
      } else {
        // All code references go to Codes & Standards
        notifier.upsertByLabel('Codes & Standards', entry.key, entry.value,
            source: 'sheet', confidence: 0.95);
      }
    }
  } catch (_) {
    // G-series code extraction is best-effort
  }

  // ── Jurisdiction enrichment (AHJ, permits, zoning) ──
  final cityVal = ref.read(projectInfoProvider)
      .where((e) => e.label == 'City')
      .map((e) => e.value)
      .firstOrNull ?? '';
  if (cityVal.isNotEmpty) {
    await Future.microtask(() {});
    final parts = cityVal.split(',');
    final city = parts.first.trim();
    final st = parts.length >= 2 ? parts.last.trim() : geocodedState;
    if (city.isNotEmpty && st.isNotEmpty) {
      try {
        final jur = JurisdictionEnricher.enrich(city, st);
        for (final entry in jur) {
          notifier.upsertByLabel(entry.category, entry.label, entry.value,
              source: 'inferred', confidence: entry.confidence);
        }
      } catch (_) {
        // Jurisdiction enrichment is best-effort
      }
    }
  }
});

/// Backward-compatible alias for existing references.
final autoPopulateProjectInfoProvider = enrichProjectInfoProvider;

// ═══════════════════════════════════════════════════════════
// ZONING LOOKUP — fetch zoning/municipality info from address
// ═══════════════════════════════════════════════════════════

/// Geocode result from Nominatim.
class GeocodedLocation {
  final String city;
  final String county;
  final String state;
  final String country;
  final double lat;
  final double lon;
  final String displayName;

  const GeocodedLocation({
    required this.city,
    required this.county,
    required this.state,
    required this.country,
    required this.lat,
    required this.lon,
    this.displayName = '',
  });
}

/// Looks up location info for the project address using Nominatim (OpenStreetMap).
/// Returns null if the address can't be geocoded.
Future<GeocodedLocation?> lookupAddressLocation(String address) async {
  if (address.isEmpty) return null;
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'json',
      'addressdetails': '1',
      'limit': '1',
    });
    final response = await http.get(uri, headers: {
      'User-Agent': 'ProjectCommandCenter/1.0',
    });
    if (response.statusCode != 200) return null;
    final results = jsonDecode(response.body) as List;
    if (results.isEmpty) return null;
    final first = results[0] as Map<String, dynamic>;
    final addr = first['address'] as Map<String, dynamic>? ?? {};
    return GeocodedLocation(
      city: addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? '',
      county: addr['county'] ?? '',
      state: addr['state'] ?? '',
      country: addr['country'] ?? '',
      lat: double.tryParse(first['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(first['lon']?.toString() ?? '') ?? 0,
      displayName: first['display_name']?.toString() ?? '',
    );
  } catch (_) {
    return null;
  }
}

// ═══════════════════════════════════════════════════════════
// SCAN STATUS — tracks whether a scan is running & last scan time
// ═══════════════════════════════════════════════════════════

class ScanStatus {
  final bool isScanning;
  final DateTime? lastScanTime;
  final int filesFound;

  const ScanStatus({this.isScanning = false, this.lastScanTime, this.filesFound = 0});

  ScanStatus copyWith({bool? isScanning, DateTime? lastScanTime, int? filesFound}) =>
      ScanStatus(
        isScanning: isScanning ?? this.isScanning,
        lastScanTime: lastScanTime ?? this.lastScanTime,
        filesFound: filesFound ?? this.filesFound,
      );
}

class ScanStatusNotifier extends StateNotifier<ScanStatus> {
  ScanStatusNotifier() : super(const ScanStatus());

  void startScan() => state = state.copyWith(isScanning: true);

  void completeScan(int filesFound) => state = ScanStatus(
    isScanning: false,
    lastScanTime: DateTime.now(),
    filesFound: filesFound,
  );
}

final scanStatusProvider = StateNotifierProvider<ScanStatusNotifier, ScanStatus>((ref) {
  return ScanStatusNotifier();
});

// ═══════════════════════════════════════════════════════════
// WEATHER — OpenMeteo free API (no key required)
// ═══════════════════════════════════════════════════════════

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final String time;
  const WeatherData({required this.temperature, required this.weatherCode, required this.windSpeed, required this.time});

  String get iconLabel => switch (weatherCode) {
    0 => 'Clear',
    1 || 2 => 'Partly Cloudy',
    3 => 'Overcast',
    45 || 48 => 'Fog',
    51 || 53 || 55 => 'Drizzle',
    61 || 63 || 65 => 'Rain',
    66 || 67 => 'Freezing Rain',
    71 || 73 || 75 || 77 => 'Snow',
    80 || 81 || 82 => 'Showers',
    85 || 86 => 'Snow Showers',
    95 || 96 || 99 => 'Thunderstorm',
    _ => 'Unknown',
  };
}

// In-memory weather cache — survives provider invalidation for 30 minutes
WeatherData? _cachedWeather;
DateTime? _weatherCacheTime;

final weatherProvider = FutureProvider<WeatherData?>((ref) async {
  // Return cached weather if less than 30 minutes old
  if (_cachedWeather != null && _weatherCacheTime != null) {
    if (DateTime.now().difference(_weatherCacheTime!).inMinutes < 30) {
      return _cachedWeather;
    }
  }

  // Primary: use IP-based geolocation for the user's actual location
  double lat = 0, lng = 0;
  try {
    final geoResp = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 5));
    if (geoResp.statusCode == 200) {
      final geoJson = jsonDecode(geoResp.body);
      lat = (geoJson['latitude'] as num?)?.toDouble() ?? 0;
      lng = (geoJson['longitude'] as num?)?.toDouble() ?? 0;
    }
  } catch (_) {}

  // Fallback: use project location if IP geolocation failed
  if (lat == 0 && lng == 0) {
    final info = ref.watch(projectInfoProvider);
    for (final e in info) {
      if (e.label == 'Latitude') lat = double.tryParse(e.value) ?? 0;
      if (e.label == 'Longitude') lng = double.tryParse(e.value) ?? 0;
    }
  }

  if (lat == 0 && lng == 0) return _cachedWeather; // return stale rather than null
  try {
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true&temperature_unit=fahrenheit');
    final resp = await http.get(url).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return _cachedWeather;
    final json = jsonDecode(resp.body);
    final cw = json['current_weather'];
    final result = WeatherData(
      temperature: (cw['temperature'] as num).toDouble(),
      weatherCode: cw['weathercode'] as int,
      windSpeed: (cw['windspeed'] as num).toDouble(),
      time: cw['time'] as String,
    );
    _cachedWeather = result;
    _weatherCacheTime = DateTime.now();
    return result;
  } catch (_) {
    return _cachedWeather;
  }
});

// Force-invalidate all keepAlive scan providers on project switch.
void invalidateAllScanProviders(WidgetRef ref) {
  ref.invalidate(_allDrawingsProvider);
  ref.invalidate(sheetIndexProvider);
  ref.invalidate(fullSetProvider);
  ref.invalidate(sheetValidationProvider);
  ref.invalidate(scannedGeneralProvider);
  ref.invalidate(scannedStructuralProvider);
  ref.invalidate(scannedArchitecturalProvider);
  ref.invalidate(scannedCivilProvider);
  ref.invalidate(scannedLandscapeProvider);
  ref.invalidate(scannedMechanicalProvider);
  ref.invalidate(scannedElectricalProvider);
  ref.invalidate(scannedPlumbingProvider);
  ref.invalidate(scannedFireProtectionProvider);
  ref.invalidate(scannedRfiPdfsProvider);
  ref.invalidate(scannedAsiPdfsProvider);
  ref.invalidate(scannedAddendumPdfsProvider);
  ref.invalidate(addendumBySheetProvider);
  ref.invalidate(rfiBySheetProvider);
  ref.invalidate(asiBySheetProvider);
  ref.invalidate(drawingMetadataProvider);
  ref.invalidate(metaGeneralProvider);
  ref.invalidate(metaStructuralProvider);
  ref.invalidate(metaArchitecturalProvider);
  ref.invalidate(metaCivilProvider);
  ref.invalidate(metaLandscapeProvider);
  ref.invalidate(metaMechanicalProvider);
  ref.invalidate(metaElectricalProvider);
  ref.invalidate(metaPlumbingProvider);
  ref.invalidate(metaFireProtectionProvider);
  ref.invalidate(scannedRfisProvider);
  ref.invalidate(scannedAsisProvider);
  ref.invalidate(scannedChangeOrdersProvider);
  ref.invalidate(scannedSubmittalsProvider);
  ref.invalidate(scannedPunchlistsProvider);
  ref.invalidate(scannedClientProvidedProvider);
  ref.invalidate(scannedPhotosProvider);
  ref.invalidate(scannedProjectInfoProvider);
  ref.invalidate(scannedContractsProvider);
  ref.invalidate(scannedScheduleProvider);
  ref.invalidate(scannedBudgetProvider);
  ref.invalidate(scannedProgressPrintsProvider);
  ref.invalidate(scannedSignedPrintsProvider);
  ref.invalidate(scannedSpecsProvider);
  ref.invalidate(scannedRenderingsProvider);
  ref.invalidate(scannedContractDocsProvider);
  ref.invalidate(scannedSiteDocsProvider);
  ref.invalidate(scannedProgrammingProvider);
  ref.invalidate(discoveredMilestonesProvider);
  ref.invalidate(phaseFileDatesProvider);
  ref.invalidate(contractMetadataProvider);
  ref.invalidate(feeWorksheetsProvider);
  ref.invalidate(infoFormsProvider);
  ref.invalidate(scannedContactsProvider);
  ref.invalidate(scannedSpreadsheetsProvider);
  ref.invalidate(projectDataSheetProvider);
  ref.invalidate(gSeriesCodesProvider);
  ref.invalidate(enrichProjectInfoProvider);
  ref.invalidate(weatherProvider);
  ref.invalidate(rootAccessibleProvider);
  ref.invalidate(scannedFeeWorksheetsProvider);
  ref.invalidate(latestSheetIndexPdfProvider);
  ref.invalidate(closeoutDocumentsProvider);
  ref.invalidate(allProjectFilesProvider);
}
