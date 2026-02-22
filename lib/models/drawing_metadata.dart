import 'scanned_file.dart';

/// Structured metadata for a single drawing file.
/// Persisted via ScanCacheService — survives across sessions.
/// The file system is raw storage; this model is the intelligence layer.
class DrawingMetadata {
  /// The raw scanned file.
  final ScannedFile file;

  /// Discipline prefix in uppercase (e.g. "A", "M", "FP").
  final String disciplinePrefix;

  /// Full discipline name (e.g. "Architectural", "Mechanical").
  final String discipline;

  /// Sheet number as displayed (exact from filename, e.g. "A1.01").
  final String sheetNumber;

  /// Canonical key — normalized sheet number (lowercase, e.g. "a1.01").
  final String sheetKey;

  /// Revision/addendum label from parser (e.g. "ADD #2", "Rev A", "").
  final String revisionLabel;

  /// Whether SheetNameParser successfully parsed this filename.
  final bool parseValid;

  /// Phase tag: SD, DD, CD, CA, or empty if unknown.
  final String phase;

  /// How phase was determined: "folder", "date", or "".
  final String phaseSource;

  /// Count of addendum cross-refs for this sheet.
  final int addendumCount;

  /// Count of RFI cross-refs for this sheet.
  final int rfiCount;

  /// Count of ASI cross-refs for this sheet.
  final int asiCount;

  /// Highest addendum label (e.g. "ADD #3") or "".
  final String latestAddLabel;

  /// Highest RFI label (e.g. "RFI 005") or "".
  final String latestRfiLabel;

  /// Highest ASI label (e.g. "ASI #2") or "".
  final String latestAsiLabel;

  /// Cross-ref files — NOW SERIALIZED for offline access.
  final List<ScannedFile> addFiles;
  final List<ScannedFile> rfiFiles;
  final List<ScannedFile> asiFiles;

  /// Another file resolves to the same sheetKey.
  final bool hasDuplicate;

  /// Issue date — extracted from filename or file modified date.
  final DateTime issueDate;

  const DrawingMetadata({
    required this.file,
    required this.disciplinePrefix,
    required this.discipline,
    required this.sheetNumber,
    required this.sheetKey,
    this.revisionLabel = '',
    this.parseValid = true,
    this.phase = '',
    this.phaseSource = '',
    this.addendumCount = 0,
    this.rfiCount = 0,
    this.asiCount = 0,
    this.latestAddLabel = '',
    this.latestRfiLabel = '',
    this.latestAsiLabel = '',
    this.addFiles = const [],
    this.rfiFiles = const [],
    this.asiFiles = const [],
    this.hasDuplicate = false,
    required this.issueDate,
  });

  DrawingMetadata copyWith({
    ScannedFile? file,
    String? disciplinePrefix,
    String? discipline,
    String? sheetNumber,
    String? sheetKey,
    String? revisionLabel,
    bool? parseValid,
    String? phase,
    String? phaseSource,
    int? addendumCount,
    int? rfiCount,
    int? asiCount,
    String? latestAddLabel,
    String? latestRfiLabel,
    String? latestAsiLabel,
    List<ScannedFile>? addFiles,
    List<ScannedFile>? rfiFiles,
    List<ScannedFile>? asiFiles,
    bool? hasDuplicate,
    DateTime? issueDate,
  }) {
    return DrawingMetadata(
      file: file ?? this.file,
      disciplinePrefix: disciplinePrefix ?? this.disciplinePrefix,
      discipline: discipline ?? this.discipline,
      sheetNumber: sheetNumber ?? this.sheetNumber,
      sheetKey: sheetKey ?? this.sheetKey,
      revisionLabel: revisionLabel ?? this.revisionLabel,
      parseValid: parseValid ?? this.parseValid,
      phase: phase ?? this.phase,
      phaseSource: phaseSource ?? this.phaseSource,
      addendumCount: addendumCount ?? this.addendumCount,
      rfiCount: rfiCount ?? this.rfiCount,
      asiCount: asiCount ?? this.asiCount,
      latestAddLabel: latestAddLabel ?? this.latestAddLabel,
      latestRfiLabel: latestRfiLabel ?? this.latestRfiLabel,
      latestAsiLabel: latestAsiLabel ?? this.latestAsiLabel,
      addFiles: addFiles ?? this.addFiles,
      rfiFiles: rfiFiles ?? this.rfiFiles,
      asiFiles: asiFiles ?? this.asiFiles,
      hasDuplicate: hasDuplicate ?? this.hasDuplicate,
      issueDate: issueDate ?? this.issueDate,
    );
  }

  /// Compact JSON for cache persistence. Cross-ref file lists ARE serialized for offline.
  Map<String, dynamic> toJson() => {
    'f': file.toJson(),
    'dp': disciplinePrefix,
    'di': discipline,
    'sn': sheetNumber,
    'sk': sheetKey,
    'rl': revisionLabel,
    'pv': parseValid,
    'ph': phase,
    'ps': phaseSource,
    'ac': addendumCount,
    'rc': rfiCount,
    'xc': asiCount,
    'al': latestAddLabel,
    'xl': latestRfiLabel,
    'il': latestAsiLabel,
    'hd': hasDuplicate,
    'id': issueDate.millisecondsSinceEpoch,
    'af': addFiles.map((f) => f.toJson()).toList(),
    'rf': rfiFiles.map((f) => f.toJson()).toList(),
    'xf': asiFiles.map((f) => f.toJson()).toList(),
  };

  factory DrawingMetadata.fromJson(Map<String, dynamic> j) => DrawingMetadata(
    file: ScannedFile.fromJson(j['f'] as Map<String, dynamic>),
    disciplinePrefix: j['dp'] as String? ?? '',
    discipline: j['di'] as String? ?? '',
    sheetNumber: j['sn'] as String? ?? '',
    sheetKey: j['sk'] as String? ?? '',
    revisionLabel: j['rl'] as String? ?? '',
    parseValid: j['pv'] as bool? ?? true,
    phase: j['ph'] as String? ?? '',
    phaseSource: j['ps'] as String? ?? '',
    addendumCount: j['ac'] as int? ?? 0,
    rfiCount: j['rc'] as int? ?? 0,
    asiCount: j['xc'] as int? ?? 0,
    latestAddLabel: j['al'] as String? ?? '',
    latestRfiLabel: j['xl'] as String? ?? '',
    latestAsiLabel: j['il'] as String? ?? '',
    addFiles: (j['af'] as List<dynamic>?)
        ?.map((e) => ScannedFile.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
    rfiFiles: (j['rf'] as List<dynamic>?)
        ?.map((e) => ScannedFile.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
    asiFiles: (j['xf'] as List<dynamic>?)
        ?.map((e) => ScannedFile.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
    hasDuplicate: j['hd'] as bool? ?? false,
    issueDate: DateTime.fromMillisecondsSinceEpoch(j['id'] as int? ?? 0),
  );
}
