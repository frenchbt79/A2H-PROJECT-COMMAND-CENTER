import 'package:flutter/material.dart';
import 'scanned_file.dart';

/// Confidence level for inferred data.
enum SignalConfidence {
  /// From structured provider data (deadlines, schedule, RFIs).
  structured(1.0),
  /// From filename with explicit date token.
  filenameDated(0.7),
  /// From filename pattern only (no date).
  filenameOnly(0.4),
  /// Inferred from folder existence / file counts.
  inferred(0.5);

  final double value;
  const SignalConfidence(this.value);
}

/// A milestone discovered from project data.
@immutable
class ProjectMilestone {
  final String id;
  final String label;
  final DateTime dueDate;
  final String source; // e.g. 'deadlines', 'folder:SD Submittal', 'filename'
  final SignalConfidence confidence;

  const ProjectMilestone({
    required this.id,
    required this.label,
    required this.dueDate,
    required this.source,
    required this.confidence,
  });
}

/// Status of a project phase, computed from file evidence.
@immutable
class ProjectPhaseStatus {
  final String phaseName;
  final DateTime? start;
  final DateTime? end;
  final double percent; // 0.0–1.0
  final String status; // 'Complete', 'In Progress', 'Upcoming', 'Not Started'
  final int fileCount;

  const ProjectPhaseStatus({
    required this.phaseName,
    this.start,
    this.end,
    required this.percent,
    required this.status,
    required this.fileCount,
  });
}

/// Aggregated project signals — the single source of truth for dashboard KPIs.
@immutable
class ProjectSignals {
  /// Overall project progress (0.0–1.0), weighted across phases.
  final double overallProgress;

  /// Number of phases considered complete (>= 95%).
  final int phasesComplete;

  /// Total number of tracked phases.
  final int phasesTotal;

  /// Open RFIs — from CA scan or manual provider.
  final int openRfis;

  /// Pending RFIs — submitted but not responded.
  final int pendingRfis;

  /// Total RFI count.
  final int totalRfis;

  /// Pending to-dos (not done).
  final int pendingTodos;

  /// Total to-do count.
  final int totalTodos;

  /// Open submittals.
  final int openSubmittals;

  /// Total submittals.
  final int totalSubmittals;

  /// Open change orders.
  final int openChangeOrders;

  /// Total change orders.
  final int totalChangeOrders;

  /// Combined milestones from all sources, sorted by date.
  final List<ProjectMilestone> milestones;

  /// Per-phase status with computed progress.
  final List<ProjectPhaseStatus> phaseTimeline;

  /// Most recently modified files across all scans.
  final List<ScannedFile> recentFiles;

  /// When the signals were last computed.
  final DateTime lastComputedAt;

  /// Total scanned file count.
  final int totalFilesScanned;

  const ProjectSignals({
    required this.overallProgress,
    required this.phasesComplete,
    required this.phasesTotal,
    required this.openRfis,
    required this.pendingRfis,
    required this.totalRfis,
    required this.pendingTodos,
    required this.totalTodos,
    required this.openSubmittals,
    required this.totalSubmittals,
    required this.openChangeOrders,
    required this.totalChangeOrders,
    required this.milestones,
    required this.phaseTimeline,
    required this.recentFiles,
    required this.lastComputedAt,
    required this.totalFilesScanned,
  });

  /// Empty/default signals for when no data is available.
  factory ProjectSignals.empty() => ProjectSignals(
    overallProgress: 0,
    phasesComplete: 0,
    phasesTotal: 0,
    openRfis: 0,
    pendingRfis: 0,
    totalRfis: 0,
    pendingTodos: 0,
    totalTodos: 0,
    openSubmittals: 0,
    totalSubmittals: 0,
    openChangeOrders: 0,
    totalChangeOrders: 0,
    milestones: const [],
    phaseTimeline: const [],
    recentFiles: const [],
    lastComputedAt: DateTime.fromMillisecondsSinceEpoch(0),
    totalFilesScanned: 0,
  );
}
