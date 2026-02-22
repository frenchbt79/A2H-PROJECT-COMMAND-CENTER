import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';

/// ═══════════════════════════════════════════════════════════
/// TITLE BLOCK READER — AI extracts metadata from drawing PDFs
/// ═══════════════════════════════════════════════════════════
///
/// HOW THIS WORKS:
///
/// Every architecture drawing has a title block (usually bottom-right corner)
/// containing: project number, sheet number, sheet title, revision, date,
/// drawn-by, checked-by, firm name, etc.
///
/// We send the PDF to Claude's vision API. Claude "reads" the title block
/// and returns structured JSON with all the extracted fields.
///
/// WHY THIS MATTERS:
/// - Validates that filenames match actual sheet numbers
/// - Catches wrong project numbers on sheets (common copy/paste error)
/// - Verifies revision dates are sequential
/// - Auto-populates drawing log from actual documents
///
/// THE PROMPT PATTERN:
/// This uses "structured extraction" — we tell Claude exactly what
/// JSON format to return, and it fills in the values from what it sees.
/// Temperature = 0 means deterministic (same input → same output).

class TitleBlockReader {
  final AiService _ai;

  TitleBlockReader(this._ai);

  /// The system prompt — this is the "brain" of the feature.
  ///
  /// PROMPT ENGINEERING NOTES:
  /// 1. We specify the EXACT JSON schema we want back
  /// 2. We tell it to return null for fields it can't find (not guess)
  /// 3. We give it domain context (AEC, title blocks) so it knows what to look for
  /// 4. We keep it focused — just extraction, no commentary
  static const _systemPrompt = '''
You are an architectural drawing title block reader. You analyze construction 
document PDFs and extract metadata from the title block.

Extract these fields and respond ONLY with a JSON object (no markdown, no explanation):

{
  "project_number": "string or null — the project/job number",
  "project_name": "string or null — the project name",
  "sheet_number": "string or null — e.g. A1.01, S2.03, M1.01",
  "sheet_title": "string or null — e.g. FLOOR PLAN - LEVEL 1",
  "discipline": "string or null — one of: General, Architectural, Structural, Civil, Landscape, Mechanical, Electrical, Plumbing, Fire Protection",
  "revision_number": "string or null — latest revision number or letter",
  "revision_date": "string or null — date of latest revision, ISO format YYYY-MM-DD",
  "issue_date": "string or null — original issue date, ISO format YYYY-MM-DD",
  "drawn_by": "string or null — initials of drafter",
  "checked_by": "string or null — initials of checker",
  "approved_by": "string or null — initials of approver",
  "scale": "string or null — e.g. 1/4\\" = 1'-0\\"",
  "firm_name": "string or null — architecture/engineering firm name",
  "client_name": "string or null — owner/client name if visible",
  "phase": "string or null — e.g. Construction Documents, Schematic Design, DD",
  "seal_present": "boolean — true if a professional seal/stamp is visible",
  "confidence": "number 0.0-1.0 — your confidence in the extraction accuracy"
}

Rules:
- Return null for any field you cannot find or read clearly
- For dates, convert to ISO YYYY-MM-DD format
- For sheet_number, preserve the original format (A1.01, not a1.01)
- The discipline is derived from the sheet prefix letter(s)
- If multiple revisions exist, report the LATEST one
- confidence should reflect how clearly you can read the title block
''';

  /// Extract title block metadata from a PDF file.
  ///
  /// Returns a [TitleBlockData] with all extracted fields,
  /// or throws [AiServiceException] on failure.
  Future<TitleBlockData> readPdf(String pdfPath) async {
    if (kIsWeb) throw AiServiceException('PDF reading not available on Web');

    final file = File(pdfPath);
    if (!await file.exists()) {
      throw AiServiceException('File not found: $pdfPath');
    }

    final bytes = await file.readAsBytes();

    // Size check — Claude accepts up to 32MB but large files are slow + expensive
    final sizeMb = bytes.length / (1024 * 1024);
    if (sizeMb > 25) {
      throw AiServiceException('PDF too large (${sizeMb.toStringAsFixed(1)}MB). Max 25MB.');
    }

    debugPrint('[TITLE-BLOCK] Reading: $pdfPath (${sizeMb.toStringAsFixed(1)}MB)');

    final json = await _ai.analyzePdfJson(
      systemPrompt: _systemPrompt,
      userPrompt: 'Extract the title block information from this construction drawing.',
      pdfBytes: bytes,
      maxTokens: 512, // Title block data is small — cap the response
    );

    return TitleBlockData.fromJson(json, sourcePath: pdfPath);
  }

