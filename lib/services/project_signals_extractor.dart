import '../models/project_signals.dart';
import '../models/project_models.dart';
import '../models/scanned_file.dart';
import '../models/ca_entry.dart';
import 'folder_scan_service.dart' show DiscoveredMilestone, PhaseFileActivity;

class ProjectSignalsExtractor {
  ProjectSignalsExtractor._();

  // Phase weight constants (tuneable)
  static const _phaseWeights = <String, double>{
    'Schematic Design': 0.15,
    'Design Development': 0.20,
    'Construction Documents': 0.30,
    'Permitting': 0.10,
    'Bidding & Negotiation': 0.10,
    'Construction Admin': 0.15,
  };

  // Filename milestone tokens
  static final _milestoneTokens = RegExp(
    r'(sd\s*submittal|dd\s*submittal|cd\s*(50|90|100|final)|'
    r'permit\s*set|bid\s*set|ifa\s*set|ifc\s*set|'
    r'addendum|notice\s*to\s*proceed|ntp|'
    r'substantial\s*completion|certificate\s*of\s*occupancy)',
    caseSensitive: false,
  );

  // Date extraction from filenames
  static final _datePatterns = [
    RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
    RegExp(r'(\d{2})-(\d{2})-(\d{4})'),
    RegExp(r'(\d{2})(\d{2})(\d{2})(?!\d)'),
  ];

  // Phase evidence keywords
  static const _phaseKeywords = <String, List<String>>{
    'Schematic Design': ['sd', 'schematic', 'concept', 'preliminary'],
    'Design Development': ['dd', 'design development', 'coordination'],
    'Construction Documents': ['cd', 'issued for permit', 'permit set', 'bid set', 'construction doc'],
    'Permitting': ['permit', 'agency review', 'plan check', 'building department'],
    'Bidding & Negotiation': ['bid', 'addendum', 'rfp', 'proposal', 'negotiation'],
    'Construction Admin': ['rfi', 'asi', 'submittal', 'co', 'change order', 'punch'],
  };

