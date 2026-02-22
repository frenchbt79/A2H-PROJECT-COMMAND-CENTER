import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drawing_metadata.dart';
import '../models/scanned_file.dart';
import 'sheet_name_parser.dart';
import 'folder_scan_service.dart';

/// Reverse lookup from prefix letter to discipline name.
const _prefixToDiscipline = <String, String>{
  'G': 'General',
  'A': 'Architectural',
  'S': 'Structural',
  'C': 'Civil',
  'L': 'Landscape',
  'M': 'Mechanical',
  'E': 'Electrical',
  'P': 'Plumbing',
  'FP': 'Fire Protection',
};

/// Phase detection patterns in file paths.
final _phasePatterns = <String, RegExp>{
  'CD': RegExp(r'Construction\s*Documents?|[\/]CD[\/]', caseSensitive: false),
  'DD': RegExp(r'Design\s*Development|[\/]DD[\/]', caseSensitive: false),
  'SD': RegExp(r'Schematic\s*Design|[\/]SD[\/]', caseSensitive: false),
  'CA': RegExp(r'Construction\s*Admin|[\/]CA[\/]', caseSensitive: false),
};

/// Persists and manages structured metadata for drawings.
/// Builds intelligence on top of raw folder storage.
///
/// NOTE: For bulk enrichment, prefer [DrawingMetadataService.enrich()].
/// This service handles per-file building and SharedPreferences persistence.
class MetadataService {
  final SharedPreferences _prefs;
  String _projectId;

  static const _baseKey = 'pcc_meta_drawings_';

  MetadataService(this._prefs, {String projectId = ''})
      : _projectId = projectId;

  void setProjectId(String id) => _projectId = id;

  String get _key => _projectId.isEmpty
      ? '${_baseKey}default'
      : '$_baseKey$_projectId';

  /// Load all persisted metadata for the current project.
  Map<String, DrawingMetadata> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, DrawingMetadata.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('[MetadataService] load error: $e');
      return {};
    }
  }

  /// Save all metadata for the current project.
  Future<void> save(Map<String, DrawingMetadata> metadata) async {
    final encoded = jsonEncode(
      metadata.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_key, encoded);
  }

  /// Build metadata for a single scanned file.
  static DrawingMetadata buildFromFile(ScannedFile file) {
    final info = SheetNameParser.parse(file.name);
    final sheetKey = FolderScanService.sheetNumber(file.name);
    final discipline = info.valid
        ? (_prefixToDiscipline[info.prefix] ?? '')
        : '';

    // Phase from file path
    String phase = '';
    String phaseSource = '';
    for (final entry in _phasePatterns.entries) {
      if (entry.value.hasMatch(file.fullPath)) {
        phase = entry.key;
        phaseSource = 'folder';
        break;
      }
    }

    return DrawingMetadata(
      file: file,
      disciplinePrefix: info.valid ? info.prefix : '',
      discipline: discipline,
      sheetNumber: info.valid ? info.sheetNumber : file.name,
      sheetKey: sheetKey,
      revisionLabel: info.revision,
      parseValid: info.valid,
      phase: phase,
      phaseSource: phaseSource,
      issueDate: SheetNameParser.extractDate(file.name) ?? file.modified,
    );
  }

  /// Rebuild metadata for all scanned files.
  Map<String, DrawingMetadata> rebuildAll(List<ScannedFile> files) {
    final result = <String, DrawingMetadata>{};
    for (final file in files) {
      final key = FolderScanService.sheetNumber(file.name);
      result[key] = buildFromFile(file);
    }
    debugPrint('[MetadataService] rebuilt ${result.length} metadata entries');
    return result;
  }

  /// Clear all metadata for the current project.
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
