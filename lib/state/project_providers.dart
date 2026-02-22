import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../services/storage_service.dart';
import '../main.dart' show storageServiceProvider;
import 'folder_scan_providers.dart' show activeProjectIdProvider, projectsProvider;
import 'default_data.dart';

// ═══════════════════════════════════════════════════════════
// MUTABLE PROVIDERS (StateNotifier — auto-save on mutation)
// ═══════════════════════════════════════════════════════════

class TeamNotifier extends StateNotifier<List<TeamMember>> {
  final StorageService _storage;

  TeamNotifier(this._storage) : super([]) {
    final saved = _storage.loadTeam();
    state = saved.isNotEmpty ? saved : DefaultData.team;
    if (saved.isEmpty) _storage.saveTeam(state);
  }

  void add(TeamMember member) {
    state = [...state, member];
    _storage.saveTeam(state);
  }

  void remove(String id) {
    state = state.where((m) => m.id != id).toList();
    _storage.saveTeam(state);
  }

  void update(TeamMember updated) {
    state = [
      for (final m in state)
        if (m.id == updated.id) updated else m,
    ];
    _storage.saveTeam(state);
  }
}

final teamProvider = StateNotifierProvider<TeamNotifier, List<TeamMember>>((ref) {
  ref.watch(activeProjectIdProvider);
  return TeamNotifier(ref.watch(storageServiceProvider));
});

class RfiNotifier extends StateNotifier<List<RfiItem>> {
  final StorageService _storage;

  RfiNotifier(this._storage) : super([]) {
    final saved = _storage.loadRfis();
    state = saved.isNotEmpty ? saved : DefaultData.rfis;
    if (saved.isEmpty) _storage.saveRfis(state);
  }

  void add(RfiItem rfi) {
    state = [...state, rfi];
    _storage.saveRfis(state);
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _storage.saveRfis(state);
  }

  void update(RfiItem rfi) {
    state = [
      for (final r in state)
        if (r.id == rfi.id) rfi else r,
    ];
    _storage.saveRfis(state);
  }

  String nextNumber() {
    final nums = state.map((r) {
      final match = RegExp(r'RFI-(\d+)').firstMatch(r.number);
      return match != null ? int.parse(match.group(1)!) : 0;
    });
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'RFI-${(max + 1).toString().padLeft(3, '0')}';
  }
}

final rfisProvider = StateNotifierProvider<RfiNotifier, List<RfiItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return RfiNotifier(ref.watch(storageServiceProvider));
});

// ═══════════════════════════════════════════════════════════
// READ-ONLY PROVIDERS (load from storage or seed defaults)
// ═══════════════════════════════════════════════════════════

class ContractNotifier extends StateNotifier<List<ContractItem>> {
  final StorageService _storage;

  ContractNotifier(this._storage) : super([]) {
    final saved = _storage.loadContracts();
    state = saved.isNotEmpty ? saved : DefaultData.contracts;
    if (saved.isEmpty) _storage.saveContracts(state);
  }

  void add(ContractItem item) {
    state = [...state, item];
    _storage.saveContracts(state);
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    _storage.saveContracts(state);
  }

  void update(ContractItem item) {
    state = [
      for (final c in state)
        if (c.id == item.id) item else c,
    ];
    _storage.saveContracts(state);
  }
}

final contractsProvider = StateNotifierProvider<ContractNotifier, List<ContractItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return ContractNotifier(ref.watch(storageServiceProvider));
});

class ScheduleNotifier extends StateNotifier<List<SchedulePhase>> {
  final StorageService _storage;

  ScheduleNotifier(this._storage) : super([]) {
    final saved = _storage.loadSchedule();
    state = saved.isNotEmpty ? saved : DefaultData.schedule;
    if (saved.isEmpty) _storage.saveSchedule(state);
  }

  void add(SchedulePhase item) {
    state = [...state, item];
    _storage.saveSchedule(state);
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
    _storage.saveSchedule(state);
  }

