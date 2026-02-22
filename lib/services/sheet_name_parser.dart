import 'package:flutter/foundation.dart' show debugPrint;

/// Parsed sheet information extracted from a drawing filename.
class SheetInfo {
  /// The discipline prefix in original case (e.g. "M", "FP", "A", "S").
  final String prefix;

  /// The full sheet number exactly as it appears in the filename
  /// (e.g. "M01.01", "A1-2A", "FP1.1").
  final String sheetNumber;

  /// Revision/addendum indicator if present (e.g. "ADD #2", "Rev A").
  /// Empty string if none.
  final String revision;

  /// Whether parsing succeeded. If false, sheetNumber is the raw basename.
  final bool valid;

  const SheetInfo({
    required this.prefix,
    required this.sheetNumber,
    required this.revision,
    required this.valid,
  });

  @override
  String toString() =>
      'SheetInfo(prefix=$prefix, sheet=$sheetNumber, rev=$revision, valid=$valid)';
}

/// Validation issue found during sheet scanning.
class SheetValidationIssue {
  final String filename;
  final String fullPath;
  final SheetIssueType type;
  final String detail;

  const SheetValidationIssue({
    required this.filename,
    required this.fullPath,
    required this.type,
    required this.detail,
  });
}

enum SheetIssueType {
  invalidFormat,
  duplicateSheet,
  prefixMismatch,
}

/// Canonical sheet name parser — single source of truth for extracting
/// sheet numbers from drawing filenames across all discipline pages.
class SheetNameParser {
  SheetNameParser._();

  /// Known discipline prefixes, longest first for greedy matching.
  static const _prefixes = [
    'fp', // Fire Protection (2-char, must come before 'f')
    'a',  // Architectural
    'c',  // Civil
    'e',  // Electrical
    'g',  // General
    'l',  // Landscape
    'm',  // Mechanical
    'p',  // Plumbing
    's',  // Structural
  ];

  /// Sheet number pattern after the prefix:
  /// digit(s) + separator(. or -) + digits/dots/dashes + optional letter suffix
  /// Also handles cases like A201 (no separator — common in some firms).
  static final _sheetPattern = RegExp(
    r'^([A-Za-z]{1,3})(\d+[.\-][\d.\-]*\d[A-Za-z]?)',
  );

  /// Fallback: prefix + digits with no separator (e.g. A201, M100).
  static final _noSepPattern = RegExp(
    r'^([A-Za-z]{1,3})(\d{2,}[A-Za-z]?)',
  );

  /// Addendum pattern in filename.
  static final _addPattern = RegExp(
    r'ADD(?:ENDUM)?\s*#?\s*(\d+)',
    caseSensitive: false,
  );

  /// Revision pattern in filename.
  static final _revPattern = RegExp(
    r'REV(?:ISION)?\s*\.?\s*([A-Za-z0-9]+)',
    caseSensitive: false,
  );

  /// Parse a drawing filename into structured sheet information.
  ///
  /// The sheet number is extracted from the start of the filename before
  /// the first space or description separator (` - `, ` – `, ` — `).
  ///
  /// Returns [SheetInfo] with `valid=true` if parsing succeeded, or
  /// `valid=false` with the raw base name if no sheet pattern matched.
  static SheetInfo parse(String filename) {
    // Strip extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;

    // Extract the leading token before the first separator
    // Separators: " - ", " – ", " — ", or just space followed by non-digit
    final sepIdx = _findDescriptionSeparator(base);
    final token = sepIdx > 0 ? base.substring(0, sepIdx).trim() : base.trim();

    // Try primary pattern: PREFIX + digits + separator + digits
    var match = _sheetPattern.firstMatch(token);
    if (match != null) {
      final rawPrefix = match.group(1)!;
      if (_isKnownPrefix(rawPrefix)) {
        final sheetNum = token.substring(0, match.end);
        final revision = _extractRevision(base);
        return SheetInfo(
          prefix: rawPrefix.toUpperCase(),
          sheetNumber: sheetNum,
          revision: revision,
          valid: true,
        );
      }
    }

    // Try no-separator pattern: PREFIX + 2+ digits (e.g. A201)
    match = _noSepPattern.firstMatch(token);
    if (match != null) {
      final rawPrefix = match.group(1)!;
      if (_isKnownPrefix(rawPrefix)) {
        final sheetNum = token.substring(0, match.end);
        final revision = _extractRevision(base);
        return SheetInfo(
          prefix: rawPrefix.toUpperCase(),
          sheetNumber: sheetNum,
          revision: revision,
          valid: true,
        );
      }
    }

    // Parse failure
    debugPrint('[SheetNameParser] Failed to parse: "$filename"');
    return SheetInfo(
      prefix: '',
      sheetNumber: base,
      revision: '',
      valid: false,
    );
  }

