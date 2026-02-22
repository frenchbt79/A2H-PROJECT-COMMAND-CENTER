import '../models/drawing_metadata.dart';
import '../models/scanned_file.dart';
import 'folder_scan_service.dart';
import 'sheet_name_parser.dart';

/// Pure enrichment service — no state, no I/O.
/// Takes raw scanned files + cross-reference maps and produces structured
/// [DrawingMetadata] records.
class DrawingMetadataService {
  DrawingMetadataService._();

  /// Prefix → full discipline name.
  static const _prefixToName = <String, String>{
    'G': 'General',
    'S': 'Structural',
    'A': 'Architectural',
    'C': 'Civil',
    'L': 'Landscape',
    'M': 'Mechanical',
    'E': 'Electrical',
    'P': 'Plumbing',
    'FP': 'Fire Protection',
  };

  /// Enrich a list of scanned files into structured metadata.
  ///
  /// [files] — raw scanned PDFs from Scanned Drawings.
  /// [addMap], [rfiMap], [asiMap] — cross-reference indexes by normalized sheet key.
  /// [phaseActivity] — per-phase date ranges for phase inference.
  static List<DrawingMetadata> enrich({
    required List<ScannedFile> files,
    required Map<String, List<ScannedFile>> addMap,
    required Map<String, List<ScannedFile>> rfiMap,
    required Map<String, List<ScannedFile>> asiMap,
    Map<String, PhaseFileActivity>? phaseActivity,
  }) {
    // 1. Parse all files and detect duplicates
    final parsed = <int, SheetInfo>{};
    final sheetCount = <String, int>{};
    for (int i = 0; i < files.length; i++) {
      final info = SheetNameParser.parse(files[i].name);
      parsed[i] = info;
      if (info.valid) {
        final key = info.sheetNumber.toLowerCase();
        sheetCount[key] = (sheetCount[key] ?? 0) + 1;
      }
    }

    // 2. Build metadata for each file
    final results = <DrawingMetadata>[];
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final info = parsed[i]!;
      final sheetKey = FolderScanService.sheetNumber(f.name);
      final addFiles = addMap[sheetKey] ?? [];
      final rfiFiles = rfiMap[sheetKey] ?? [];
      final asiFiles = asiMap[sheetKey] ?? [];
      final isDuplicate = info.valid &&
          (sheetCount[info.sheetNumber.toLowerCase()] ?? 0) > 1;

      // Phase inference
      final phaseResult = _inferPhase(f, phaseActivity);

      // Issue date: use file modified date
      final issueDate = f.modified;

      results.add(DrawingMetadata(
        file: f,
        disciplinePrefix: info.valid ? info.prefix : '',
        discipline: info.valid ? (_prefixToName[info.prefix] ?? info.prefix) : '',
        sheetNumber: info.valid ? info.sheetNumber : f.name,
        sheetKey: sheetKey,
        revisionLabel: info.revision,
        parseValid: info.valid,
        phase: phaseResult.$1,
        phaseSource: phaseResult.$2,
        addendumCount: addFiles.length,
        rfiCount: rfiFiles.length,
        asiCount: asiFiles.length,
        latestAddLabel: bestLabel(f.name, addFiles, FolderScanService.extractAddendumNumber),
        latestRfiLabel: bestLabel(f.name, rfiFiles, FolderScanService.extractRfiNumber),
        latestAsiLabel: bestLabel(f.name, asiFiles, FolderScanService.extractAsiNumber),
        addFiles: addFiles,
        rfiFiles: rfiFiles,
        asiFiles: asiFiles,
        hasDuplicate: isDuplicate,
        issueDate: issueDate,
      ));
    }

    return results;
  }

  /// Extract the best label for a type from the drawing filename + cross-ref files.
  /// Priority: drawing filename first, then highest number from cross-ref files.
  static String bestLabel(
    String drawingName,
    List<ScannedFile> crossRefFiles,
    String? Function(String) extractor,
  ) {
    // 1. Check the drawing filename itself
    final fromDrawing = extractor(drawingName);
    if (fromDrawing != null) return fromDrawing;
    // 2. Check cross-referenced files — try name first, then path
    String? best;
    for (final f in crossRefFiles) {
      final label = extractor(f.name) ?? extractor(f.fullPath);
      if (label != null) {
        if (best == null || label.compareTo(best) > 0) best = label;
      }
    }
    return best ?? '';
  }

  /// Infer phase from folder path keywords, then fall back to date ranges.
  /// Returns (phase, source) tuple.
  static (String, String) _inferPhase(
    ScannedFile file,
    Map<String, PhaseFileActivity>? phaseActivity,
  ) {
    final pathLower = file.relativePath.toLowerCase();

    // Check folder path for phase keywords
    if (pathLower.contains('schematic design') || pathLower.contains(r'\sd\') || pathLower.contains('/sd/')) {
      return ('SD', 'folder');
    }
    if (pathLower.contains('design development') || pathLower.contains(r'\dd\') || pathLower.contains('/dd/')) {
      return ('DD', 'folder');
    }
    if (pathLower.contains('construction document') || pathLower.contains(r'\cd\') || pathLower.contains('/cd/')) {
      return ('CD', 'folder');
    }
    if (pathLower.contains('construction admin') || pathLower.contains(r'\ca\') || pathLower.contains('/ca/')) {
      return ('CA', 'folder');
    }

    // Fall back to date-based phase matching
    if (phaseActivity != null && phaseActivity.isNotEmpty) {
      final fileDate = file.modified;
      // Check phases in reverse order (CA > CD > DD > SD) — latest phase wins
      for (final phaseName in ['CA', 'CD', 'DD', 'SD']) {
        final activity = phaseActivity[phaseName];
        if (activity != null) {
          if (!fileDate.isBefore(activity.earliestFile) &&
              !fileDate.isAfter(activity.latestFile.add(const Duration(days: 30)))) {
            return (phaseName, 'date');
          }
        }
      }
    }

    return ('', '');
  }

  /// Filter metadata to a specific discipline prefix and keep latest per sheet.
  static List<DrawingMetadata> filterByPrefix(
    List<DrawingMetadata> all,
    String prefix,
  ) {
    final upperPrefix = prefix.toUpperCase();
    final matching = all.where((m) =>
      m.parseValid && m.disciplinePrefix == upperPrefix,
    ).toList();

    // Keep only latest per sheetKey
    final latest = <String, DrawingMetadata>{};
    for (final m in matching) {
      final existing = latest[m.sheetKey];
      if (existing == null || m.issueDate.isAfter(existing.issueDate)) {
        latest[m.sheetKey] = m;
      }
    }
    return latest.values.toList();
  }
}