  void update(SchedulePhase item) {
    state = [
      for (final s in state)
        if (s.id == item.id) item else s,
    ];
    _storage.saveSchedule(state);
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<SchedulePhase>>((ref) {
  ref.watch(activeProjectIdProvider);
  return ScheduleNotifier(ref.watch(storageServiceProvider));
});

/// Computed overall project progress (0.0–1.0) from schedule phases.
/// Weighted by phase duration: longer phases contribute more to the total.
/// Also auto-updates the stored progress on the active ProjectEntry.
final computedProgressProvider = Provider<double>((ref) {
  final phases = ref.watch(scheduleProvider);
  if (phases.isEmpty) return 0.0;

  double totalWeight = 0;
  double weightedProgress = 0;
  for (final p in phases) {
    final days = p.durationDays.clamp(1, 9999).toDouble();
    totalWeight += days;
    weightedProgress += days * p.progress;
  }
  final progress = totalWeight > 0 ? (weightedProgress / totalWeight).clamp(0.0, 1.0) : 0.0;

  // Side-effect: persist progress on active project so pinned bar shows it even when not active
  final activeId = ref.read(activeProjectIdProvider);
  if (activeId != null) {
    final projects = ref.read(projectsProvider);
    final active = projects.where((p) => p.id == activeId).firstOrNull;
    if (active != null && (active.progress - progress).abs() > 0.01) {
      // Use Future.microtask to avoid modifying providers during build
      Future.microtask(() {
        ref.read(projectsProvider.notifier).update(
          active.copyWith(progress: progress),
        );
      });
    }
  }

  return progress;
});

class BudgetNotifier extends StateNotifier<List<BudgetLine>> {
  final StorageService _storage;

  BudgetNotifier(this._storage) : super([]) {
    final saved = _storage.loadBudget();
    state = saved.isNotEmpty ? saved : DefaultData.budget;
    if (saved.isEmpty) _storage.saveBudget(state);
  }

  void add(BudgetLine item) {
    state = [...state, item];
    _storage.saveBudget(state);
  }

  void remove(String id) {
    state = state.where((b) => b.id != id).toList();
    _storage.saveBudget(state);
  }

  void update(BudgetLine item) {
    state = [
      for (final b in state)
        if (b.id == item.id) item else b,
    ];
    _storage.saveBudget(state);
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<BudgetLine>>((ref) {
  ref.watch(activeProjectIdProvider);
  return BudgetNotifier(ref.watch(storageServiceProvider));
});

final deadlinesProvider = Provider<List<Deadline>>((ref) {
  ref.watch(activeProjectIdProvider);
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadDeadlines();
  if (saved.isNotEmpty) return saved;
  storage.saveDeadlines(DefaultData.deadlines);
  return DefaultData.deadlines;
});

class DrawingSheetNotifier extends StateNotifier<List<DrawingSheet>> {
  final StorageService _storage;

  DrawingSheetNotifier(this._storage) : super([]) {
    final saved = _storage.loadDrawingSheets();
    state = saved.isNotEmpty ? saved : DefaultData.drawingSheets;
    if (saved.isEmpty) _storage.saveDrawingSheets(state);
  }

  void add(DrawingSheet item) {
    state = [...state, item];
    _storage.saveDrawingSheets(state);
  }

  void remove(String id) {
    state = state.where((d) => d.id != id).toList();
    _storage.saveDrawingSheets(state);
  }

  void update(DrawingSheet item) {
    state = [
      for (final d in state)
        if (d.id == item.id) item else d,
    ];
    _storage.saveDrawingSheets(state);
  }
}

final drawingSheetsProvider = StateNotifierProvider<DrawingSheetNotifier, List<DrawingSheet>>((ref) {
  ref.watch(activeProjectIdProvider);
  return DrawingSheetNotifier(ref.watch(storageServiceProvider));
});

final printSetsProvider = Provider<List<PrintSet>>((ref) {
  ref.watch(activeProjectIdProvider);
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadPrintSets();
  if (saved.isNotEmpty) return saved;
  storage.savePrintSets(DefaultData.printSets);
  return DefaultData.printSets;
});

final renderingsProvider = Provider<List<RenderingItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadRenderings();
  if (saved.isNotEmpty) return saved;
  storage.saveRenderings(DefaultData.renderings);
  return DefaultData.renderings;
});

class AsiNotifier extends StateNotifier<List<AsiItem>> {
  final StorageService _storage;

  AsiNotifier(this._storage) : super([]) {
    final saved = _storage.loadAsis();
    state = saved.isNotEmpty ? saved : DefaultData.asis;
    if (saved.isEmpty) _storage.saveAsis(state);
  }

  void add(AsiItem item) {
    state = [...state, item];
    _storage.saveAsis(state);
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
    _storage.saveAsis(state);
  }

  void update(AsiItem item) {
    state = [
      for (final a in state)
        if (a.id == item.id) item else a,
    ];
    _storage.saveAsis(state);
  }

  String nextNumber() {
    final nums = state.map((a) {
      final match = RegExp(r'ASI-(\d+)').firstMatch(a.number);
      return match != null ? int.parse(match.group(1)!) : 0;
    });
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'ASI-${(max + 1).toString().padLeft(3, '0')}';
  }
}

final asisProvider = StateNotifierProvider<AsiNotifier, List<AsiItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return AsiNotifier(ref.watch(storageServiceProvider));
});