  /// Check if a raw prefix (case-insensitive) is a known discipline.
  static bool _isKnownPrefix(String rawPrefix) {
    final lower = rawPrefix.toLowerCase();
    return _prefixes.contains(lower);
  }

  /// Find the index of the description separator in the base name.
  /// Looks for ` - `, ` – `, ` — `, or first space that's followed
  /// by a non-digit (to avoid splitting "M1-1" on the dash).
  static int _findDescriptionSeparator(String base) {
    // Try explicit dash separators first
    for (final sep in [' - ', ' – ', ' — ']) {
      final idx = base.indexOf(sep);
      if (idx > 0) return idx;
    }
    // Fallback: first space
    final spaceIdx = base.indexOf(' ');
    if (spaceIdx > 0) return spaceIdx;
    return -1;
  }

  /// Extract a date from a filename.
  /// Supports: YYYY-MM-DD, MM-DD-YYYY, MM.DD.YYYY, YYYYMMDD.
  /// Returns null if no date pattern is found.
  static DateTime? extractDate(String filename) {
    // Strip extension
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;

    // YYYY-MM-DD or YYYY.MM.DD
    final iso = RegExp(r'(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})').firstMatch(base);
    if (iso != null) {
      final y = int.tryParse(iso.group(1)!);
      final m = int.tryParse(iso.group(2)!);
      final d = int.tryParse(iso.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // MM-DD-YYYY or MM.DD.YYYY
    final mdy = RegExp(r'(\d{1,2})[.\-](\d{1,2})[.\-](\d{4})').firstMatch(base);
    if (mdy != null) {
      final m = int.tryParse(mdy.group(1)!);
      final d = int.tryParse(mdy.group(2)!);
      final y = int.tryParse(mdy.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // YYYYMMDD (8 contiguous digits starting with 19xx or 20xx)
    final compact = RegExp(r'((?:19|20)\d{2})(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])').firstMatch(base);
    if (compact != null) {
      final y = int.parse(compact.group(1)!);
      final m = int.parse(compact.group(2)!);
      final d = int.parse(compact.group(3)!);
      return DateTime(y, m, d);
    }

    return null;
  }

  /// Extract revision/addendum info from the full base name.
  static String _extractRevision(String base) {
    final addMatch = _addPattern.firstMatch(base);
    if (addMatch != null) return 'ADD #${addMatch.group(1)}';

    final revMatch = _revPattern.firstMatch(base);
    if (revMatch != null) return 'Rev ${revMatch.group(1)}';

    return '';
  }

  /// Validate a list of files and return any issues found.
  /// [expectedPrefix] is the discipline prefix to check against (e.g. "m" for Mechanical).
  static List<SheetValidationIssue> validate(
    List<({String name, String fullPath})> files, {
    String? expectedPrefix,
  }) {
    final issues = <SheetValidationIssue>[];
    final sheetMap = <String, List<String>>{}; // sheetNumber → list of filenames

    for (final f in files) {
      final info = parse(f.name);

      // Invalid format
      if (!info.valid) {
        issues.add(SheetValidationIssue(
          filename: f.name,
          fullPath: f.fullPath,
          type: SheetIssueType.invalidFormat,
          detail: 'Could not parse sheet number from filename',
        ));
        continue;
      }

      // Prefix mismatch
      if (expectedPrefix != null &&
          info.prefix.toLowerCase() != expectedPrefix.toLowerCase()) {
        issues.add(SheetValidationIssue(
          filename: f.name,
          fullPath: f.fullPath,
          type: SheetIssueType.prefixMismatch,
          detail:
              'Expected prefix "${expectedPrefix.toUpperCase()}" but found "${info.prefix}"',
        ));
      }

      // Track for duplicate detection
      final key = info.sheetNumber.toLowerCase();
      sheetMap.putIfAbsent(key, () => []).add(f.name);
    }

    // Find duplicates
    for (final entry in sheetMap.entries) {
      if (entry.value.length > 1) {
        for (final filename in entry.value) {
          final fullPath =
              files.firstWhere((f) => f.name == filename).fullPath;
          issues.add(SheetValidationIssue(
            filename: filename,
            fullPath: fullPath,
            type: SheetIssueType.duplicateSheet,
            detail:
                'Duplicate sheet "${entry.key.toUpperCase()}" — ${entry.value.length} files',
          ));
        }
      }
    }

    return issues;
  }
}
