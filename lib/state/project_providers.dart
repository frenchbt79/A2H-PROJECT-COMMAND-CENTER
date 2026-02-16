import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../services/storage_service.dart';
import '../main.dart' show storageServiceProvider;
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
  return RfiNotifier(ref.watch(storageServiceProvider));
});

// ═══════════════════════════════════════════════════════════
// READ-ONLY PROVIDERS (load from storage or seed defaults)
// ═══════════════════════════════════════════════════════════

final contractsProvider = Provider<List<ContractItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadContracts();
  if (saved.isNotEmpty) return saved;
  storage.saveContracts(DefaultData.contracts);
  return DefaultData.contracts;
});

final scheduleProvider = Provider<List<SchedulePhase>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadSchedule();
  if (saved.isNotEmpty) return saved;
  storage.saveSchedule(DefaultData.schedule);
  return DefaultData.schedule;
});

final budgetProvider = Provider<List<BudgetLine>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadBudget();
  if (saved.isNotEmpty) return saved;
  storage.saveBudget(DefaultData.budget);
  return DefaultData.budget;
});

final deadlinesProvider = Provider<List<Deadline>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadDeadlines();
  if (saved.isNotEmpty) return saved;
  storage.saveDeadlines(DefaultData.deadlines);
  return DefaultData.deadlines;
});

final drawingSheetsProvider = Provider<List<DrawingSheet>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadDrawingSheets();
  if (saved.isNotEmpty) return saved;
  storage.saveDrawingSheets(DefaultData.drawingSheets);
  return DefaultData.drawingSheets;
});

final printSetsProvider = Provider<List<PrintSet>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadPrintSets();
  if (saved.isNotEmpty) return saved;
  storage.savePrintSets(DefaultData.printSets);
  return DefaultData.printSets;
});

final renderingsProvider = Provider<List<RenderingItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadRenderings();
  if (saved.isNotEmpty) return saved;
  storage.saveRenderings(DefaultData.renderings);
  return DefaultData.renderings;
});

final asisProvider = Provider<List<AsiItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadAsis();
  if (saved.isNotEmpty) return saved;
  storage.saveAsis(DefaultData.asis);
  return DefaultData.asis;
});

final spaceRequirementsProvider = Provider<List<SpaceRequirement>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadSpaceReqs();
  if (saved.isNotEmpty) return saved;
  storage.saveSpaceReqs(DefaultData.spaceRequirements);
  return DefaultData.spaceRequirements;
});

final projectInfoProvider = Provider<List<ProjectInfoEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadProjectInfo();
  if (saved.isNotEmpty) return saved;
  storage.saveProjectInfo(DefaultData.projectInfo);
  return DefaultData.projectInfo;
});

// ═══════════════════════════════════════════════════════════
// ACTIVITY / NOTIFICATIONS
// ═══════════════════════════════════════════════════════════

class ActivityNotifier extends StateNotifier<List<ActivityItem>> {
  ActivityNotifier() : super(_defaultActivities);

  void markRead(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(isRead: true) else a,
    ];
  }

  void markAllRead() {
    state = [for (final a in state) a.copyWith(isRead: true)];
  }

  void addActivity(ActivityItem item) {
    state = [item, ...state];
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
  return ActivityNotifier();
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
  return PhaseDocumentsNotifier(ref.watch(storageServiceProvider));
});