final spaceRequirementsProvider = Provider<List<SpaceRequirement>>((ref) {
  ref.watch(activeProjectIdProvider);
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadSpaceReqs();
  if (saved.isNotEmpty) return saved;
  storage.saveSpaceReqs(DefaultData.spaceRequirements);
  return DefaultData.spaceRequirements;
});

class ProjectInfoNotifier extends StateNotifier<List<ProjectInfoEntry>> {
  final StorageService _storage;

  ProjectInfoNotifier(this._storage) : super([]) {
    final saved = _storage.loadProjectInfo();
    state = saved.isNotEmpty ? saved : DefaultData.projectInfo;
    if (saved.isEmpty) _storage.saveProjectInfo(state);
  }

  void add(ProjectInfoEntry entry) {
    state = [...state, entry];
    _storage.saveProjectInfo(state);
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _storage.saveProjectInfo(state);
  }

  void update(ProjectInfoEntry entry) {
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ];
    _storage.saveProjectInfo(state);
  }

  static const _sourcePriority = {
    'manual': 100,
    'sheet': 80,
    'city': 60,
    'contract': 40,
    'inferred': 20,
  };

  /// Clear all automated (non-manual) field values so stale cached data
  /// doesn't persist when the extraction pipeline is re-run.
  /// Keeps the entries but resets their values to empty.
  void clearAutomatedFields() {
    bool changed = false;
    state = [
      for (final e in state)
        if (e.source != 'manual' && e.value.isNotEmpty)
          (() { changed = true; return ProjectInfoEntry(
            id: e.id, category: e.category, label: e.label, value: '',
            source: e.source, confidence: 0, lastUpdated: e.lastUpdated,
          ); })()
        else e,
    ];
    if (changed) _storage.saveProjectInfo(state);
  }

  /// Update a single field by label; creates the entry if it doesn't exist.
  /// Respects source priority: manual > sheet > city > contract > inferred.
  void upsertByLabel(String category, String label, String value, {
    String source = 'manual',
    double confidence = 1.0,
  }) {
    if (value.isEmpty) return;
    final idx = state.indexWhere((e) => e.label == label);
    if (idx >= 0) {
      final existing = state[idx];
      final existingPri = _sourcePriority[existing.source] ?? 0;
      final newPri = _sourcePriority[source] ?? 0;
      // Never overwrite manual entries with automated sources
      if (existing.source == 'manual' && source != 'manual' && existing.value.isNotEmpty) return;
      // Only overwrite if equal/higher priority or existing is empty
      if (newPri < existingPri && existing.value.isNotEmpty) return;
      // Skip if value unchanged from same source
      if (existing.value == value && existing.source == source) return;
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) ProjectInfoEntry(
            id: existing.id, category: category, label: label, value: value,
            source: source, confidence: confidence, lastUpdated: DateTime.now(),
          )
          else state[i],
      ];
    } else {
      state = [...state, ProjectInfoEntry(
        id: 'pi_${DateTime.now().millisecondsSinceEpoch}',
        category: category, label: label, value: value,
        source: source, confidence: confidence, lastUpdated: DateTime.now(),
      )];
    }
    _storage.saveProjectInfo(state);
  }
}

final projectInfoProvider = StateNotifierProvider<ProjectInfoNotifier, List<ProjectInfoEntry>>((ref) {
  ref.watch(activeProjectIdProvider);
  return ProjectInfoNotifier(ref.watch(storageServiceProvider));
});

