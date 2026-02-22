import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_signals.dart';
import '../models/ca_entry.dart';
import '../models/scanned_file.dart';
import '../services/project_signals_extractor.dart';
import '../services/folder_scan_service.dart' show DiscoveredMilestone, PhaseFileActivity;
import 'folder_scan_providers.dart';
import 'ca_scan_providers.dart';
import 'project_providers.dart';

/// Main provider \u2014 watches all data sources and recomputes signals.
/// Uses keepAlive so the result persists across page switches.
final projectSignalsProvider = FutureProvider<ProjectSignals>((ref) async {
  ref.keepAlive();

  // Trigger recomputation on scan refresh
  ref.watch(scanRefreshProvider);

  // \u2500\u2500 Gather all inputs \u2500\u2500

  // Structured providers (synchronous \u2014 SharedPreferences-backed)
  final schedulePhases = ref.watch(scheduleProvider);
  final deadlines = ref.watch(deadlinesProvider);
  final manualRfis = ref.watch(rfisProvider);
  final todos = ref.watch(todosProvider);
  final manualSubmittals = ref.watch(submittalsProvider);
  final manualChangeOrders = ref.watch(changeOrdersProvider);

  // Scan-based providers (async \u2014 may still be loading)
  final allDrawings = ref.watch(_allDrawingsForSignals).valueOrNull ?? <ScannedFile>[];
  final discoveredMilestones = ref.watch(discoveredMilestonesProvider).valueOrNull ?? <DiscoveredMilestone>[];
  final phaseFileActivity = ref.watch(phaseFileDatesProvider).valueOrNull ?? <String, PhaseFileActivity>{};
  final scannedRfis = ref.watch(scannedCaRfisProvider).valueOrNull ?? <CaEntry>[];
  final scannedSubmittals = ref.watch(scannedCaSubmittalsProvider).valueOrNull ?? <CaEntry>[];
  final scannedChangeOrders = ref.watch(scannedCaChangeOrdersProvider).valueOrNull ?? <CaEntry>[];

  // \u2500\u2500 Run extractor \u2500\u2500
  return ProjectSignalsExtractor.extract(
    schedulePhases: schedulePhases,
    deadlines: deadlines,
    manualRfis: manualRfis,
    todos: todos,
    discoveredMilestones: discoveredMilestones,
    phaseFileActivity: phaseFileActivity,
    allDrawings: allDrawings,
    scannedRfis: scannedRfis,
    scannedSubmittals: scannedSubmittals,
    scannedChangeOrders: scannedChangeOrders,
    manualSubmittals: manualSubmittals,
    manualChangeOrders: manualChangeOrders,
  );
});

/// Re-use the cached all-files provider instead of doing a separate I: drive scan.
/// This was previously doing svc.scanFolderRecursive() which duplicated the
/// entire project tree walk on every signal recomputation.
final _allDrawingsForSignals = FutureProvider<List<ScannedFile>>((ref) async {
  ref.keepAlive();
  final allFiles = await ref.watch(allProjectFilesProvider.future);
  final drawingsPath = r'0 Project Management\Construction Documents\Scanned Drawings'.toLowerCase();
  return allFiles.where((f) {
    final rel = f.relativePath.toLowerCase();
    return rel.startsWith(drawingsPath) && f.extension.toLowerCase() == '.pdf';
  }).toList();
});
