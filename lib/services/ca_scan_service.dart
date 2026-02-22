import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/ca_entry.dart';

/// Scans Construction Admin subfolders (RFIs, ASIs, etc.) and parses
/// metadata from folder names, filenames, and file dates.
class CaScanService {
  final String basePath;

  CaScanService(this.basePath);

  /// OS/editor junk to skip.
  static const _ignoredFiles = {
    'desktop.ini', '.ds_store', 'thumbs.db',
    '.spotlight-v100', '.trashes', '.fseventsd',
  };

  static bool _isIgnored(String filename) {
    final lower = filename.toLowerCase();
    if (_ignoredFiles.contains(lower)) return true;
    if (lower.startsWith('.') || lower.startsWith('~\$')) return true;
    return false;
  }

  // ════════════════════════════════════════════════════════════
  // PUBLIC: Scan a CA category folder
  // ════════════════════════════════════════════════════════════

  /// Scans a Construction Admin subfolder (e.g. "RFIs", "ASIs") and returns
  /// parsed [CaEntry] objects. Each subfolder becomes one entry.
  /// Loose files at root level also become individual entries.
  Future<List<CaEntry>> scanCaFolder(String caType, String relativePath) async {
    if (kIsWeb || basePath.isEmpty) return [];
    final dirPath = '$basePath\\$relativePath';
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final entries = <CaEntry>[];
    int looseIdx = 0;

    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is Directory) {
          final folderName = entity.uri.pathSegments
              .where((s) => s.isNotEmpty).last;

          // For Change Orders: expand the "RFCs" subfolder into individual RFC entries
          if (caType == 'CO' && folderName.toLowerCase() == 'rfcs') {
            try {
              await for (final rfcEntity in Directory(entity.path).list(recursive: false)) {
                if (rfcEntity is Directory) {
                  final rfcName = rfcEntity.uri.pathSegments
                      .where((s) => s.isNotEmpty).last;
                  final rfcEntry = await _parseFolder('RFC', rfcName, rfcEntity.path);
                  if (rfcEntry != null) entries.add(rfcEntry);
                }
              }
            } catch (e) {
              debugPrint('[CA-SCAN] Error scanning RFCs subfolder: $e');
            }
            continue;
          }

          // Each subfolder = one CA entry
          final entry = await _parseFolder(
            caType, folderName, entity.path,
          );
          if (entry != null) entries.add(entry);
        } else if (entity is File) {
          // Loose files at root (like tracking spreadsheets)
          final name = entity.uri.pathSegments.last;
          if (_isIgnored(name)) continue;
          final ext = _ext(name);
          if (ext != '.pdf' && ext != '.xls' && ext != '.xlsx'
              && ext != '.docx') continue;
          final stat = await entity.stat();
          looseIdx++;
          entries.add(CaEntry(
            id: '${caType.toLowerCase()}_loose_$looseIdx',
            type: caType,
            number: '$caType-L$looseIdx',
            description: _stripExt(name),
            date: stat.modified,
            status: 'Filed',
            folderPath: entity.path,
            files: [CaFile(
              name: name,
              fullPath: entity.path,
              sizeBytes: stat.size,
              modified: stat.modified,
              extension: ext,
              isPrimary: true,
            )],
          ));
        }
      }
    } catch (e) {
      debugPrint('[CA-SCAN] Error scanning $relativePath: $e');
    }

    // Sort by parsed number (natural sort)
    entries.sort((a, b) => _naturalCompare(a.number, b.number));
    return entries;
  }

  // ════════════════════════════════════════════════════════════
  // FOLDER PARSING
  // ════════════════════════════════════════════════════════════

  /// Parse a single CA entry folder into a [CaEntry].
  Future<CaEntry?> _parseFolder(
    String caType, String folderName, String folderPath,
  ) async {
    try {
      // Gather all files in the folder (recursive)
      final files = <CaFile>[];
      final folderDir = Directory(folderPath);
      await for (final entity in folderDir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (_isIgnored(name)) continue;
        final stat = await entity.stat();
        files.add(CaFile(
          name: name,
          fullPath: entity.path,
          sizeBytes: stat.size,
          modified: stat.modified,
          extension: _ext(name),
        ));
      }

      // Parse folder name for number, description, date
      final parsed = _parseFolderName(caType, folderName);
      final number = parsed.number;
      var description = parsed.description;
      var date = parsed.date;

      // Find the primary PDF (the main RFI/ASI/CO/SUB document)
      final primaryPdf = _findPrimaryPdf(caType, number, files);

      // If no description from folder, try primary PDF filename
      if (description.isEmpty && primaryPdf != null) {
        description = _descriptionFromFilename(caType, primaryPdf.name);
      }
      if (description.isEmpty) description = folderName;

      // If no date from folder name, use primary PDF date or newest file
      if (date == null) {
        date = primaryPdf?.modified ?? _newestDate(files);
      }

      // Extract affected sheets from filenames in the folder
      final sheets = _extractSheetNumbers(files);

      // Try to extract status from folder name + filenames
      final status = _extractStatus(caType, files, folderName: folderName);

      // Mark primary PDF
      final enrichedFiles = files.map((f) {
        if (primaryPdf != null && f.fullPath == primaryPdf.fullPath) {
          return CaFile(
            name: f.name, fullPath: f.fullPath,
            sizeBytes: f.sizeBytes, modified: f.modified,
            extension: f.extension, isPrimary: true,
          );
        }
        return f;
      }).toList();

      // Try to extract "issued by" from filenames
      final issuedBy = _extractIssuedBy(files);

      return CaEntry(
        id: '${caType.toLowerCase()}_${number.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}',
        type: caType,
        number: number,
        description: description,
        issuedBy: issuedBy,
        affectedSheets: sheets.isNotEmpty ? sheets.join(', ') : null,
        date: date,
        status: status,
        folderPath: folderPath,
        files: enrichedFiles,
      );
    } catch (e) {
      debugPrint('[CA-SCAN] Error parsing folder $folderName: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // FOLDER NAME PARSING
  // ════════════════════════════════════════════════════════════

  /// Parse patterns like:
  /// - "RFI #1"
  /// - "ASI #10 2022-09-22 Screen Wall"
  /// - "1-S1 Anchor Bolt Drawings 051200"
  /// - "Amendment #01"
  static ({String number, String description, DateTime? date}) _parseFolderName(
    String caType, String folderName,
  ) {
    String number = folderName;
    String description = '';
    DateTime? date;

    switch (caType) {
      case 'RFI':
        // Real patterns: "RFI 1 - CLOSED", "RFI 100 AHU 11 and AC1 Conflict - CLOSED",
        // "RFI 101 Ambient Temps in D104 and D105", "Pre-Construction RFI's"
        final m = RegExp(r'RFI\s*#?\s*(\d+)', caseSensitive: false).firstMatch(folderName);
        if (m != null) {
          number = 'RFI #${m.group(1)}';
          // Everything after the match is description (strip leading separators)
          description = folderName.substring(m.end).trim();
          // Remove " - CLOSED" before stripping separators (to handle "RFI 1 - CLOSED")
          description = description.replaceFirst(RegExp(r'\s*-\s*CLOSED\s*$', caseSensitive: false), '').trim();
          description = description.replaceFirst(RegExp(r'^[\s\-–—]+'), '').trim();
          // If description is exactly "CLOSED" after stripping, clear it
          if (description.toUpperCase() == 'CLOSED') description = '';
        }

      case 'ASI':
        // Real patterns: "ASI 01 - Response to State Health - East Wall Move 2021-01-19",
        // "ASI 02 - Common Corridor A Lobby Ceiling Revision (VOID)",
        // "ASI 12R1 - Response to RFI #31, #32, #33 & #34 (B&G Demo Work)"
        // Number may have revision suffix: 12R1, 12R, 12RR
        final m = RegExp(r'ASI\s*#?\s*(\d+[A-Za-z]*\d*)', caseSensitive: false).firstMatch(folderName);
        if (m != null) {
          number = 'ASI #${m.group(1)}';
          // Rest is description, possibly with date at end
          var rest = folderName.substring(m.end).trim();
          rest = rest.replaceFirst(RegExp(r'^[\s\-–—]+'), '').trim();
          // Check for date at the end: "2021-01-19"
          final dateMatch = RegExp(r'\s+(\d{4}[\-\.]\d{2}[\-\.]\d{2})\s*$').firstMatch(rest);
          if (dateMatch != null) {
            date = _parseDate(dateMatch.group(1)!);
            rest = rest.substring(0, dateMatch.start).trim();
          }
          // Remove (VOID) from description but note it for status
          rest = rest.replaceFirst(RegExp(r'\s*\(VOID\)\s*$', caseSensitive: false), '').trim();
          description = rest;
        }

      case 'CO':
        // Real patterns: "Change Order No. 1", "Change Order No. 14", "RFCs"
        final m = RegExp(r'(?:Amendment|Change\s*Order|CO)\s*(?:No\.?\s*|#?\s*)(\d+)', caseSensitive: false).firstMatch(folderName);
        if (m != null) {
          number = 'CO #${m.group(1)}';
          description = folderName.substring(m.end).trim();
          description = description.replaceFirst(RegExp(r'^[\s\-–—]+'), '').trim();
        } else if (folderName.toLowerCase() == 'rfcs') {
          // Skip the RFCs folder — it's a sub-grouping, not a CO
          return (number: folderName, description: 'Request for Changes', date: null);
        }

      case 'SUB':
        // Real patterns: "1-A5 Electronic Access Control 1.0",
        // "17-M2 Modular Indoor Central Station AHU 23 7313-1.0",
        // "63-FP1R Fire Sprinkler Rev. 1 21 0500-1.1",
        // "79 FP1R Fire Sprinkler Rev. 2 21 0500-1.2"
        // Pattern: SEQ-DISCIPLINE DESCRIPTION SPEC-VERSION  or  SEQ DISCIPLINE DESCRIPTION SPEC-VERSION
        final m = RegExp(r'^(\d+[\-\s][A-Za-z]+\d*[A-Za-z]*)\s+(.+?)(?:\s+(\d[\d\s]*\d{4}[\-\.]\d\.\d))?$').firstMatch(folderName);
        if (m != null) {
          number = 'SUB ${m.group(1)}';
          description = m.group(2)?.trim() ?? '';
          final spec = m.group(3)?.trim() ?? '';
          if (spec.isNotEmpty) {
            description = '$description [$spec]';
          }
        } else {
          // Fallback: split on first space after seq-disc
          final m2 = RegExp(r'^(\d+[\-\s]\S+)\s+(.*)$').firstMatch(folderName);
          if (m2 != null) {
            number = 'SUB ${m2.group(1)}';
            description = m2.group(2)?.trim() ?? folderName;
          }
        }

      case 'PL':
        // Punchlist folder may not exist — handle gracefully
        final m = RegExp(r'(?:Punchlist|PL|Punch\s*List)\s*#?\s*(\d+)', caseSensitive: false).firstMatch(folderName);
        if (m != null) {
          number = 'PL #${m.group(1)}';
          description = folderName.substring(m.end).trim();
        } else {
          number = folderName;
          description = folderName;
        }

      case 'RFC':
        // Real patterns: "RFC 1 - CO1", "RFC 50 (Rejected)", "RFC 107 (Cancelled)"
        final m = RegExp(r'RFC\s*#?\s*(\d+)', caseSensitive: false).firstMatch(folderName);
        if (m != null) {
          number = 'RFC #${m.group(1)}';
          description = folderName.substring(m.end).trim();
          description = description.replaceFirst(RegExp(r'^[\s\-–—]+'), '').trim();
          // Extract CO assignment from description: "CO1" → "Change Order 1"
          final coMatch = RegExp(r'CO\s*#?\s*(\d+)', caseSensitive: false).firstMatch(description);
          if (coMatch != null) {
            description = 'Change Order ${coMatch.group(1)}';
          }
          // Clean up parenthetical status markers from description
          description = description.replaceFirst(RegExp(r'\s*\((?:Rejected|Cancelled|Canceled)\)\s*$', caseSensitive: false), '').trim();
        }
    }

    return (number: number, description: description, date: date);
  }

  // ════════════════════════════════════════════════════════════
  // FILE / PDF PARSING HELPERS
  // ════════════════════════════════════════════════════════════

  /// Find the "main" PDF in a folder — the one that IS the RFI/ASI/CO document.
  static CaFile? _findPrimaryPdf(String caType, String number, List<CaFile> files) {
    final pdfs = files.where((f) => f.isPdf).toList();
    if (pdfs.isEmpty) return null;
    if (pdfs.length == 1) return pdfs.first;

    // Look for PDFs containing the type keyword + number
    // e.g. "ASI #1 19514.05 (2020-07-02).pdf" or "RFI #1 - Request For Information.pdf"
    final typeKey = caType.toLowerCase();
    final numOnly = RegExp(r'\d+').firstMatch(number)?.group(0) ?? '';

    // Priority 1: Contains the type and number pattern
    for (final f in pdfs) {
      final lower = f.name.toLowerCase();
      if (lower.contains(typeKey) && lower.contains(numOnly)) return f;
    }

    // Priority 2: Contains "executed" or "response" (for Change Orders / RFIs)
    for (final f in pdfs) {
      final lower = f.name.toLowerCase();
      if (lower.contains('executed') || lower.contains('response') || lower.contains('request')) return f;
    }

    // Priority 3: The newest PDF
    pdfs.sort((a, b) => b.modified.compareTo(a.modified));
    return pdfs.first;
  }

  /// Extract description from a PDF filename.
  /// e.g. "RFI 0003 - Column Line 5 to X1 Dimension - Jul 09 2020.pdf"
  ///   → "Column Line 5 to X1 Dimension"
  static String _descriptionFromFilename(String caType, String filename) {
    var name = _stripExt(filename);

    // Remove project number patterns (5+ digits optionally with dots)
    name = name.replaceAll(RegExp(r'\d{5,}\.?\d*'), '').trim();

    // Remove date patterns
    name = name.replaceAll(RegExp(r'\d{4}[\-\.]\d{2}[\-\.]\d{2}'), '').trim();
    name = name.replaceAll(RegExp(r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\s+\d{4}', caseSensitive: false), '').trim();

    // Remove the CA type and number
    name = name.replaceAll(RegExp('${caType}[\\s#]*\\d+', caseSensitive: false), '').trim();
    name = name.replaceAll(RegExp(r'^[\s\-–—,()]+'), '').trim();
    name = name.replaceAll(RegExp(r'[\s\-–—,()]+$'), '').trim();

    // Remove common suffixes
    name = name.replaceAll(RegExp(r'\s*[\(\[]\s*(NET|ETN|MCN|R&R|SB REVIEWED)\s*[\)\]]?\s*$', caseSensitive: false), '').trim();

    // Clean up double separators
    name = name.replaceAll(RegExp(r'\s*[\-–—]\s*[\-–—]\s*'), ' - ').trim();
    name = name.replaceAll(RegExp(r'^[\s\-–—]+|[\s\-–—]+$'), '').trim();

    return name;
  }

  /// Extract sheet numbers from filenames in the folder.
  /// Looks for patterns like A1.01, S1-2, E0-0, etc.
  static List<String> _extractSheetNumbers(List<CaFile> files) {
    final sheetPattern = RegExp(r'^[A-Za-z]{1,3}\d+[.\-][\d.\-]*\d');
    final sheets = <String>{};
    for (final f in files) {
      if (!f.isPdf) continue;
      final name = _stripExt(f.name);
      final match = sheetPattern.firstMatch(name);
      if (match != null) {
        sheets.add(match.group(0)!.toUpperCase());
      }
    }
    final sorted = sheets.toList()..sort();
    return sorted;
  }

  /// Extract status from folder name + filenames.
  static String _extractStatus(String caType, List<CaFile> files, {String? folderName}) {
    // Check folder name first — most reliable signal
    if (folderName != null) {
      final lowerFolder = folderName.toLowerCase();
      if (lowerFolder.endsWith('- closed') || lowerFolder.contains('- closed')) return 'Closed';
      if (lowerFolder.contains('(void)')) return 'Void';
      if (lowerFolder.contains('(rejected)')) return 'Rejected';
      if (lowerFolder.contains('(cancelled)') || lowerFolder.contains('(canceled)')) return 'Cancelled';
    }

    for (final f in files) {
      final lower = f.name.toLowerCase();
      if (lower.contains('executed') || lower.contains('fully executed')) return 'Executed';
      if (lower.contains('response') || lower.contains('responded')) return 'Responded';
      if (lower.contains('approved')) return 'Approved';
      if (lower.contains('rejected')) return 'Rejected';
      if (lower.contains('void')) return 'Void';
      if (lower.contains('reviewed') || lower.contains('sb reviewed')) return 'Reviewed';
      if (lower.contains('r&r') || lower.contains('revise')) return 'Revise & Resubmit';
    }

    // Check for draft status (lower priority — files with "draft" may exist alongside final)
    for (final f in files) {
      final lower = f.name.toLowerCase();
      if (lower.contains('draft')) return 'Draft';
    }

    // Check common status codes in submittal filenames: (NET), (ETN), (MCN)
    for (final f in files) {
      final lower = f.name.toLowerCase();
      if (RegExp(r'\(net\)').hasMatch(lower)) return 'No Exception Taken';
      if (RegExp(r'\(etn\)').hasMatch(lower)) return 'Exception Taken - Noted';
      if (RegExp(r'\(mcn\)').hasMatch(lower)) return 'Make Corrections Noted';
    }

    // Default by type
    return switch (caType) {
      'RFI' => 'Open',
      'ASI' => 'Issued',
      'CO'  => 'Pending',
      'RFC' => 'Pending',
      'SUB' => 'Pending',
      'PL'  => 'Open',
      _     => 'Filed',
    };
  }

  /// Try to extract "issued by" from filenames.
  /// Looks for patterns like "SB" in "(SB REVIEWED)" or architect initials.
  static String? _extractIssuedBy(List<CaFile> files) {
    for (final f in files) {
      final m = RegExp(r'[\(\[]([A-Z]{2,4})\s*(?:REVIEWED|REVIEW)?[\)\]]', caseSensitive: false).firstMatch(f.name);
      if (m != null) {
        final initials = m.group(1)!.toUpperCase();
        // Skip status codes
        if (!{'NET', 'ETN', 'MCN', 'R&R', 'PDF', 'DWG'}.contains(initials)) {
          return initials;
        }
      }
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════
  // UTILITY HELPERS
  // ════════════════════════════════════════════════════════════

  static DateTime? _parseDate(String dateStr) {
    try {
      final cleaned = dateStr.replaceAll('.', '-');
      return DateTime.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _newestDate(List<CaFile> files) {
    if (files.isEmpty) return null;
    return files.map((f) => f.modified).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  static String _ext(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot >= 0 ? filename.substring(dot).toLowerCase() : '';
  }

  static String _stripExt(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot >= 0 ? filename.substring(0, dot) : filename;
  }

  /// Natural sort comparison: "RFI #2" before "RFI #10"
  static int _naturalCompare(String a, String b) {
    final aNum = RegExp(r'\d+').allMatches(a).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    final bNum = RegExp(r'\d+').allMatches(b).map((m) => int.tryParse(m.group(0)!) ?? 0).toList();
    for (int i = 0; i < aNum.length && i < bNum.length; i++) {
      final cmp = aNum[i].compareTo(bNum[i]);
      if (cmp != 0) return cmp;
    }
    return a.compareTo(b);
  }
}