// ═══════════════════════════════════════════════════════════
// CHANGE ORDERS (Mutable)
// ═══════════════════════════════════════════════════════════

class ChangeOrderNotifier extends StateNotifier<List<ChangeOrder>> {
  final StorageService _storage;

  ChangeOrderNotifier(this._storage) : super([]) {
    final saved = _storage.loadChangeOrders();
    state = saved.isNotEmpty ? saved : DefaultData.changeOrders;
    if (saved.isEmpty) _storage.saveChangeOrders(state);
  }

  void add(ChangeOrder item) {
    state = [...state, item];
    _storage.saveChangeOrders(state);
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    _storage.saveChangeOrders(state);
  }

  void update(ChangeOrder item) {
    state = [
      for (final c in state)
        if (c.id == item.id) item else c,
    ];
    _storage.saveChangeOrders(state);
  }

  String nextNumber() {
    final nums = state.map((c) {
      final match = RegExp(r'CO-(\d+)').firstMatch(c.number);
      return match != null ? int.parse(match.group(1)!) : 0;
    });
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'CO-${(max + 1).toString().padLeft(3, '0')}';
  }
}

final changeOrdersProvider = StateNotifierProvider<ChangeOrderNotifier, List<ChangeOrder>>((ref) {
  ref.watch(activeProjectIdProvider);
  return ChangeOrderNotifier(ref.watch(storageServiceProvider));
});

// ═══════════════════════════════════════════════════════════
// SUBMITTALS (Mutable)
// ═══════════════════════════════════════════════════════════

class SubmittalNotifier extends StateNotifier<List<SubmittalItem>> {
  final StorageService _storage;

  SubmittalNotifier(this._storage) : super([]) {
    final saved = _storage.loadSubmittals();
    state = saved.isNotEmpty ? saved : DefaultData.submittals;
    if (saved.isEmpty) _storage.saveSubmittals(state);
  }

  void add(SubmittalItem item) {
    state = [...state, item];
    _storage.saveSubmittals(state);
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
    _storage.saveSubmittals(state);
  }

  void update(SubmittalItem item) {
    state = [
      for (final s in state)
        if (s.id == item.id) item else s,
    ];
    _storage.saveSubmittals(state);
  }

  String nextNumber() {
    final nums = state.map((s) {
      final match = RegExp(r'SUB-(\d+)').firstMatch(s.number);
      return match != null ? int.parse(match.group(1)!) : 0;
    });
    final max = nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
    return 'SUB-${(max + 1).toString().padLeft(3, '0')}';
  }
}

final submittalsProvider = StateNotifierProvider<SubmittalNotifier, List<SubmittalItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return SubmittalNotifier(ref.watch(storageServiceProvider));
});

// ═══════════════════════════════════════════════════════════
// ACTIVITY / NOTIFICATIONS
// ═══════════════════════════════════════════════════════════

class ActivityNotifier extends StateNotifier<List<ActivityItem>> {
  final StorageService _storage;

  ActivityNotifier(this._storage) : super([]) {
    final saved = _storage.loadActivities();
    state = saved.isNotEmpty ? saved : _defaultActivities;
    if (saved.isEmpty) _storage.saveActivities(state);
  }

  void markRead(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(isRead: true) else a,
    ];
    _storage.saveActivities(state);
  }

  void markAllRead() {
    state = [for (final a in state) a.copyWith(isRead: true)];
    _storage.saveActivities(state);
  }

  void addActivity(ActivityItem item) {
    state = [item, ...state];
    _storage.saveActivities(state);
  }

  static final _defaultActivities = [
    ActivityItem(id: 'act1', title: 'RFI-004 Response Received', description: 'Structural engineer responded to foundation query', timestamp: DateTime.now().subtract(const Duration(minutes: 12)), category: 'rfi'),
    ActivityItem(id: 'act2', title: 'Drawing A-201 Rev 3 Uploaded', description: 'Floor plan updated with client revisions', timestamp: DateTime.now().subtract(const Duration(hours: 1)), category: 'document'),
    ActivityItem(id: 'act3', title: 'Budget Alert: MEP Over 90%', description: 'Mechanical/Electrical/Plumbing budget utilization at 93%', timestamp: DateTime.now().subtract(const Duration(hours: 3)), category: 'budget'),
    ActivityItem(id: 'act4', title: 'Schedule Milestone Approaching', description: 'CD Phase submission due in 5 days', timestamp: DateTime.now().subtract(const Duration(hours: 6)), category: 'schedule'),
    ActivityItem(id: 'act5', title: 'ASI-003 Issued', description: 'Window specification change issued to contractor', timestamp: DateTime.now().subtract(const Duration(hours: 8)), category: 'asi'),
    ActivityItem(id: 'act6', title: 'New Team Member Added', description: 'Lisa Park (Interior Designer) joined the project', timestamp: DateTime.now().subtract(const Duration(days: 1)), category: 'team'),
    ActivityItem(id: 'act7', title: 'Todo Completed: Site Survey', description: 'Site survey review marked as complete', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)), category: 'todo'),
    ActivityItem(id: 'act8', title: 'Contract Amendment #2 Executed', description: 'Additional services scope approved', timestamp: DateTime.now().subtract(const Duration(days: 2)), category: 'budget'),
  ];
}

