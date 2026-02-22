import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

/// Reads .xlsx and .csv files and extracts key-value pairs matching
/// known project info field labels. Pure static class, no state.
class SpreadsheetParserService {
  SpreadsheetParserService._();

  /// Maps normalized label text → (category, canonical label).
  static const _fieldMappings = <String, (String, String)>{
    // General
    'project name': ('General', 'Project Name'),
    'project number': ('General', 'Project Number'),
    'project no': ('General', 'Project Number'),
    'project no.': ('General', 'Project Number'),
    'project address': ('General', 'Project Address'),
    'address': ('General', 'Project Address'),
    'site address': ('General', 'Project Address'),
    'client': ('General', 'Client'),
    'owner': ('General', 'Client'),
    'property owner': ('General', 'Client'),
    'architect of record': ('General', 'Architect of Record'),
    'architect': ('General', 'Architect of Record'),
    // Codes & Standards
    'building code': ('Codes & Standards', 'Building Code'),
    'applicable building code': ('Codes & Standards', 'Building Code'),
    'energy code': ('Codes & Standards', 'Energy Code'),
    'fire code': ('Codes & Standards', 'Fire Code'),
    'accessibility': ('Codes & Standards', 'Accessibility'),
    'ada': ('Codes & Standards', 'Accessibility'),
    'ada compliance': ('Codes & Standards', 'Accessibility'),
    'healthcare guidelines': ('Codes & Standards', 'Healthcare Guidelines'),
    'fgi': ('Codes & Standards', 'Healthcare Guidelines'),
    'fgi guidelines': ('Codes & Standards', 'Healthcare Guidelines'),
    'local amendments': ('Codes & Standards', 'Local Amendments'),
    'jurisdiction': ('Codes & Standards', 'Jurisdiction'),
    'occupancy group': ('Codes & Standards', 'Occupancy Group'),
    'occupancy classification': ('Codes & Standards', 'Occupancy Group'),
    'occupancy type': ('Codes & Standards', 'Occupancy Group'),
    'construction type': ('Codes & Standards', 'Construction Type'),
    'type of construction': ('Codes & Standards', 'Construction Type'),
    'allowable area': ('Codes & Standards', 'Allowable Area'),
    'allowable building area': ('Codes & Standards', 'Allowable Area'),
    'allowable height': ('Codes & Standards', 'Allowable Height'),
    'allowable stories': ('Codes & Standards', 'Allowable Stories'),
    'allowable number of stories': ('Codes & Standards', 'Allowable Stories'),
    'mixed use': ('Codes & Standards', 'Mixed Use'),
    'separated uses': ('Codes & Standards', 'Mixed Use'),
    'fire alarm': ('Codes & Standards', 'Fire Alarm System'),
    'fire alarm system': ('Codes & Standards', 'Fire Alarm System'),
    'sprinklered': ('Codes & Standards', 'Sprinklered'),
    'fire sprinkler': ('Codes & Standards', 'Sprinklered'),
    // Zoning
    'zoning': ('Zoning', 'Zoning Classification'),
    'zoning classification': ('Zoning', 'Zoning Classification'),
    'zoning district': ('Zoning', 'Zoning Classification'),
    'far allowed': ('Zoning', 'FAR (Allowed / Designed)'),
    'far': ('Zoning', 'FAR (Allowed / Designed)'),
    'floor area ratio': ('Zoning', 'FAR (Allowed / Designed)'),
    'max height': ('Zoning', 'Max Height'),
    'maximum height': ('Zoning', 'Max Height'),
    'maximum building height': ('Zoning', 'Max Height'),
    'height limit': ('Zoning', 'Max Height'),
    'setbacks': ('Zoning', 'Setbacks (F/S/R)'),
    'setback': ('Zoning', 'Setbacks (F/S/R)'),
    'front setback': ('Zoning', 'Setbacks (F/S/R)'),
    'parking required': ('Zoning', 'Parking Required'),
    'parking req': ('Zoning', 'Parking Required'),
    'parking': ('Zoning', 'Parking Required'),
    'overlays': ('Zoning', 'Overlays'),
    'overlay district': ('Zoning', 'Overlays'),
    'zoning link': ('Zoning', 'Zoning Link'),
    // Site
    'parcel number': ('Site', 'Parcel Number'),
    'parcel': ('Site', 'Parcel Number'),
    'parcel id': ('Site', 'Parcel Number'),
    'pin': ('Site', 'Parcel Number'),
    'lot size': ('Site', 'Lot Size'),
    'lot size acres': ('Site', 'Lot Size'),
    'site area': ('Site', 'Lot Size'),
    'acreage': ('Site', 'Lot Size'),
    'existing use': ('Site', 'Existing Use'),
    'current use': ('Site', 'Existing Use'),
    'latitude': ('Site', 'Latitude'),
    'lat': ('Site', 'Latitude'),
    'longitude': ('Site', 'Longitude'),
    'lon': ('Site', 'Longitude'),
    'lng': ('Site', 'Longitude'),
    'city': ('Site', 'City'),
    'county': ('Site', 'County'),
    'flood zone': ('Site', 'Flood Zone'),
    'fema flood zone': ('Site', 'Flood Zone'),
    'utilities': ('Site', 'Utilities'),
    'elevation': ('Site', 'Elevation'),
  };

  /// Parse an XLSX file and return discovered key-value pairs.
  static List<(String category, String label, String value)> parseXlsx(String filePath) {
    if (kIsWeb) return [];
    try {
      final bytes = File(filePath).readAsBytesSync();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      final results = <(String, String, String)>[];

      for (final table in decoder.tables.values) {
        for (final row in table.rows) {
          if (row.length < 2) continue;
          final cellA = (row[0]?.toString() ?? '').trim();
          final cellB = (row[1]?.toString() ?? '').trim();
          if (cellA.isEmpty || cellB.isEmpty) continue;

          final normalized = _normalize(cellA);
          final mapping = _fieldMappings[normalized];
          if (mapping != null) {
            results.add((mapping.$1, mapping.$2, cellB));
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('[SHEET] parseXlsx error: $e');
      return [];
    }
  }

  /// Parse a CSV file and return discovered key-value pairs.
  static List<(String category, String label, String value)> parseCsv(String filePath) {
    if (kIsWeb) return [];
    try {
      final content = File(filePath).readAsStringSync();
      final results = <(String, String, String)>[];

      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        // Split on first comma only — value may contain commas
        final commaIdx = trimmed.indexOf(',');
        if (commaIdx < 0) continue;
        final cellA = trimmed.substring(0, commaIdx).replaceAll('"', '').trim();
        final cellB = trimmed.substring(commaIdx + 1).replaceAll('"', '').trim();
        if (cellA.isEmpty || cellB.isEmpty) continue;

        final normalized = _normalize(cellA);
        final mapping = _fieldMappings[normalized];
        if (mapping != null) {
          results.add((mapping.$1, mapping.$2, cellB));
        }
      }
      return results;
    } catch (e) {
      debugPrint('[SHEET] parseCsv error: $e');
      return [];
    }
  }

  /// Normalize a label string for matching.
  static String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[:\-_/]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