  /// Read title blocks from multiple PDFs. Returns results in order.
  /// Continues on individual failures (returns error in the result).
  Future<List<TitleBlockResult>> readMultiple(List<String> pdfPaths, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <TitleBlockResult>[];
    for (int i = 0; i < pdfPaths.length; i++) {
      try {
        final data = await readPdf(pdfPaths[i]);
        results.add(TitleBlockResult(path: pdfPaths[i], data: data));
      } catch (e) {
        results.add(TitleBlockResult(path: pdfPaths[i], error: e.toString()));
      }
      onProgress?.call(i + 1, pdfPaths.length);
    }
    return results;
  }
}

/// Structured data from a title block extraction.
class TitleBlockData {
  final String sourcePath;
  final String? projectNumber;
  final String? projectName;
  final String? sheetNumber;
  final String? sheetTitle;
  final String? discipline;
  final String? revisionNumber;
  final DateTime? revisionDate;
  final DateTime? issueDate;
  final String? drawnBy;
  final String? checkedBy;
  final String? approvedBy;
  final String? scale;
  final String? firmName;
  final String? clientName;
  final String? phase;
  final bool sealPresent;
  final double confidence;

  const TitleBlockData({
    required this.sourcePath,
    this.projectNumber,
    this.projectName,
    this.sheetNumber,
    this.sheetTitle,
    this.discipline,
    this.revisionNumber,
    this.revisionDate,
    this.issueDate,
    this.drawnBy,
    this.checkedBy,
    this.approvedBy,
    this.scale,
    this.firmName,
    this.clientName,
    this.phase,
    this.sealPresent = false,
    this.confidence = 0.0,
  });

  factory TitleBlockData.fromJson(Map<String, dynamic> j, {required String sourcePath}) {
    return TitleBlockData(
      sourcePath: sourcePath,
      projectNumber: j['project_number'] as String?,
      projectName: j['project_name'] as String?,
      sheetNumber: j['sheet_number'] as String?,
      sheetTitle: j['sheet_title'] as String?,
      discipline: j['discipline'] as String?,
      revisionNumber: j['revision_number'] as String?,
      revisionDate: _parseDate(j['revision_date']),
      issueDate: _parseDate(j['issue_date']),
      drawnBy: j['drawn_by'] as String?,
      checkedBy: j['checked_by'] as String?,
      approvedBy: j['approved_by'] as String?,
      scale: j['scale'] as String?,
      firmName: j['firm_name'] as String?,
      clientName: j['client_name'] as String?,
      phase: j['phase'] as String?,
      sealPresent: j['seal_present'] as bool? ?? false,
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v as String);
    } catch (_) {
      return null;
    }
  }

  /// Check if the filename matches the extracted sheet number.
  /// Returns null if no mismatch, or a description of the problem.
  String? validateFilename(String filename) {
    if (sheetNumber == null) return null;
    final normalized = sheetNumber!.replaceAll(' ', '').toUpperCase();
    final fnUpper = filename.toUpperCase();
    if (!fnUpper.startsWith(normalized) && !fnUpper.contains(normalized)) {
      return 'Filename "$filename" doesn\'t match extracted sheet "$sheetNumber"';
    }
    return null;
  }

  /// Check if the project number matches what we expect.
  String? validateProjectNumber(String expectedNumber) {
    if (projectNumber == null) return null;
    if (!projectNumber!.contains(expectedNumber)) {
      return 'Sheet shows project "$projectNumber" but expected "$expectedNumber"';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'source_path': sourcePath,
    'project_number': projectNumber,
    'project_name': projectName,
    'sheet_number': sheetNumber,
    'sheet_title': sheetTitle,
    'discipline': discipline,
    'revision_number': revisionNumber,
    'revision_date': revisionDate?.toIso8601String(),
    'issue_date': issueDate?.toIso8601String(),
    'drawn_by': drawnBy,
    'checked_by': checkedBy,
    'approved_by': approvedBy,
    'scale': scale,
    'firm_name': firmName,
    'client_name': clientName,
    'phase': phase,
    'seal_present': sealPresent,
    'confidence': confidence,
  };
}

/// Result wrapper for batch processing — either data or error.
class TitleBlockResult {
  final String path;
  final TitleBlockData? data;
  final String? error;

  const TitleBlockResult({required this.path, this.data, this.error});
  bool get isSuccess => data != null;
  bool get isError => error != null;
}