final activityProvider = StateNotifierProvider<ActivityNotifier, List<ActivityItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return ActivityNotifier(ref.watch(storageServiceProvider));
});

final unreadCountProvider = Provider<int>((ref) {
  final activities = ref.watch(activityProvider);
  return activities.where((a) => !a.isRead).length;
});

// ═══════════════════════════════════════════════════════════
// OTHER MUTABLE PROVIDERS
// ═══════════════════════════════════════════════════════════

class TodoNotifier extends StateNotifier<List<TodoItem>> {
  final StorageService _storage;

  TodoNotifier(this._storage) : super([]) {
    final saved = _storage.loadTodos();
    state = saved.isNotEmpty ? saved : DefaultData.todos;
    if (saved.isEmpty) _storage.saveTodos(state);
  }

  void toggle(String id) {
    state = [
      for (final t in state)
        if (t.id == id) (t..done = !t.done) else t,
    ];
    _storage.saveTodos(state);
  }

  void add(String text, {String? assignee, DateTime? dueDate}) {
    state = [...state, TodoItem(
      id: 'tn${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      assignee: assignee,
      dueDate: dueDate,
    )];
    _storage.saveTodos(state);
  }

  void edit(String id, {required String text, String? assignee, DateTime? dueDate}) {
    state = [
      for (final t in state)
        if (t.id == id)
          TodoItem(id: t.id, text: text, done: t.done, assignee: assignee, dueDate: dueDate)
        else t,
    ];
    _storage.saveTodos(state);
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _storage.saveTodos(state);
  }
}

final todosProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) {
  ref.watch(activeProjectIdProvider);
  return TodoNotifier(ref.watch(storageServiceProvider));
});

class FilesNotifier extends StateNotifier<List<ProjectFile>> {
  final StorageService _storage;

  FilesNotifier(this._storage) : super([]) {
    final saved = _storage.loadFiles();
    state = saved.isNotEmpty ? saved : DefaultData.files;
    if (saved.isEmpty) _storage.saveFiles(state);
  }

  void addFile(ProjectFile file) {
    state = [file, ...state];
    _storage.saveFiles(state);
  }

  void removeFile(String id) {
    state = state.where((f) => f.id != id).toList();
    _storage.saveFiles(state);
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, List<ProjectFile>>((ref) {
  ref.watch(activeProjectIdProvider);
  return FilesNotifier(ref.watch(storageServiceProvider));
});

class PhaseDocumentsNotifier extends StateNotifier<List<PhaseDocument>> {
  final StorageService _storage;

  PhaseDocumentsNotifier(this._storage) : super([]) {
    final saved = _storage.loadPhaseDocuments();
    state = saved.isNotEmpty ? saved : DefaultData.phaseDocuments;
    if (saved.isEmpty) _storage.savePhaseDocuments(state);
  }

  void addDocument(PhaseDocument doc) {
    state = [doc, ...state];
    _storage.savePhaseDocuments(state);
  }
}

final phaseDocumentsProvider = StateNotifierProvider<PhaseDocumentsNotifier, List<PhaseDocument>>((ref) {
  ref.watch(activeProjectIdProvider);
  return PhaseDocumentsNotifier(ref.watch(storageServiceProvider));
});
