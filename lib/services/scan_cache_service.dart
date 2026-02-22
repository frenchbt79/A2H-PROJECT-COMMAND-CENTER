import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scanned_file.dart';
import '../models/ca_entry.dart';
import '../models/drawing_metadata.dart';
import 'folder_scan_service.dart';

/// Caches scan results to SharedPreferences so the app works offline.
///
/// Each cache entry stores:
/// - The serialized data (JSON list)
/// - A timestamp of when the scan was performed
///
/// Keys are prefixed with `pcc_cache_` to separate from other app data.
class ScanCacheService {
  static const _basePrefix = 'pcc_cache_';
  static const _baseTsPrefix = 'pcc_cache_ts_';

  late final SharedPreferences _prefs;
  String _projectId = '';

  /// Returns the namespaced cache key prefix for the current project.
  String get _prefix => _projectId.isEmpty ? _basePrefix : '$_basePrefix${_projectId}_';
  String get _tsPrefix => _projectId.isEmpty ? _baseTsPrefix : '$_baseTsPrefix${_projectId}_';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Initialize with an existing SharedPreferences instance.
  void initWith(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Set the active project ID for per-project cache namespacing.
  void setProjectId(String id) => _projectId = id;

  // ══════════════════════════════════════════════════════════
  // GENERIC HELPERS — eliminate boilerplate across type-specific methods
  // ══════════════════════════════════════════════════════════

  /// Generic list loader — deserializes JSON array to List<T>.
  List<T>? _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Generic list saver — serializes List<T> to JSON array.
  Future<void> _saveList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) async {
    await _prefs.setString('$_prefix$key', jsonEncode(items.map(toJson).toList()));
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// Generic map loader — deserializes JSON object to Map<String, T>.
  Map<String, T>? _loadMap<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return null;
    }
  }

  /// Generic map saver — serializes Map<String, T> to JSON object.
  Future<void> _saveMap<T>(String key, Map<String, T> data, Map<String, dynamic> Function(T) toJson) async {
    final encoded = data.map((k, v) => MapEntry(k, toJson(v)));
    await _prefs.setString('$_prefix$key', jsonEncode(encoded));
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  // ══════════════════════════════════════════════════════════
  // TYPE-SPECIFIC THIN WRAPPERS (one-liners using generics)
  // ══════════════════════════════════════════════════════════

  // ── ScannedFile lists ────────────────────────────────────
  List<ScannedFile>? loadFiles(String key) => _loadList(key, ScannedFile.fromJson);
  Future<void> saveFiles(String key, List<ScannedFile> files) => _saveList(key, files, (f) => f.toJson());

  // ── CaEntry lists ───────────────────────────────────────
  List<CaEntry>? loadCaEntries(String key) => _loadList(key, CaEntry.fromJson);
  Future<void> saveCaEntries(String key, List<CaEntry> entries) => _saveList(key, entries, (e) => e.toJson());

  // ── ExtractedContract lists ─────────────────────────────
  List<ExtractedContract>? loadContracts(String key) => _loadList(key, ExtractedContract.fromJson);
  Future<void> saveContracts(String key, List<ExtractedContract> items) => _saveList(key, items, (e) => e.toJson());

  // ── ExtractedFeeWorksheet lists ─────────────────────────
  List<ExtractedFeeWorksheet>? loadFeeWorksheets(String key) => _loadList(key, ExtractedFeeWorksheet.fromJson);
  Future<void> saveFeeWorksheets(String key, List<ExtractedFeeWorksheet> items) => _saveList(key, items, (e) => e.toJson());

  // ── DiscoveredMilestone lists ───────────────────────────
  List<DiscoveredMilestone>? loadMilestones(String key) => _loadList(key, DiscoveredMilestone.fromJson);
  Future<void> saveMilestones(String key, List<DiscoveredMilestone> items) => _saveList(key, items, (e) => e.toJson());

  // ── PhaseFileActivity map ───────────────────────────────
  Map<String, PhaseFileActivity>? loadPhaseActivity(String key) => _loadMap(key, PhaseFileActivity.fromJson);
  Future<void> savePhaseActivity(String key, Map<String, PhaseFileActivity> data) => _saveMap(key, data, (v) => v.toJson());

  // ── DrawingMetadata lists ───────────────────────────────
  List<DrawingMetadata>? loadDrawingMetadata(String key) => _loadList(key, DrawingMetadata.fromJson);
  Future<void> saveDrawingMetadata(String key, List<DrawingMetadata> items) => _saveList(key, items, (e) => e.toJson());

  // ── Info forms (record — custom shape) ─────────────────

  ({int count, DateTime? earliest, DateTime? latest})? loadInfoForms(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (
        count: j['c'] as int,
        earliest: j['e'] != null ? DateTime.fromMillisecondsSinceEpoch(j['e'] as int) : null,
        latest: j['l'] != null ? DateTime.fromMillisecondsSinceEpoch(j['l'] as int) : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveInfoForms(String key, ({int count, DateTime? earliest, DateTime? latest}) data) async {
    await _prefs.setString('$_prefix$key', jsonEncode({
      'c': data.count,
      'e': data.earliest?.millisecondsSinceEpoch,
      'l': data.latest?.millisecondsSinceEpoch,
    }));
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  // ── Generic string maps ────────────────────────────────

  Map<String, String>? loadStringMap(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStringMap(String key, Map<String, String> data) async {
    await _prefs.setString('$_prefix$key', jsonEncode(data));
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  // ══════════════════════════════════════════════════════════
  // UTILITIES
  // ══════════════════════════════════════════════════════════

  DateTime? lastCacheTime(String key) {
    final ts = _prefs.getInt('$_tsPrefix$key');
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Clear scan caches for the current project.
  Future<void> clearAll() async {
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