  /// Main extraction entry point. Pure function, no side effects.
  static ProjectSignals extract({
    required List<SchedulePhase> schedulePhases,
    required List<Deadline> deadlines,
    required List<RfiItem> manualRfis,
    required List<TodoItem> todos,
    required List<DiscoveredMilestone> discoveredMilestones,
    required Map<String, PhaseFileActivity> phaseFileActivity,
    required List<ScannedFile> allDrawings,
    required List<CaEntry> scannedRfis,
    required List<CaEntry> scannedSubmittals,
    required List<CaEntry> scannedChangeOrders,
    required List<SubmittalItem> manualSubmittals,
    required List<ChangeOrder> manualChangeOrders,
  }) {
    final milestones = _extractMilestones(
      deadlines: deadlines,
      discovered: discoveredMilestones,
      allDrawings: allDrawings,
    );

    final rfiCounts = _extractRfiCounts(scannedRfis, manualRfis);
    final subCounts = _extractSubmittalCounts(scannedSubmittals, manualSubmittals);
    final coCounts = _extractChangeOrderCounts(scannedChangeOrders, manualChangeOrders);
    final pendingTodos = todos.where((t) => !t.done).length;

    final phaseTimeline = _buildPhaseTimeline(
      schedulePhases: schedulePhases,
      phaseFileActivity: phaseFileActivity,
      allDrawings: allDrawings,
    );

    final overallProgress = _computeOverallProgress(phaseTimeline);
    final phasesComplete = phaseTimeline.where((p) => p.percent >= 0.95).length;
    final recentFiles = _extractRecentFiles(allDrawings);

    return ProjectSignals(
      overallProgress: overallProgress,
      phasesComplete: phasesComplete,
      phasesTotal: phaseTimeline.length,
      openRfis: rfiCounts.open,
      pendingRfis: rfiCounts.pending,
      totalRfis: rfiCounts.total,
      pendingTodos: pendingTodos,
      totalTodos: todos.length,
      openSubmittals: subCounts.open,
      totalSubmittals: subCounts.total,
      openChangeOrders: coCounts.open,
      totalChangeOrders: coCounts.total,
      milestones: milestones,
      phaseTimeline: phaseTimeline,
      recentFiles: recentFiles,
      lastComputedAt: DateTime.now(),
      totalFilesScanned: allDrawings.length,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MILESTONES
  // ═══════════════════════════════════════════════════════════

  static List<ProjectMilestone> _extractMilestones({
    required List<Deadline> deadlines,
    required List<DiscoveredMilestone> discovered,
    required List<ScannedFile> allDrawings,
  }) {
    final result = <ProjectMilestone>[];
    int idCounter = 0;

    // 1. Structured deadlines (highest confidence)
    for (final dl in deadlines) {
      result.add(ProjectMilestone(
        id: 'dl_${idCounter++}',
        label: dl.label,
        dueDate: dl.date,
        source: 'deadlines',
        confidence: SignalConfidence.structured,
      ));
    }

    // 2. Discovered milestones from folder scanning
    for (final m in discovered) {
      final isDupe = result.any((r) =>
          r.label.toLowerCase() == m.label.toLowerCase() &&
          (r.dueDate.difference(m.date).inDays).abs() < 7);
      if (!isDupe) {
        result.add(ProjectMilestone(
          id: 'disc_${idCounter++}',
          label: m.label,
          dueDate: m.date,
          source: 'folder:${m.source}',
          confidence: SignalConfidence.filenameDated,
        ));
      }
    }

    // 3. Filename-based milestone inference from drawings
    final seen = <String>{};
    for (final f in allDrawings) {
      final match = _milestoneTokens.firstMatch(f.name.toLowerCase());
      if (match == null) continue;
      final token = (match.group(0) ?? '').trim().toLowerCase();
      if (seen.contains(token)) continue;
      seen.add(token);

      final date = _extractDateFromFilename(f.name) ?? f.modified;
      final confidence = _extractDateFromFilename(f.name) != null
          ? SignalConfidence.filenameDated
          : SignalConfidence.filenameOnly;

      final isDupe = result.any((r) =>
          r.label.toLowerCase().contains(token) ||
          token.contains(r.label.toLowerCase()));
      if (!isDupe) {
        result.add(ProjectMilestone(
          id: 'fn_${idCounter++}',
          label: _prettifyToken(token),
          dueDate: date,
          source: 'filename:${f.name}',
          confidence: confidence,
        ));
      }
    }

    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  static DateTime? _extractDateFromFilename(String name) {
    // YYYY-MM-DD
    final m1 = _datePatterns[0].firstMatch(name);
    if (m1 != null) {
      return DateTime.tryParse('${m1.group(1)}-${m1.group(2)}-${m1.group(3)}');
    }
    // MM-DD-YYYY
    final m2 = _datePatterns[1].firstMatch(name);
    if (m2 != null) {
      return DateTime.tryParse('${m2.group(3)}-${m2.group(1)}-${m2.group(2)}');
    }
    // MMDDYY
    final m3 = _datePatterns[2].firstMatch(name);
    if (m3 != null) {
      final yy = int.tryParse(m3.group(3)!) ?? 0;
      final yyyy = yy > 50 ? 1900 + yy : 2000 + yy;
      final mm = int.tryParse(m3.group(1)!) ?? 1;
      final dd = int.tryParse(m3.group(2)!) ?? 1;
      if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) {
        return DateTime(yyyy, mm, dd);
      }
    }
    return null;
  }

  static String _prettifyToken(String token) {
    return token
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  // ═══════════════════════════════════════════════════════════
  // RFI COUNTS
  // ═══════════════════════════════════════════════════════════

  static ({int open, int pending, int total}) _extractRfiCounts(
    List<CaEntry> scannedRfis,
    List<RfiItem> manualRfis,
  ) {
    if (scannedRfis.isNotEmpty) {
      final open = scannedRfis.where((r) => r.status == 'Open').length;
      final pending = scannedRfis.where((r) =>
          r.status != 'Open' && r.status != 'Closed' && r.status != 'Responded').length;
      return (open: open, pending: pending, total: scannedRfis.length);
    }
    final open = manualRfis.where((r) => r.status == 'Open').length;
    final pending = manualRfis.where((r) => r.status == 'Pending').length;
    return (open: open, pending: pending, total: manualRfis.length);
  }

  // ═══════════════════════════════════════════════════════════
  // SUBMITTAL COUNTS
  // ═══════════════════════════════════════════════════════════

  static ({int open, int total}) _extractSubmittalCounts(
    List<CaEntry> scannedSubs,
    List<SubmittalItem> manualSubs,
  ) {
    if (scannedSubs.isNotEmpty) {
      final open = scannedSubs.where((s) =>
          s.status != 'Approved' && s.status != 'No Exception Taken').length;
      return (open: open, total: scannedSubs.length);
    }
    final open = manualSubs.where((s) =>
        s.status != 'Approved' && s.status != 'Approved as Noted').length;
    return (open: open, total: manualSubs.length);
  }

  // ═══════════════════════════════════════════════════════════
  // CHANGE ORDER COUNTS
  // ═══════════════════════════════════════════════════════════

  static ({int open, int total}) _extractChangeOrderCounts(
    List<CaEntry> scannedCOs,
    List<ChangeOrder> manualCOs,
  ) {
    if (scannedCOs.isNotEmpty) {
      final open = scannedCOs.where((c) =>
          c.status != 'Executed' && c.status != 'Approved' && c.status != 'Rejected').length;
      return (open: open, total: scannedCOs.length);
    }
    final open = manualCOs.where((c) =>
        c.status == 'Pending').length;
    return (open: open, total: manualCOs.length);
  }

  // ═══════════════════════════════════════════════════════════
  // PHASE TIMELINE — merge structured schedule with file evidence
  // ═══════════════════════════════════════════════════════════

  static List<ProjectPhaseStatus> _buildPhaseTimeline({
    required List<SchedulePhase> schedulePhases,
    required Map<String, PhaseFileActivity> phaseFileActivity,
    required List<ScannedFile> allDrawings,
  }) {
    if (schedulePhases.isNotEmpty) {
      return schedulePhases.map((phase) {
        final activity = phaseFileActivity[phase.name];
        return ProjectPhaseStatus(
          phaseName: phase.name,
          start: phase.start,
          end: phase.end,
          percent: phase.progress,
          status: phase.status,
          fileCount: activity?.fileCount ?? 0,
        );
      }).toList();
    }

    return _inferPhasesFromFiles(allDrawings, phaseFileActivity);
  }

  /// Infer phase statuses purely from scanned file names and dates.
  static List<ProjectPhaseStatus> _inferPhasesFromFiles(
    List<ScannedFile> allDrawings,
    Map<String, PhaseFileActivity> phaseFileActivity,
  ) {
    final now = DateTime.now();
    final result = <ProjectPhaseStatus>[];

    for (final entry in _phaseKeywords.entries) {
      final phaseName = entry.key;
      final keywords = entry.value;

      final matchingFiles = allDrawings.where((f) {
        final lower = f.name.toLowerCase();
        return keywords.any((kw) => lower.contains(kw));
      }).toList();

      final activity = phaseFileActivity[phaseName];
      final fileCount = activity?.fileCount ?? matchingFiles.length;

      double percent = 0;
      String status = 'Not Started';
      DateTime? start;
      DateTime? end;

      if (activity != null) {
        start = activity.earliestFile;
        end = activity.latestFile;
        final daysSinceLatest = now.difference(activity.latestFile).inDays;
        if (fileCount > 0 && daysSinceLatest > 60) {
          percent = 1.0;
          status = 'Complete';
        } else if (fileCount > 0) {
          percent = 0.5;
          status = 'In Progress';
        }
      } else if (matchingFiles.isNotEmpty) {
        matchingFiles.sort((a, b) => a.modified.compareTo(b.modified));
        start = matchingFiles.first.modified;
        end = matchingFiles.last.modified;
        final daysSinceLatest = now.difference(end).inDays;
        if (daysSinceLatest > 60) {
          percent = 1.0;
          status = 'Complete';
        } else {
          percent = 0.5;
          status = 'In Progress';
        }
      }

      result.add(ProjectPhaseStatus(
        phaseName: phaseName,
        start: start,
        end: end,
        percent: percent,
        status: status,
        fileCount: fileCount,
      ));
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // OVERALL PROGRESS — weighted by phase importance
  // ═══════════════════════════════════════════════════════════

  static double _computeOverallProgress(List<ProjectPhaseStatus> phases) {
    if (phases.isEmpty) return 0;

    double weightedSum = 0;
    double totalWeight = 0;

    for (final phase in phases) {
      final weight = _phaseWeights[phase.phaseName] ?? (1.0 / phases.length);
      weightedSum += phase.percent * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? (weightedSum / totalWeight).clamp(0, 1) : 0;
  }

  // ═══════════════════════════════════════════════════════════
  // RECENT FILES — top 10 by modification date
  // ═══════════════════════════════════════════════════════════

  static List<ScannedFile> _extractRecentFiles(List<ScannedFile> allDrawings) {
    if (allDrawings.isEmpty) return const [];
    final sorted = [...allDrawings]..sort((a, b) => b.modified.compareTo(a.modified));
    return sorted.take(10).toList();
  }
}
