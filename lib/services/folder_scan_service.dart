import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import '../models/scanned_file.dart';

/// Scans project folders on disk and returns file metadata.
/// Only works on desktop (Windows). Returns empty lists on web.
class FolderScanService {
  final String basePath;

  FolderScanService(this.basePath);

  /// Cached root accessibility check — avoids repeated network I/O per provider.
  bool? _rootAccessibleCache;

  /// Returns true if the project root folder (basePath) exists and is accessible.
  /// Times out after 4 seconds to prevent UI lock when network drives are offline.
  Future<bool> isRootAccessible() async {
    if (_rootAccessibleCache != null) return _rootAccessibleCache!;
    if (kIsWeb || basePath.isEmpty) {
      _rootAccessibleCache = false;
      return false;
    }
    try {
      final exists = await Directory(basePath).exists().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[SCAN] isRootAccessible TIMEOUT — drive likely offline');
          return false;
        },
      );
      _rootAccessibleCache = exists;
      return exists;
    } catch (e) {
      debugPrint('[SCAN] isRootAccessible ERROR: $e');
      _rootAccessibleCache = false;
      return false;
    }
  }

  /// Normalised root path (lowercase, forward slashes) for boundary checks.
  late final String _normalRoot = basePath.toLowerCase().replaceAll('\\', '/');

  /// Returns true if [absolutePath] is inside the project root.
  /// Prevents scanning from escaping the project folder via `..` paths.
  bool _isWithinRoot(String absolutePath) {
    final norm = absolutePath.toLowerCase().replaceAll('\\', '/');
    return norm.startsWith(_normalRoot);
  }

  /// Verifies a relative path against basePath and checks it stays within root.
  /// Returns null if the directory doesn't exist or the path escapes the root.
  Future<Directory?> _resolveDir(String relativePath) async {
    // Reject any relative path containing ".." to prevent directory traversal
    if (relativePath.contains('..')) {
      debugPrint('[SCAN] BLOCKED: "$relativePath" contains ".."');
      return null;
    }
    final dir = Directory('$basePath\\$relativePath');
    if (!await dir.exists()) return null;
    if (!_isWithinRoot(dir.path)) {
      debugPrint('[SCAN] BLOCKED: "${dir.path}" is outside root "$basePath"');
      return null;
    }
    return dir;
  }

  /// OS and editor resource files to always exclude from scan results.
  static const _ignoredFiles = {
    'desktop.ini',
    '.ds_store',
    '.thumbs',
    'thumbs.db',
    '.spotlight-v100',
    '.trashes',
    '.fseventsd',
    '.temporaryitems',
    'icon\r',
    '~\$',
  };

  /// File extensions to always exclude from scan results.
  static const _ignoredExtensions = {
    '.zip', '.rar', '.7z', '.tar', '.gz',
    '.dwg', '.dxf',
    '.sqlite', '.mdb',
  };

  /// Returns true if [filename] matches [prefix] as a valid drawing sheet.
  /// Requires the format: PREFIX + DIGIT(s) + SEPARATOR(. or -) + DIGIT(s)
  /// Examples that PASS:  A1.01, A1-02, FP1.1, C2.0, E1-0
  /// Examples that FAIL:  A02 (no separator), A2 (no separator),
  ///                      ADA (letters after prefix), AS1.00 (wrong prefix for 'a')
  static bool matchesSheetPrefix(String filename, String prefix) {
    final lower = filename.toLowerCase();
    final p = prefix.toLowerCase();
    if (!lower.startsWith(p)) return false;
    // After the prefix, require: digit(s) then a dot or dash then digit(s)
    final rest = lower.substring(p.length);
    return RegExp(r'^\d+[.\-]\d').hasMatch(rest);
  }

  /// Returns true if the filename should be excluded from scan results.
  static bool _isIgnored(String filename) {
    final lower = filename.toLowerCase();
    if (_ignoredFiles.contains(lower)) return true;
    // Skip hidden files (starting with .)
    if (lower.startsWith('.')) return true;
    // Skip Office temp files (~$...)
    if (lower.startsWith('~\$')) return true;
    // Skip excluded extensions
    final dotIdx = lower.lastIndexOf('.');
    if (dotIdx >= 0 && _ignoredExtensions.contains(lower.substring(dotIdx))) return true;
    return false;
  }

  /// Scan a subfolder relative to basePath, returning files matching [extensions].
  /// If [extensions] is empty, returns all files.
  /// If [latestPerSheet] is true, groups files by sheet number and keeps only
  /// the most recently modified file per sheet (e.g. only one A1.01).
  Future<List<ScannedFile>> scanFolder(
    String relativePath, {
    List<String> extensions = const [],
    String? nameContains,
    String? nameStartsWith,
    bool latestPerSheet = false,
  }) async {
    if (kIsWeb || basePath.isEmpty) return [];
    try {
      if (!await isRootAccessible()) return [];
      final dir = await _resolveDir(relativePath);
      if (dir == null) return [];

      final files = <ScannedFile>[];
      await for (final entity in dir.list(recursive: false)) {
        if (entity is! File) continue;
        if (!_isWithinRoot(entity.path)) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        final ext = _extension(name);

        // Extension filter
        if (extensions.isNotEmpty && !extensions.contains(ext.toLowerCase())) continue;

        // Name-contains filter (case-insensitive)
        if (nameContains != null && !name.toLowerCase().contains(nameContains.toLowerCase())) continue;

        // Name-starts-with filter — strict sheet prefix (e.g. 'a' matches A1.01 but not AS1.00)
        if (nameStartsWith != null && !matchesSheetPrefix(name, nameStartsWith)) continue;

        final stat = await entity.stat();
        files.add(ScannedFile(
          name: name,
          fullPath: entity.path,
          relativePath: '$relativePath\\$name',
          sizeBytes: stat.size,
          modified: stat.modified,
          extension: ext,
        ));
      }

      final result = latestPerSheet ? keepLatestPerSheet(files) : files;
      result.sort((a, b) => b.modified.compareTo(a.modified));
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Extract a sheet number from a filename like "A1.01-FLOOR PLAN.pdf" → "a1.01"
  /// or "E0-0 - ELECTRICAL LEGEND.pdf" → "e0-0".
  /// Returns the leading alphanumeric+dot+dash token before the first space or
  /// description separator. Returns lowercase for grouping.
  ///
  /// Normalizes dash-separated and dot-separated sheet numbers so that
  /// "A1-1" and "A1.1" and "A1.01" all map to the same canonical form "a1.01".
  /// Extract the raw (unmodified) sheet number from a filename, preserving
  /// the original casing, separators, and digit formatting exactly as written.
  /// Returns the matched portion or the full base name if no pattern matches.
  static String rawSheetNumber(String filename) {
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    final match = RegExp(r'^([A-Za-z]{1,3}\d+[.\-][\d.\-]*\d[A-Za-z]?)').firstMatch(base);
    return match != null ? match.group(1)! : base;
  }

  static String sheetNumber(String filename) {
    // Remove extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    // Match sheet number: letter(s) + digit(s) + separator(. or -) + more digits/dots/dashes + optional letter suffix
    // Examples: A1.01, A1-02B, C3.0, FP1-1A, E0-0, G0.1, S1-0
    // Does NOT match: A02, A2, ADA (no separator between prefix and remaining digits)
    final match = RegExp(r'^([A-Za-z]{1,3}\d+[.\-][\d.\-]*\d[A-Za-z]?)').firstMatch(base);
    if (match == null) return base.toLowerCase();

    final raw = match.group(1)!.toLowerCase();

    // Normalize: convert dashes to dots for consistent grouping
    // Split into prefix letters and the rest
    final prefixMatch = RegExp(r'^([a-z]+)(.*)$').firstMatch(raw);
    if (prefixMatch == null) return raw;

    final prefix = prefixMatch.group(1)!; // e.g. "a", "fp", "as"
    var rest = prefixMatch.group(2)!;       // e.g. "1-02b", "1.02b", "1.01"

    // Replace dashes with dots as separators
    rest = rest.replaceAll('-', '.');

    // Split on dots and normalize each numeric segment (pad to 2 digits)
    final segments = rest.split('.');
    final normalized = segments.map((s) {
      // If it's a pure number, pad to 2 digits for consistent comparison
      if (RegExp(r'^\d+$').hasMatch(s)) {
        return s.padLeft(2, '0');
      }
      // If it starts with digits followed by a letter suffix, pad the number part
      final numSuffix = RegExp(r'^(\d+)([a-z]+)$').firstMatch(s);
      if (numSuffix != null) {
        return '${numSuffix.group(1)!.padLeft(2, '0')}${numSuffix.group(2)!}';
      }
      return s;
    }).join('.');

    return '$prefix$normalized';
  }

  /// From a list of files, keep only the newest (by modified date) per sheet number.
  static List<ScannedFile> keepLatestPerSheet(List<ScannedFile> files) {
    final map = <String, ScannedFile>{};
    for (final f in files) {
      final sheet = sheetNumber(f.name);
      final existing = map[sheet];
      if (existing == null || f.modified.isAfter(existing.modified)) {
        map[sheet] = f;
      }
    }
    return map.values.toList();
  }

  /// Scan a folder recursively, returning files matching filters.
  /// If [latestPerSheet] is true, groups files by sheet number and keeps only
  /// the most recently modified file per sheet.
  Future<List<ScannedFile>> scanFolderRecursive(
    String relativePath, {
    List<String> extensions = const [],
    String? nameContains,
    String? nameStartsWith,
    bool latestPerSheet = false,
  }) async {
    debugPrint('[SCAN] scanFolderRecursive called: basePath="$basePath" rel="$relativePath" ext=$extensions startsWith=$nameStartsWith latestPerSheet=$latestPerSheet kIsWeb=$kIsWeb');
    if (kIsWeb || basePath.isEmpty) {
      debugPrint('[SCAN] SKIPPED: kIsWeb=$kIsWeb basePath.isEmpty=${basePath.isEmpty}');
      return [];
    }
    try {
      final rootOk = await isRootAccessible();
      debugPrint('[SCAN] root accessible: $rootOk');
      if (!rootOk) return [];
      final dir = await _resolveDir(relativePath);
      debugPrint('[SCAN] dir resolved: ${dir?.path}');
      if (dir == null) return [];

      final files = <ScannedFile>[];
      final stripPrefix = '$basePath\\';
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        if (!_isWithinRoot(entity.path)) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        final ext = _extension(name);

        if (extensions.isNotEmpty && !extensions.contains(ext.toLowerCase())) continue;
        if (nameContains != null && !name.toLowerCase().contains(nameContains.toLowerCase())) continue;
        if (nameStartsWith != null && !matchesSheetPrefix(name, nameStartsWith)) continue;

        final stat = await entity.stat();
        final rel = entity.path.startsWith(stripPrefix)
            ? entity.path.substring(stripPrefix.length)
            : '$relativePath\\$name';
        files.add(ScannedFile(
          name: name,
          fullPath: entity.path,
          relativePath: rel,
          sizeBytes: stat.size,
          modified: stat.modified,
          extension: ext,
        ));
      }
      final result = latestPerSheet ? keepLatestPerSheet(files) : files;
      result.sort((a, b) => b.modified.compareTo(a.modified));
      debugPrint('[SCAN] DONE: found ${files.length} raw → ${result.length} after dedup');
      return result;
    } catch (e, stack) {
      debugPrint('[SCAN] ERROR: $e\n$stack');
      return [];
    }
  }

  /// Quick scan to count all non-ignored files in the project folder.
  Future<int> countAllFiles() async {
    if (kIsWeb || basePath.isEmpty) return 0;
    try {
      if (!await isRootAccessible()) return 0;
      final dir = Directory(basePath);
      int count = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Check how many files have been added or modified since [since].
  /// Returns a record of (newOrModified, totalFiles).
  Future<({int changed, int total})> countChangedSince(DateTime since) async {
    if (kIsWeb || basePath.isEmpty) return (changed: 0, total: 0);
    try {
      if (!await isRootAccessible()) return (changed: 0, total: 0);
      final dir = Directory(basePath);
      int total = 0;
      int changed = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        total++;
        final stat = await entity.stat();
        if (stat.modified.isAfter(since)) changed++;
      }
      return (changed: changed, total: total);
    } catch (_) {
      return (changed: 0, total: 0);
    }
  }

  /// Scan multiple folders and combine results.
  Future<List<ScannedFile>> scanMultipleFolders(
    List<String> relativePaths, {
    List<String> extensions = const [],
  }) async {
    final results = <ScannedFile>[];
    for (final path in relativePaths) {
      results.addAll(await scanFolder(path, extensions: extensions));
    }
    results.sort((a, b) => b.modified.compareTo(a.modified));
    return results;
  }

  /// Scan entire project for files whose name matches keywords (case-insensitive).
  Future<List<ScannedFile>> scanByKeywords(List<String> keywords) async {
    if (kIsWeb || basePath.isEmpty) return [];
    try {
      if (!await isRootAccessible()) return [];
      final dir = Directory(basePath);

      final files = <ScannedFile>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final rawName = entity.uri.pathSegments.last;
        if (_isIgnored(rawName)) continue;
        final name = rawName.toLowerCase();
        final matches = keywords.any((kw) => name.contains(kw.toLowerCase()));
        if (!matches) continue;

        final ext = _extension(rawName);
        final stat = await entity.stat();
        final rel = entity.path.replaceFirst('$basePath\\', '');
        files.add(ScannedFile(
          name: rawName,
          fullPath: entity.path,
          relativePath: rel,
          sizeBytes: stat.size,
          modified: stat.modified,
          extension: ext,
        ));
      }
      files.sort((a, b) => b.modified.compareTo(a.modified));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Check if a folder exists and is accessible.
  Future<bool> isFolderAccessible(String relativePath) async {
    if (kIsWeb || basePath.isEmpty) return false;
    try {
      return await Directory('$basePath\\$relativePath').exists();
    } catch (_) {
      return false;
    }
  }

  /// Open a file with the default system application.
  static Future<void> openFile(String fullPath) async {
    if (kIsWeb) return;
    // Windows: use 'start' command to open with default app
    await Process.run('cmd', ['/c', 'start', '', fullPath]);
  }

  /// Open the containing folder in Windows Explorer and select the file.
  static Future<void> openContainingFolder(String fullPath) async {
    if (kIsWeb) return;
    await Process.run('explorer', ['/select,', fullPath]);
  }

  /// Copy a file from [sourcePath] into [relativePath] under the project folder,
  /// renamed to [newName]. Creates the destination directory if needed.
  Future<File?> copyFileToProjectFolder({
    required String sourcePath,
    required String relativePath,
    required String newName,
  }) async {
    if (kIsWeb || basePath.isEmpty) return null;
    final destDir = Directory('$basePath\\$relativePath');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destPath = '${destDir.path}\\$newName';
    return File(sourcePath).copy(destPath);
  }

  /// Merge multiple PDF files into a single output PDF.
  /// Creates the output directory if it doesn't exist.
  /// Returns the output path on success, throws on failure.
  static Future<String> mergeAndSavePdfs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('PDF merging is not available on Web.');
    }
    if (inputPaths.isEmpty) {
      throw ArgumentError('No input files provided.');
    }

    // Ensure output directory exists
    final outDir = Directory(outputPath.substring(0, outputPath.lastIndexOf('\\')));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final inputs = inputPaths.map((p) => MergeInput.path(p)).toList();
    final result = await PdfCombiner.mergeMultiplePDFs(
      inputs: inputs,
      outputPath: outputPath,
    );
    debugPrint('[SCAN] Merged ${inputPaths.length} PDFs → $result');
    return result;
  }

  /// Scan subdirectories under Scanned Drawings (and key project folders) for
  /// milestone-like names. Returns a list of discovered milestones with dates
  /// derived from the most recent file in each matching folder.
  Future<List<DiscoveredMilestone>> scanForMilestones() async {
    if (kIsWeb || basePath.isEmpty) return [];
    if (!await isRootAccessible()) return [];

    final milestones = <DiscoveredMilestone>[];

    // Paths to check for milestone-named subfolders or files
    final scanPaths = [
      r'0 Project Management\Construction Documents\Scanned Drawings',
      r'0 Project Management\Construction Documents',
      r'0 Project Management\Construction Admin',
      r'0 Project Management\Contracts',
      r'0 Project Management',
      r'Common',
    ];

    // Known milestone patterns: keyword → friendly label
    // Ordered so more specific matches are checked first
    final patterns = <String, String>{
      'sd submittal': 'SD Submittal',
      'sd submit': 'SD Submittal',
      'schematic design': 'Schematic Design',
      'dd submittal': 'DD Submittal',
      'dd submit': 'DD Submittal',
      'design development': 'Design Development',
      'cd 50': 'CD 50% Submittal',
      '50% cd': 'CD 50% Submittal',
      '50%': 'CD 50% Submittal',
      '50 percent': 'CD 50% Submittal',
      'cd 90': 'CD 90% Submittal',
      '90% cd': 'CD 90% Submittal',
      '90%': 'CD 90% Submittal',
      'cd 100': 'CD 100% Submittal',
      '100% cd': 'CD 100% Submittal',
      '100%': 'CD 100% Submittal',
      'construction document': 'Construction Documents',
      'constr doc': 'Construction Documents',
      'permit set': 'Permit Submittal',
      'permit submittal': 'Permit Submittal',
      'permit app': 'Permit Application',
      'bid set': 'Bid Package',
      'bid package': 'Bid Package',
      'bid doc': 'Bid Package',
      'ifa set': 'Issued for Agency',
      'issued for agency': 'Issued for Agency',
      'ifc set': 'Issued for Construction',
      'issued for construction': 'Issued for Construction',
      'progress print': 'Progress Print Set',
      'progress set': 'Progress Print Set',
      'signed sealed': 'Signed & Sealed Set',
      'signed & sealed': 'Signed & Sealed Set',
      'signed set': 'Signed & Sealed Set',
      'addendum': 'Addendum Issued',
      'bulletin': 'Bulletin Issued',
      'notice to proceed': 'Notice to Proceed',
      'ntp': 'Notice to Proceed',
      'substantial completion': 'Substantial Completion',
      'punch list': 'Punchlist',
      'punchlist': 'Punchlist',
      'closeout': 'Project Closeout',
      'close-out': 'Project Closeout',
      'certificate of occupancy': 'Certificate of Occupancy',
    };

    final found = <String>{}; // Track found labels to avoid duplicates

    for (final scanPath in scanPaths) {
      try {
        final dir = Directory('$basePath\\$scanPath');
        if (!await dir.exists()) continue;

        // Check subdirectory names for milestone patterns
        await for (final entity in dir.list(recursive: false)) {
          if (entity is! Directory) continue;
          final folderName = entity.path.split('\\').last.toLowerCase();

          for (final entry in patterns.entries) {
            if (folderName.contains(entry.key) && !found.contains(entry.value)) {
              // Found a milestone folder — get date from newest file inside
              final date = await _newestFileDate(entity.path);
              if (date != null) {
                milestones.add(DiscoveredMilestone(
                  label: entry.value,
                  date: date,
                  source: entity.path.replaceFirst('$basePath\\', ''),
                  fileCount: await _countFiles(entity.path),
                ));
                found.add(entry.value);
              }
              break;
            }
          }
        }

        // Also check files directly in the folder for milestone-like names
        await for (final entity in dir.list(recursive: false)) {
          if (entity is! File) continue;
          final fileName = entity.uri.pathSegments.last.toLowerCase();

          for (final entry in patterns.entries) {
            if (fileName.contains(entry.key) && !found.contains(entry.value)) {
              final stat = await entity.stat();
              milestones.add(DiscoveredMilestone(
                label: entry.value,
                date: stat.modified,
                source: entity.path.replaceFirst('$basePath\\', ''),
                fileCount: 1,
              ));
              found.add(entry.value);
              break;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    milestones.sort((a, b) => a.date.compareTo(b.date));
    return milestones;
  }

  /// Scan known phase-related folders to discover actual file activity dates.
  /// Returns a map of phase label → PhaseFileActivity with earliest/latest file dates.
  Future<Map<String, PhaseFileActivity>> scanPhaseFileDates() async {
    if (kIsWeb || basePath.isEmpty) return {};
    if (!await isRootAccessible()) return {};

    // Map schedule phase names to folders that contain their deliverables
    final phaseToFolders = <String, List<String>>{
      'Schematic Design': [
        r'0 Project Management\Construction Documents\Scanned Drawings',
      ],
      'Design Development': [
        r'0 Project Management\Construction Documents\Scanned Drawings',
      ],
      'Construction Documents': [
        r'0 Project Management\Construction Documents\Scanned Drawings',
        r'0 Project Management\Construction Documents\Front End-Specs',
      ],
      'Permitting': [
        r'0 Project Management\Construction Admin',
      ],
      'Bidding & Negotiation': [
        r'0 Project Management\Contracts',
      ],
      'Construction Admin': [
        r'0 Project Management\Construction Admin\RFIs',
        r'0 Project Management\Construction Admin\ASIs',
        r'0 Project Management\Construction Admin\Change Orders',
        r'0 Project Management\Construction Admin\Submittals',
        r'0 Project Management\Construction Admin\Punchlist Documents',
      ],
    };

    final results = <String, PhaseFileActivity>{};

    for (final entry in phaseToFolders.entries) {
      DateTime? earliest;
      DateTime? latest;
      int fileCount = 0;

      for (final folder in entry.value) {
        try {
          final dir = Directory('$basePath\\$folder');
          if (!await dir.exists()) continue;

          await for (final entity in dir.list(recursive: true)) {
            if (entity is! File) continue;
            if (_isIgnored(entity.uri.pathSegments.last)) continue;
            final stat = await entity.stat();
            fileCount++;
            if (earliest == null || stat.modified.isBefore(earliest)) {
              earliest = stat.modified;
            }
            if (latest == null || stat.modified.isAfter(latest)) {
              latest = stat.modified;
            }
          }
        } catch (_) {
          continue;
        }
      }

      if (earliest != null && latest != null && fileCount > 0) {
        results[entry.key] = PhaseFileActivity(
          earliestFile: earliest,
          latestFile: latest,
          fileCount: fileCount,
        );
      }
    }

    return results;
  }

  /// Get the modification date of the newest file in a directory (recursive).
  Future<DateTime?> _newestFileDate(String dirPath) async {
    try {
      DateTime? newest;
      await for (final entity in Directory(dirPath).list(recursive: true)) {
        if (entity is! File) continue;
        if (_isIgnored(entity.uri.pathSegments.last)) continue;
        final stat = await entity.stat();
        if (newest == null || stat.modified.isAfter(newest)) {
          newest = stat.modified;
        }
      }
      return newest;
    } catch (_) {
      return null;
    }
  }

  /// Count files in a directory (recursive).
  Future<int> _countFiles(String dirPath) async {
    try {
      int count = 0;
      await for (final entity in Directory(dirPath).list(recursive: true)) {
        if (entity is! File) continue;
        if (_isIgnored(entity.uri.pathSegments.last)) continue;
        count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Try to extract a project name from the most recent contract PDF filename.
  /// Contract filenames typically follow:
  /// List all filenames in the Contracts folder tree (Fee Worksheets, Executed, etc.)
  /// Used for address extraction from filenames across all contract-related files.
  Future<List<String>> listContractFolderFiles() async {
    if (kIsWeb || basePath.isEmpty) return [];
    try {
      final contractsDir = Directory('$basePath\\0 Project Management\\Contracts');
      if (!await contractsDir.exists()) return [];
      final filenames = <String>[];
      await for (final entity in contractsDir.list(recursive: true)) {
        if (entity is! File) continue;
        filenames.add(entity.uri.pathSegments.last);
      }
      return filenames;
    } catch (_) {
      return [];
    }
  }

  /// `YYYY-MM-DD - NUMBER - CLIENT - FormNumber - Description (Status).pdf`
  /// or `YYYY-MM-DD - NUMBER - CLIENT - Description (Status).pdf`
  /// We look for the client/project description in the filename.
  Future<String?> extractProjectNameFromContracts() async {
    if (kIsWeb || basePath.isEmpty) return null;
    try {
      final contractsDir = Directory('$basePath\\0 Project Management\\Contracts');
      if (!await contractsDir.exists()) return null;

      // ── Priority 1: Fee Worksheets folder ──
      // Fee worksheet filenames often contain the project name directly:
      //   "2022-03-30 - 19201 TC Animal Shelter per Discipline.xlsx"
      // Scan most recent file first.
      final feeDir = Directory('${contractsDir.path}\\Fee Worksheets');
      if (await feeDir.exists()) {
        final feeFiles = <File>[];
        await for (final entity in feeDir.list(recursive: true)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last.toLowerCase();
          // Include all spreadsheet formats (xlsx, xls, csv, gsheet) and PDFs
          if (name.endsWith('.xlsx') ||
              name.endsWith('.xls') ||
              name.endsWith('.pdf') ||
              name.endsWith('.gsheet') ||
              name.endsWith('.csv') ||
              name.endsWith('.xlsm') ||
              name.endsWith('.ods')) {
            feeFiles.add(entity);
          }
        }
        if (feeFiles.isNotEmpty) {
          // Sort by modification time, newest first
          final stats = <File, DateTime>{};
          for (final f in feeFiles) {
            stats[f] = (await f.stat()).modified;
          }
          feeFiles.sort((a, b) => stats[b]!.compareTo(stats[a]!));

          // Try to extract project name from each fee file (newest first)
          for (final f in feeFiles) {
            final name = _parseProjectNameFromFeeWorksheet(f.uri.pathSegments.last);
            if (name != null) return name;
          }
        }
      }

      // ── Priority 2: Contract filenames ──
      final candidates = <File>[];
      await for (final entity in contractsDir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.endsWith('.pdf')) continue;
        if (name.contains('contract') || name.contains('agreement') || name.contains('proposal')) {
          if (!name.contains('consultant') && !name.contains('invoice')) {
            candidates.add(entity);
          }
        }
      }

      if (candidates.isEmpty) {
        // Fallback: try any PDF under Executed folder
        final execDir = Directory('${contractsDir.path}\\Executed');
        if (await execDir.exists()) {
          await for (final entity in execDir.list(recursive: true)) {
            if (entity is! File) continue;
            if (entity.uri.pathSegments.last.toLowerCase().endsWith('.pdf')) {
              candidates.add(entity);
            }
          }
        }
      }

      if (candidates.isEmpty) return null;

      // Sort by modification time, newest first
      final stats = <File, DateTime>{};
      for (final f in candidates) {
        stats[f] = (await f.stat()).modified;
      }
      candidates.sort((a, b) => stats[b]!.compareTo(stats[a]!));

      // Parse the filename of the most recent contract
      final filename = candidates.first.uri.pathSegments.last;
      return _parseProjectNameFromContractFilename(filename);
    } catch (_) {
      return null;
    }
  }

  /// Parse project name from a Fee Worksheet filename.
  /// Handles many naming variations found across A2H projects:
  ///   "2022-03-30 - 19201 TC Animal Shelter per Discipline.xlsx"
  ///   "19201 TC Animal Shelter Fee Worksheet.xlsx"
  ///   "19201 - TC Animal Shelter.xlsx"
  ///   "Fee Worksheet - 19201 TC Animal Shelter.xlsx"
  ///   "19201_TC_Animal_Shelter_fees.gsheet"
  /// Always searches for a 4-6 digit project number then takes the name after it.
  static String? _parseProjectNameFromFeeWorksheet(String filename) {
    // Remove extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;

    // Replace underscores with spaces for uniformity
    var cleaned = base.replaceAll('_', ' ');

    // Find the project number (4-6 digits) anywhere in the filename
    final numMatch = RegExp(r'(\d{4,6})').firstMatch(cleaned);
    if (numMatch == null) return null;

    // Take everything after the project number
    var rest = cleaned.substring(numMatch.end).trim();

    // Strip leading separators (" - ", "-", etc.)
    rest = rest.replaceAll(RegExp(r'^[\s\-–—]+'), '').trim();

    // Iteratively strip trailing noise phrases (loop to catch multiples)
    String prev;
    do {
      prev = rest;
      rest = rest
          .replaceAll(RegExp(r'\s+per\s+Discipline\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Fee\s+Worksheet[s]?\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Fee\s+Schedule[s]?\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Fee\s+Proposal[s]?\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+fees?\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+by\s+Discipline\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Scope\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Revised\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Final\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+Draft\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+v\d+\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '') // trailing parenthetical
          .trim();
    } while (rest != prev && rest.isNotEmpty);

    // Strip leading noise: "Fee Worksheet", "Fee Schedule" if it somehow ended up at start
    rest = rest
        .replaceAll(RegExp(r'^Fee\s+Worksheet[s]?\s*[-–—]?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Fee\s+Schedule[s]?\s*[-–—]?\s*', caseSensitive: false), '')
        .trim();

    return rest.isNotEmpty ? rest : null;
  }

  /// Parse a project name from a contract filename.
  /// A2H contract naming convention:
  ///   "date - number - client - description type (status).pdf"
  /// Examples:
  ///   "2024-06-06 - 19201 - Tipton County - Animal Shelter Contract (Executed).pdf"
  ///   → "Tipton County Animal Shelter"
  ///   "2025-06-19 - 24402 - BMHCC - Warren Road New Site Development Contract - PO#... (A2H Executed).pdf"
  ///   → "BMHCC Warren Road New Site Development"
  static String? _parseProjectNameFromContractFilename(String filename) {
    // Remove extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;

    // Remove parenthetical status at end: "(A2H Executed)", "(Consultant Executed)", etc.
    final noParens = base.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

    // Split by " - " delimiter
    final parts = noParens.split(' - ').map((s) => s.trim()).toList();

    // Expected: [date, number, client, ...description parts...]
    if (parts.length < 4) return null;

    // Client name (part 2) — e.g. "Tipton County", "BMHCC"
    final client = parts[2];

    // Join description parts (index 3+)
    final descParts = parts.sublist(3);
    var desc = descParts.join(' - ');

    // Remove contract form numbers (C402-2018, B101-2017, etc.)
    desc = desc.replaceAll(RegExp(r'\b[A-Z]\d{2,3}-\d{4}\b'), '').trim();
    // Remove PO numbers
    desc = desc.replaceAll(RegExp(r'PO#[\w\-]+'), '').trim();
    // Remove ALL occurrences of "Contract", "Agreement", "Amendment #N", "Revised"
    // (loop to handle repeated occurrences like "Contract Contract Amendment #2")
    String prev;
    do {
      prev = desc;
      desc = desc
          .replaceAll(RegExp(r'\s*(Contract|Agreement|Proposal|Amendment\s*#?\d*|Revised)\s*$', caseSensitive: false), '')
          .trim();
    } while (desc != prev && desc.isNotEmpty);
    // Also strip standalone "Contract"/"Agreement" anywhere it appears as a full word at the end
    desc = desc.replaceAll(RegExp(r'\bContract\b\s*$', caseSensitive: false), '').trim();
    // Remove leading/trailing separators
    desc = desc.replaceAll(RegExp(r'^\s*-\s*|\s*-\s*$'), '').trim();

    // Combine: "Client Description" — e.g. "Tipton County Animal Shelter"
    if (desc.isNotEmpty) {
      return '$client $desc';
    }
    // If no description after cleaning, use just the client name
    return client.isNotEmpty ? client : null;
  }

  /// FAST extraction of project name + client from folder name and contract filenames.
  /// No PDF parsing — just directory listing. Returns in <1 second typically.
  /// Returns (projectName, clientName) — either may be null.
  Future<({String? name, String? client})> extractProjectInfoQuick() async {
    if (kIsWeb || basePath.isEmpty) return (name: null, client: null);
    String? name;
    String? client;

    try {
      // ── Priority 0: Folder name itself ──
      // Many project folders are named "24402 - Baptist Hospital" or "24402 Baptist"
      final folderName = basePath.split(RegExp(r'[/\\]')).last;
      final folderMatch = RegExp(r'^\d{4,6}\s*[-–—]\s*(.+)$').firstMatch(folderName);
      if (folderMatch != null) {
        final raw = folderMatch.group(1)!.trim();
        if (raw.length > 2) name = raw;
      }

      // ── Priority 1: Fee Worksheets (filename only, no file content) ──
      final feeDir = Directory('$basePath\\0 Project Management\\Contracts\\Fee Worksheets');
      if (await feeDir.exists()) {
        final feeFiles = <FileSystemEntity>[];
        await for (final entity in feeDir.list()) {
          if (entity is File) feeFiles.add(entity);
        }
        for (final f in feeFiles) {
          final parsed = _parseProjectNameFromFeeWorksheet(f.uri.pathSegments.last);
          if (parsed != null && parsed.length > 2) {
            name ??= parsed;
            break;
          }
        }
      }

      // ── Priority 2: Executed contract filenames ──
      final execDir = Directory('$basePath\\0 Project Management\\Contracts\\Executed');
      if (await execDir.exists()) {
        final files = <File>[];
        await for (final entity in execDir.list(recursive: true)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            files.add(entity);
          }
        }
        // Sort newest first by name (date-prefixed filenames sort naturally)
        files.sort((a, b) => b.uri.pathSegments.last.compareTo(a.uri.pathSegments.last));
        for (final f in files) {
          final filename = f.uri.pathSegments.last;
          final parsed = _parseProjectNameFromContractFilename(filename);
          if (parsed != null && parsed.length > 2) {
            name ??= parsed;
          }
          // Extract client from contract parts
          final dot = filename.lastIndexOf('.');
          final base = dot > 0 ? filename.substring(0, dot) : filename;
          final noParens = base.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
          final parts = noParens.split(' - ').map((s) => s.trim()).toList();
          if (parts.length >= 3 && client == null) {
            // parts[0]=date, parts[1]=number, parts[2]=client
            final c = parts[2];
            if (c.isNotEmpty && !RegExp(r'^\d+$').hasMatch(c)) {
              client = c;
            }
          }
          if (name != null && client != null) break;
        }
      }
    } catch (_) {
      // Best-effort
    }

    return (name: name, client: client);
  }

  /// Extract an Addendum number from a filename.
  /// Matches: ADD#2, ADD #2, ADD#12, Addendum 1, Addendum #3
  /// Returns null if no addendum reference found.
  static String? extractAddendumNumber(String filename) {
    final match = RegExp(r'ADD(?:ENDUM)?\s*#?\s*(\d+)', caseSensitive: false).firstMatch(filename);
    return match != null ? 'ADD #${match.group(1)}' : null;
  }

  /// Extract an RFI number from a filename.
  /// Matches: RFI-001, RFI #1, RFI#3, RFI 003
  /// Returns null if no RFI reference found.
  static String? extractRfiNumber(String filename) {
    final match = RegExp(r'RFI\s*[-#]?\s*(\d+)', caseSensitive: false).firstMatch(filename);
    return match != null ? 'RFI ${match.group(1)!.padLeft(3, '0')}' : null;
  }

  /// Extract an ASI number from a filename.
  /// Matches: ASI-001, ASI #1, ASI#3, ASI 003
  /// Returns null if no ASI reference found.
  static String? extractAsiNumber(String filename) {
    final match = RegExp(r'ASI\s*[-#]?\s*(\d+)', caseSensitive: false).firstMatch(filename);
    return match != null ? 'ASI #${match.group(1)}' : null;
  }

  /// Extract structured contract metadata from filenames in the Contracts\Executed folder.
  /// Returns a list of [ExtractedContract] parsed from the naming convention:
  /// `YYYY-MM-DD - NUMBER - CLIENT-ARCHITECT Description (Status).pdf`
  Future<List<ExtractedContract>> extractContractMetadata() async {
    if (kIsWeb || basePath.isEmpty) return [];
    try {
      if (!await isRootAccessible()) return [];

      final results = <ExtractedContract>[];

      // Scan Executed contracts (including Consultant Agreements subfolder)
      final executedDir = Directory('$basePath\\0 Project Management\\Contracts\\Executed');
      if (await executedDir.exists()) {
        await for (final entity in executedDir.list(recursive: true)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          if (!name.toLowerCase().endsWith('.pdf')) continue;
          if (_isIgnored(name)) continue;
          final stat = await entity.stat();
          final parsed = ExtractedContract.fromFilename(name, entity.path, stat.modified);
          if (parsed != null) results.add(parsed);
        }
      }

      // Scan Proposal RFP for additional amendment proposals
      final proposalDir = Directory('$basePath\\0 Project Management\\Contracts\\Proposal RFP');
      if (await proposalDir.exists()) {
        await for (final entity in proposalDir.list(recursive: false)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          if (!name.toLowerCase().endsWith('.pdf')) continue;
          if (_isIgnored(name)) continue;
          final stat = await entity.stat();
          final parsed = ExtractedContract.fromFilename(name, entity.path, stat.modified);
          if (parsed != null) {
            // Avoid duplicates — prefer Client Executed over A2H Executed
            final isDup = results.any((r) =>
              r.amendmentNumber == parsed.amendmentNumber &&
              r.type == parsed.type &&
              r.isClientExecuted);
            if (!isDup) results.add(parsed);
          }
        }
      }

      results.sort((a, b) => a.date.compareTo(b.date));
      return results;
    } catch (e) {
      debugPrint('[SCAN] extractContractMetadata ERROR: $e');
      return [];
    }
  }

  /// Extract fee discipline categories from Fee Worksheets folder.
  Future<List<ExtractedFeeWorksheet>> extractFeeWorksheets() async {
    if (kIsWeb || basePath.isEmpty) return [];
    try {
      if (!await isRootAccessible()) return [];
      final dir = Directory('$basePath\\0 Project Management\\Contracts\\Fee Worksheets');
      if (!await dir.exists()) return [];

      final results = <ExtractedFeeWorksheet>[];
      await for (final entity in dir.list(recursive: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        final stat = await entity.stat();
        final parsed = ExtractedFeeWorksheet.fromFilename(name, entity.path, stat.modified);
        if (parsed != null) results.add(parsed);
      }
      results.sort((a, b) => a.discipline.compareTo(b.discipline));
      return results;
    } catch (e) {
      debugPrint('[SCAN] extractFeeWorksheets ERROR: $e');
      return [];
    }
  }

  /// Scan Info Forms folder for Project Change documents.
  /// Returns count of project change forms and date range.
  Future<({int count, DateTime? earliest, DateTime? latest})> scanInfoForms() async {
    if (kIsWeb || basePath.isEmpty) return (count: 0, earliest: null, latest: null);
    try {
      if (!await isRootAccessible()) return (count: 0, earliest: null, latest: null);
      final dir = Directory('$basePath\\0 Project Management\\Contracts\\Info Forms');
      if (!await dir.exists()) return (count: 0, earliest: null, latest: null);

      int count = 0;
      DateTime? earliest;
      DateTime? latest;

      await for (final entity in dir.list(recursive: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        count++;
        // Extract date from filename: "YYYY-MM-DD ..."
        final dateMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(name);
        if (dateMatch != null) {
          try {
            final d = DateTime(
              int.parse(dateMatch.group(1)!),
              int.parse(dateMatch.group(2)!),
              int.parse(dateMatch.group(3)!),
            );
            if (earliest == null || d.isBefore(earliest)) earliest = d;
            if (latest == null || d.isAfter(latest)) latest = d;
          } catch (_) {}
        }
      }
      return (count: count, earliest: earliest, latest: latest);
    } catch (_) {
      return (count: 0, earliest: null, latest: null);
    }
  }


  // ── File operations (rename / copy / delete / clipboard) ────────────

  /// Copy file to Windows clipboard (Ctrl+V in Explorer).
  static Future<void> copyFileToClipboard(String fullPath) async {
    if (kIsWeb) return;
    await Process.run(
        'powershell', ['-Command', 'Set-Clipboard', '-Path', fullPath]);
  }

  /// Rename a file on disk. [newName] must be a basename only.
  static Future<File> renameFileOnDisk(
      String fullPath, String newName) async {
    _validateBasename(newName);
    final src = File(fullPath);
    final destPath = '${src.parent.path}\\$newName';
    if (await File(destPath).exists()) {
      throw FileSystemException(
          'A file with that name already exists', destPath);
    }
    try {
      return await src.rename(destPath);
    } on FileSystemException catch (e) {
      throw FileSystemException(
          'Cannot rename: file may be read-only or in use',
          e.path, e.osError);
    }
  }

  /// Delete a file from disk.
  static Future<void> deleteFileOnDisk(String fullPath) async {
    try {
      await File(fullPath).delete();
    } on FileSystemException catch (e) {
      throw FileSystemException(
          'Cannot delete: file may be read-only or in use',
          e.path, e.osError);
    }
  }

  /// Duplicate file in same folder as "Name - Copy.ext", auto-incrementing.
  static Future<File> duplicateFile(String fullPath) async {
    final src = File(fullPath);
    final dir = src.parent.path;
    final stem = _stemOf(fullPath);
    final ext = _extOf(fullPath);
    var dest = '$dir\\$stem - Copy$ext';
    if (!File(dest).existsSync()) return src.copy(dest);
    for (var i = 2; i < 1000; i++) {
      dest = '$dir\\$stem - Copy ($i)$ext';
      if (!File(dest).existsSync()) return src.copy(dest);
    }
    return src.copy(
        '$dir\\$stem - Copy (${DateTime.now().millisecondsSinceEpoch})$ext');
  }

  static final _invalidChars = RegExp(r'[\\/:*?"<>|]');

  static void _validateBasename(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Filename cannot be empty');
    }
    if (_invalidChars.hasMatch(name)) {
      throw ArgumentError('Invalid characters in filename');
    }
  }

  /// Check if a filename is valid (no empty, no invalid chars).
  static bool isValidFilename(String name) =>
      name.trim().isNotEmpty && !_invalidChars.hasMatch(name);

  static String _stemOf(String path) {
    final n = path.split('\\').last;
    final d = n.lastIndexOf('.');
    return d > 0 ? n.substring(0, d) : n;
  }

  static String _extOf(String path) {
    final n = path.split('\\').last;
    final d = n.lastIndexOf('.');
    return d > 0 ? n.substring(d) : '';
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot >= 0 ? filename.substring(dot) : '';
  }
}

/// Structured metadata extracted from a contract PDF filename.
class ExtractedContract {
  final DateTime date;
  final String projectNumber;
  final String parties;      // e.g. "HRT-A2H" or "A2H-SSR"
  final String description;
  final String type;         // 'Original', 'Amendment', 'Consultant'
  final int? amendmentNumber;
  final String status;       // 'Client Executed', 'A2H Executed', 'Consultant Executed', 'Draft'
  final String fullPath;
  final DateTime fileModified;

  const ExtractedContract({
    required this.date,
    required this.projectNumber,
    required this.parties,
    required this.description,
    required this.type,
    this.amendmentNumber,
    required this.status,
    required this.fullPath,
    required this.fileModified,
  });

  Map<String, dynamic> toJson() => {
    'd': date.millisecondsSinceEpoch,
    'pn': projectNumber,
    'pa': parties,
    'de': description,
    'ty': type,
    'an': amendmentNumber,
    'st': status,
    'fp': fullPath,
    'fm': fileModified.millisecondsSinceEpoch,
  };

  factory ExtractedContract.fromJson(Map<String, dynamic> j) => ExtractedContract(
    date: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
    projectNumber: j['pn'] as String,
    parties: j['pa'] as String,
    description: j['de'] as String,
    type: j['ty'] as String,
    amendmentNumber: j['an'] as int?,
    status: j['st'] as String,
    fullPath: j['fp'] as String,
    fileModified: DateTime.fromMillisecondsSinceEpoch(j['fm'] as int),
  );

  bool get isClientExecuted => status.toLowerCase().contains('client');

  String get displayTitle {
    if (type == 'Amendment' && amendmentNumber != null) {
      return 'Amendment #$amendmentNumber \u2014 $description';
    }
    if (type == 'Consultant') {
      return 'Consultant: $parties \u2014 $description';
    }
    return description;
  }

  String get displayStatus {
    if (status.toLowerCase().contains('executed')) return 'Executed';
    if (status.toLowerCase().contains('draft')) return 'Draft';
    return 'Pending';
  }

  /// Parse a contract filename into structured metadata.
  /// Expected format: `YYYY-MM-DD - NUMBER - PARTIES - Description (Status).pdf`
  static ExtractedContract? fromFilename(String filename, String fullPath, DateTime modified) {
    // Remove extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;

    // Extract status from parenthetical at end
    final statusMatch = RegExp(r'\(([^)]+)\)\s*$').firstMatch(base);
    final status = statusMatch?.group(1)?.trim() ?? '';
    final noStatus = statusMatch != null
        ? base.substring(0, statusMatch.start).trim()
        : base;

    // Split by " - " delimiter
    final parts = noStatus.split(' - ').map((s) => s.trim()).toList();
    if (parts.length < 3) return null;

    // Parse date
    final datePart = parts[0];
    DateTime? date;
    try {
      final dp = datePart.split('-');
      if (dp.length == 3) {
        date = DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]));
      }
    } catch (_) {}
    if (date == null) return null;

    final projectNumber = parts[1];
    final parties = parts[2];
    final descParts = parts.length > 3 ? parts.sublist(3) : <String>[];
    var desc = descParts.join(' - ');

    // Determine type
    String type = 'Original';
    int? amendmentNum;

    final amendMatch = RegExp(r'Amendment\s*(?:Proposal\s*)?#?(\d+)', caseSensitive: false).firstMatch(desc);
    if (amendMatch != null) {
      type = 'Amendment';
      amendmentNum = int.tryParse(amendMatch.group(1)!);
    }

    // Check for consultant agreement
    if (parties.toLowerCase().contains('ssr') ||
        desc.toLowerCase().contains('consultant') ||
        desc.toLowerCase().contains('c401') ||
        desc.toLowerCase().contains('g803')) {
      type = 'Consultant';
      // Extract consultant amendment number from G803 references
      final consultAmend = RegExp(r'#(\d+)', caseSensitive: false).firstMatch(desc);
      if (consultAmend != null) {
        amendmentNum = int.tryParse(consultAmend.group(1)!);
      }
    }

    // Clean description — remove form numbers
    desc = desc.replaceAll(RegExp(r'\b[A-Z]\d{2,3}\s*-?\s*\d{4}\b'), '').trim();
    desc = desc.replaceAll(RegExp(r'^\s*-\s*|\s*-\s*$'), '').trim();

    return ExtractedContract(
      date: date,
      projectNumber: projectNumber,
      parties: parties,
      description: desc.isNotEmpty ? desc : 'Contract',
      type: type,
      amendmentNumber: amendmentNum,
      status: status,
      fullPath: fullPath,
      fileModified: modified,
    );
  }
}

/// Structured metadata extracted from a fee worksheet filename.
class ExtractedFeeWorksheet {
  final String discipline;
  final String fullPath;
  final DateTime modified;
  final String filename;

  const ExtractedFeeWorksheet({
    required this.discipline,
    required this.fullPath,
    required this.modified,
    required this.filename,
  });

  Map<String, dynamic> toJson() => {
    'di': discipline,
    'fp': fullPath,
    'mo': modified.millisecondsSinceEpoch,
    'fn': filename,
  };

  factory ExtractedFeeWorksheet.fromJson(Map<String, dynamic> j) => ExtractedFeeWorksheet(
    discipline: j['di'] as String,
    fullPath: j['fp'] as String,
    modified: DateTime.fromMillisecondsSinceEpoch(j['mo'] as int),
    filename: j['fn'] as String,
  );

  static ExtractedFeeWorksheet? fromFilename(String filename, String fullPath, DateTime modified) {
    // Match "DISCIPLINE Fee Worksheet.xls(x)"
    final wsMatch = RegExp(r'^(.+?)\s+fee\s+worksheet', caseSensitive: false).firstMatch(filename);
    if (wsMatch != null) {
      return ExtractedFeeWorksheet(
        discipline: wsMatch.group(1)!.trim(),
        fullPath: fullPath,
        modified: modified,
        filename: filename,
      );
    }

    // Match "YYYY-MM-DD - NUMBER - Fee Breakdown - TYPE.xlsx"
    final breakdownMatch = RegExp(r'fee\s+breakdown\s*-\s*(.+)', caseSensitive: false).firstMatch(filename);
    if (breakdownMatch != null) {
      final rest = breakdownMatch.group(1)!;
      final extDot = rest.lastIndexOf('.');
      final label = extDot > 0 ? rest.substring(0, extDot).trim() : rest.trim();
      return ExtractedFeeWorksheet(
        discipline: label,
        fullPath: fullPath,
        modified: modified,
        filename: filename,
      );
    }

    // Match summary/breakout files
    if (filename.toLowerCase().contains('summary') || filename.toLowerCase().contains('breakout')) {
      return ExtractedFeeWorksheet(
        discipline: 'Summary',
        fullPath: fullPath,
        modified: modified,
        filename: filename,
      );
    }

    return null;
  }
}

/// A milestone discovered from folder/file names in the project directory.
class DiscoveredMilestone {
  final String label;
  final DateTime date;
  final String source; // relative path where it was found
  final int fileCount;

  const DiscoveredMilestone({
    required this.label,
    required this.date,
    required this.source,
    required this.fileCount,
  });

  Map<String, dynamic> toJson() => {
    'l': label,
    'd': date.millisecondsSinceEpoch,
    's': source,
    'c': fileCount,
  };

  factory DiscoveredMilestone.fromJson(Map<String, dynamic> j) => DiscoveredMilestone(
    label: j['l'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
    source: j['s'] as String,
    fileCount: j['c'] as int,
  );
}

/// File activity dates discovered for a schedule phase.
class PhaseFileActivity {
  final DateTime earliestFile;
  final DateTime latestFile;
  final int fileCount;

  const PhaseFileActivity({
    required this.earliestFile,
    required this.latestFile,
    required this.fileCount,
  });

  Map<String, dynamic> toJson() => {
    'e': earliestFile.millisecondsSinceEpoch,
    'l': latestFile.millisecondsSinceEpoch,
    'c': fileCount,
  };

  factory PhaseFileActivity.fromJson(Map<String, dynamic> j) => PhaseFileActivity(
    earliestFile: DateTime.fromMillisecondsSinceEpoch(j['e'] as int),
    latestFile: DateTime.fromMillisecondsSinceEpoch(j['l'] as int),
    fileCount: j['c'] as int,
  );
}
