import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_models.dart';

/// Handles local persistence of all project data via SharedPreferences.
/// Data is stored as JSON strings keyed by collection name.
class StorageService {
  static const _keyTeam = 'pcc_team';
  static const _keyContracts = 'pcc_contracts';
  static const _keySchedule = 'pcc_schedule';
  static const _keyBudget = 'pcc_budget';
  static const _keyTodos = 'pcc_todos';
  static const _keyFiles = 'pcc_files';
  static const _keyDeadlines = 'pcc_deadlines';
  static const _keyRfis = 'pcc_rfis';
  static const _keyDrawingSheets = 'pcc_drawing_sheets';
  static const _keyPhaseDocuments = 'pcc_phase_documents';
  static const _keyPrintSets = 'pcc_print_sets';
  static const _keyRenderings = 'pcc_renderings';
  static const _keyAsis = 'pcc_asis';
  static const _keySpaceReqs = 'pcc_space_reqs';
  static const _keyProjectInfo = 'pcc_project_info';
  static const _keyChangeOrders = 'pcc_change_orders';
  static const _keySubmittals = 'pcc_submittals';
  static const _keyActivities = 'pcc_activities';
  static const _keyProjectPath = 'pcc_project_path';
  static const _keyProjects = 'pcc_projects';
  static const _keyActiveProjectId = 'pcc_active_project_id';

  late final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;
  String _projectId = '';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Set the active project ID for per-project key namespacing.
  void setProjectId(String id) => _projectId = id;

  /// Returns the namespaced key for per-project data.
  String _pkey(String baseKey) =>
      _projectId.isEmpty ? baseKey : '${baseKey}_$_projectId';

  // ── Generic helpers ─────────────────────────────────────────
  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson, {bool global = false}) {
    final raw = _prefs.getString(global ? key : _pkey(key));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson, {bool global = false}) async {
    await _prefs.setString(global ? key : _pkey(key), jsonEncode(items.map(toJson).toList()));
  }

  bool hasData(String key) => _prefs.containsKey(_pkey(key));
  bool get hasAnyData => _prefs.getKeys().any((k) => k.startsWith('pcc_'));

  // ── Team ────────────────────────────────────────────────────
  List<TeamMember> loadTeam() => _loadList(_keyTeam, _teamFromJson);
  Future<void> saveTeam(List<TeamMember> items) => _saveList(_keyTeam, items, _teamToJson);

  // ── Contracts ───────────────────────────────────────────────
  List<ContractItem> loadContracts() => _loadList(_keyContracts, _contractFromJson);
  Future<void> saveContracts(List<ContractItem> items) => _saveList(_keyContracts, items, _contractToJson);

  // ── Schedule ────────────────────────────────────────────────
  List<SchedulePhase> loadSchedule() => _loadList(_keySchedule, _scheduleFromJson);
  Future<void> saveSchedule(List<SchedulePhase> items) => _saveList(_keySchedule, items, _scheduleToJson);

  // ── Budget ──────────────────────────────────────────────────
  List<BudgetLine> loadBudget() => _loadList(_keyBudget, _budgetFromJson);
  Future<void> saveBudget(List<BudgetLine> items) => _saveList(_keyBudget, items, _budgetToJson);

  // ── Todos ───────────────────────────────────────────────────
  List<TodoItem> loadTodos() => _loadList(_keyTodos, _todoFromJson);
  Future<void> saveTodos(List<TodoItem> items) => _saveList(_keyTodos, items, _todoToJson);

  // ── Files ───────────────────────────────────────────────────
  List<ProjectFile> loadFiles() => _loadList(_keyFiles, _fileFromJson);
  Future<void> saveFiles(List<ProjectFile> items) => _saveList(_keyFiles, items, _fileToJson);

  // ── Deadlines ───────────────────────────────────────────────
  List<Deadline> loadDeadlines() => _loadList(_keyDeadlines, _deadlineFromJson);
  Future<void> saveDeadlines(List<Deadline> items) => _saveList(_keyDeadlines, items, _deadlineToJson);

  // ── RFIs ────────────────────────────────────────────────────
  List<RfiItem> loadRfis() => _loadList(_keyRfis, _rfiFromJson);
  Future<void> saveRfis(List<RfiItem> items) => _saveList(_keyRfis, items, _rfiToJson);

  // ── Drawing Sheets ──────────────────────────────────────────
  List<DrawingSheet> loadDrawingSheets() => _loadList(_keyDrawingSheets, _drawingFromJson);
  Future<void> saveDrawingSheets(List<DrawingSheet> items) => _saveList(_keyDrawingSheets, items, _drawingToJson);

  // ── Phase Documents ─────────────────────────────────────────
  List<PhaseDocument> loadPhaseDocuments() => _loadList(_keyPhaseDocuments, _phaseDocFromJson);
  Future<void> savePhaseDocuments(List<PhaseDocument> items) => _saveList(_keyPhaseDocuments, items, _phaseDocToJson);

  // ── Print Sets ──────────────────────────────────────────────
  List<PrintSet> loadPrintSets() => _loadList(_keyPrintSets, _printSetFromJson);
  Future<void> savePrintSets(List<PrintSet> items) => _saveList(_keyPrintSets, items, _printSetToJson);

  // ── Renderings ──────────────────────────────────────────────
  List<RenderingItem> loadRenderings() => _loadList(_keyRenderings, _renderingFromJson);
  Future<void> saveRenderings(List<RenderingItem> items) => _saveList(_keyRenderings, items, _renderingToJson);

  // ── ASIs ────────────────────────────────────────────────────
  List<AsiItem> loadAsis() => _loadList(_keyAsis, _asiFromJson);
  Future<void> saveAsis(List<AsiItem> items) => _saveList(_keyAsis, items, _asiToJson);

  // ── Space Requirements ──────────────────────────────────────
  List<SpaceRequirement> loadSpaceReqs() => _loadList(_keySpaceReqs, _spaceReqFromJson);
  Future<void> saveSpaceReqs(List<SpaceRequirement> items) => _saveList(_keySpaceReqs, items, _spaceReqToJson);

  // ── Project Info ────────────────────────────────────────────
  List<ProjectInfoEntry> loadProjectInfo() => _loadList(_keyProjectInfo, _projInfoFromJson);
  Future<void> saveProjectInfo(List<ProjectInfoEntry> items) => _saveList(_keyProjectInfo, items, _projInfoToJson);

  // ── Change Orders ─────────────────────────────────────────
  List<ChangeOrder> loadChangeOrders() => _loadList(_keyChangeOrders, _changeOrderFromJson);
  Future<void> saveChangeOrders(List<ChangeOrder> items) => _saveList(_keyChangeOrders, items, _changeOrderToJson);

  // ── Submittals ────────────────────────────────────────────
  List<SubmittalItem> loadSubmittals() => _loadList(_keySubmittals, _submittalFromJson);
  Future<void> saveSubmittals(List<SubmittalItem> items) => _saveList(_keySubmittals, items, _submittalToJson);

  // ── Activities ──────────────────────────────────────────────
  List<ActivityItem> loadActivities() => _loadList(_keyActivities, _activityFromJson);
  Future<void> saveActivities(List<ActivityItem> items) => _saveList(_keyActivities, items, _activityToJson);

  // ── Project Path ──────────────────────────────────────────────
  String loadProjectPath() => _prefs.getString(_keyProjectPath) ?? r'I:\2024\24402';
  Future<void> saveProjectPath(String path) => _prefs.setString(_keyProjectPath, path);

  // ── Projects (multi-project support) ────────────────────────────
  List<ProjectEntry> loadProjects() => _loadList(_keyProjects, _projectFromJson, global: true);
  Future<void> saveProjects(List<ProjectEntry> items) => _saveList(_keyProjects, items, _projectToJson, global: true);
  String? loadActiveProjectId() => _prefs.getString(_keyActiveProjectId);
  Future<void> saveActiveProjectId(String id) => _prefs.setString(_keyActiveProjectId, id);

  // ── Generic string storage ────────────────────────────────────
  String? loadString(String key) => _prefs.getString('pcc_$key');
  Future<void> saveString(String key, String value) => _prefs.setString('pcc_$key', value);

  // ── Import all data from JSON string ────────────────────────────
  Future<String?> importAll(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      for (final entry in data.entries) {
        if (entry.key.startsWith('pcc_') && entry.value is List) {
          await _prefs.setString(entry.key, jsonEncode(entry.value));
        }
      }
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Clear all data ──────────────────────────────────────────
  Future<void> clearAll() async {
    // Only clear per-project data, not global keys (projects list, active ID)
    final globalKeys = {_keyProjects, _keyActiveProjectId, _keyProjectPath};
    final keys = _prefs.getKeys().where((k) =>
      k.startsWith('pcc_') && !globalKeys.contains(k)
    ).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  // ── Export all data as JSON string ──────────────────────────
  String exportAll() {
    final suffix = _projectId.isEmpty ? '' : '_$_projectId';
    final data = <String, dynamic>{};
    for (final key in _prefs.getKeys().where((k) => k.startsWith('pcc_'))) {
      // Export per-project keys (with current suffix) + global keys
      if (suffix.isNotEmpty && !key.endsWith(suffix) &&
          key != _keyProjects && key != _keyActiveProjectId && key != _keyProjectPath) {
        continue;
      }
      data[key] = jsonDecode(_prefs.getString(key) ?? '[]');
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ══════════════════════════════════════════════════════════════
  // JSON CONVERTERS
  // ══════════════════════════════════════════════════════════════

  // ── Team ────────────────────────────────────────────────────
  static Map<String, dynamic> _teamToJson(TeamMember m) => {
    'id': m.id, 'name': m.name, 'role': m.role, 'company': m.company,
    'email': m.email, 'phone': m.phone, 'avatarColor': m.avatarColor.toARGB32(),
  };
  static TeamMember _teamFromJson(Map<String, dynamic> j) => TeamMember(
    id: j['id'], name: j['name'], role: j['role'], company: j['company'],
    email: j['email'] ?? '', phone: j['phone'] ?? '',
    avatarColor: Color(j['avatarColor'] ?? 0xFF607D8B),
  );

  // ── Contract ────────────────────────────────────────────────
  static Map<String, dynamic> _contractToJson(ContractItem c) => {
    'id': c.id, 'title': c.title, 'type': c.type,
    'amount': c.amount, 'status': c.status, 'date': c.date.toIso8601String(),
  };
  static ContractItem _contractFromJson(Map<String, dynamic> j) => ContractItem(
    id: j['id'], title: j['title'], type: j['type'],
    amount: (j['amount'] as num).toDouble(), status: j['status'],
    date: DateTime.parse(j['date']),
  );

  // ── Schedule ────────────────────────────────────────────────
  static Map<String, dynamic> _scheduleToJson(SchedulePhase s) => {
    'id': s.id, 'name': s.name, 'start': s.start.toIso8601String(),
    'end': s.end.toIso8601String(), 'progress': s.progress, 'status': s.status,
  };
  static SchedulePhase _scheduleFromJson(Map<String, dynamic> j) => SchedulePhase(
    id: j['id'], name: j['name'], start: DateTime.parse(j['start']),
    end: DateTime.parse(j['end']), progress: (j['progress'] as num).toDouble(),
    status: j['status'],
  );

  // ── Budget ──────────────────────────────────────────────────
  static Map<String, dynamic> _budgetToJson(BudgetLine b) => {
    'id': b.id, 'category': b.category, 'budgeted': b.budgeted,
    'spent': b.spent, 'committed': b.committed,
  };
  static BudgetLine _budgetFromJson(Map<String, dynamic> j) => BudgetLine(
    id: j['id'], category: j['category'],
    budgeted: (j['budgeted'] as num).toDouble(),
    spent: (j['spent'] as num).toDouble(),
    committed: (j['committed'] as num).toDouble(),
  );

  // ── Todos ───────────────────────────────────────────────────
  static Map<String, dynamic> _todoToJson(TodoItem t) => {
    'id': t.id, 'text': t.text, 'done': t.done,
    'assignee': t.assignee, 'dueDate': t.dueDate?.toIso8601String(),
  };
  static TodoItem _todoFromJson(Map<String, dynamic> j) => TodoItem(
    id: j['id'], text: j['text'], done: j['done'] ?? false,
    assignee: j['assignee'], dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
  );

  // ── Files ───────────────────────────────────────────────────
  static Map<String, dynamic> _fileToJson(ProjectFile f) => {
    'id': f.id, 'name': f.name, 'category': f.category,
    'sizeBytes': f.sizeBytes, 'modified': f.modified.toIso8601String(),
  };
  static ProjectFile _fileFromJson(Map<String, dynamic> j) => ProjectFile(
    id: j['id'], name: j['name'], category: j['category'],
    sizeBytes: j['sizeBytes'], modified: DateTime.parse(j['modified']),
  );

  // ── Deadlines ───────────────────────────────────────────────
  static Map<String, dynamic> _deadlineToJson(Deadline d) => {
    'id': d.id, 'label': d.label, 'date': d.date.toIso8601String(), 'severity': d.severity,
  };
  static Deadline _deadlineFromJson(Map<String, dynamic> j) => Deadline(
    id: j['id'], label: j['label'], date: DateTime.parse(j['date']), severity: j['severity'],
  );

  // ── RFIs ────────────────────────────────────────────────────
  static Map<String, dynamic> _rfiToJson(RfiItem r) => {
    'id': r.id, 'number': r.number, 'subject': r.subject, 'status': r.status,
    'dateOpened': r.dateOpened.toIso8601String(),
    'dateClosed': r.dateClosed?.toIso8601String(), 'assignee': r.assignee,
  };
  static RfiItem _rfiFromJson(Map<String, dynamic> j) => RfiItem(
    id: j['id'], number: j['number'], subject: j['subject'], status: j['status'],
    dateOpened: DateTime.parse(j['dateOpened']),
    dateClosed: j['dateClosed'] != null ? DateTime.parse(j['dateClosed']) : null,
    assignee: j['assignee'],
  );

  // ── Drawing Sheets ──────────────────────────────────────────
  static Map<String, dynamic> _drawingToJson(DrawingSheet d) => {
    'id': d.id, 'sheetNumber': d.sheetNumber, 'title': d.title,
    'discipline': d.discipline, 'phase': d.phase, 'revision': d.revision,
    'lastRevised': d.lastRevised.toIso8601String(), 'status': d.status,
  };
  static DrawingSheet _drawingFromJson(Map<String, dynamic> j) => DrawingSheet(
    id: j['id'], sheetNumber: j['sheetNumber'], title: j['title'],
    discipline: j['discipline'], phase: j['phase'], revision: j['revision'],
    lastRevised: DateTime.parse(j['lastRevised']), status: j['status'],
  );

  // ── Phase Documents ─────────────────────────────────────────
  static Map<String, dynamic> _phaseDocToJson(PhaseDocument d) => {
    'id': d.id, 'name': d.name, 'phase': d.phase, 'discipline': d.discipline,
    'docType': d.docType, 'source': d.source, 'sizeBytes': d.sizeBytes,
    'modified': d.modified.toIso8601String(), 'status': d.status, 'revision': d.revision,
  };
  static PhaseDocument _phaseDocFromJson(Map<String, dynamic> j) => PhaseDocument(
    id: j['id'], name: j['name'], phase: j['phase'], discipline: j['discipline'] ?? '',
    docType: j['docType'], source: j['source'], sizeBytes: j['sizeBytes'],
    modified: DateTime.parse(j['modified']), status: j['status'], revision: j['revision'] ?? 0,
  );

  // ── Print Sets ──────────────────────────────────────────────
  static Map<String, dynamic> _printSetToJson(PrintSet p) => {
    'id': p.id, 'title': p.title, 'type': p.type,
    'date': p.date.toIso8601String(), 'sheetCount': p.sheetCount,
    'distributedTo': p.distributedTo, 'status': p.status, 'sealedBy': p.sealedBy,
  };
  static PrintSet _printSetFromJson(Map<String, dynamic> j) => PrintSet(
    id: j['id'], title: j['title'], type: j['type'],
    date: DateTime.parse(j['date']), sheetCount: j['sheetCount'],
    distributedTo: j['distributedTo'], status: j['status'], sealedBy: j['sealedBy'],
  );

  // ── Renderings ──────────────────────────────────────────────
  static Map<String, dynamic> _renderingToJson(RenderingItem r) => {
    'id': r.id, 'title': r.title, 'viewType': r.viewType,
    'created': r.created.toIso8601String(), 'status': r.status,
    'sizeBytes': r.sizeBytes, 'placeholderColor': r.placeholderColor.toARGB32(),
  };
  static RenderingItem _renderingFromJson(Map<String, dynamic> j) => RenderingItem(
    id: j['id'], title: j['title'], viewType: j['viewType'],
    created: DateTime.parse(j['created']), status: j['status'],
    sizeBytes: j['sizeBytes'],
    placeholderColor: Color(j['placeholderColor'] ?? 0xFF2A3A5C),
  );

  // ── ASIs ────────────────────────────────────────────────────
  static Map<String, dynamic> _asiToJson(AsiItem a) => {
    'id': a.id, 'number': a.number, 'subject': a.subject, 'status': a.status,
    'dateIssued': a.dateIssued.toIso8601String(),
    'affectedSheets': a.affectedSheets, 'issuedBy': a.issuedBy,
  };
  static AsiItem _asiFromJson(Map<String, dynamic> j) => AsiItem(
    id: j['id'], number: j['number'], subject: j['subject'], status: j['status'],
    dateIssued: DateTime.parse(j['dateIssued']),
    affectedSheets: j['affectedSheets'], issuedBy: j['issuedBy'],
  );

  // ── Space Requirements ──────────────────────────────────────
  static Map<String, dynamic> _spaceReqToJson(SpaceRequirement s) => {
    'id': s.id, 'roomName': s.roomName, 'department': s.department,
    'programmedSF': s.programmedSF, 'designedSF': s.designedSF,
    'adjacency': s.adjacency, 'notes': s.notes,
  };
  static SpaceRequirement _spaceReqFromJson(Map<String, dynamic> j) => SpaceRequirement(
    id: j['id'], roomName: j['roomName'], department: j['department'],
    programmedSF: j['programmedSF'], designedSF: j['designedSF'],
    adjacency: j['adjacency'] ?? '', notes: j['notes'] ?? '',
  );

  // ── Project Info ────────────────────────────────────────────
  static Map<String, dynamic> _projInfoToJson(ProjectInfoEntry p) => {
    'id': p.id, 'category': p.category, 'label': p.label, 'value': p.value,
    'source': p.source, 'confidence': p.confidence,
    'lastUpdated': p.lastUpdated?.toIso8601String(),
  };
  static ProjectInfoEntry _projInfoFromJson(Map<String, dynamic> j) => ProjectInfoEntry(
    id: j['id'], category: j['category'], label: j['label'], value: j['value'],
    source: j['source'] as String? ?? 'manual',
    confidence: (j['confidence'] as num?)?.toDouble() ?? 1.0,
    lastUpdated: j['lastUpdated'] != null ? DateTime.tryParse(j['lastUpdated']) : null,
  );

  // ── Change Orders ─────────────────────────────────────────
  static Map<String, dynamic> _changeOrderToJson(ChangeOrder c) => {
    'id': c.id, 'number': c.number, 'description': c.description,
    'amount': c.amount, 'status': c.status,
    'dateSubmitted': c.dateSubmitted.toIso8601String(),
    'dateResolved': c.dateResolved?.toIso8601String(),
    'initiatedBy': c.initiatedBy, 'reason': c.reason,
  };
  static ChangeOrder _changeOrderFromJson(Map<String, dynamic> j) => ChangeOrder(
    id: j['id'], number: j['number'], description: j['description'],
    amount: (j['amount'] as num).toDouble(), status: j['status'],
    dateSubmitted: DateTime.parse(j['dateSubmitted']),
    dateResolved: j['dateResolved'] != null ? DateTime.parse(j['dateResolved']) : null,
    initiatedBy: j['initiatedBy'], reason: j['reason'],
  );

  // ── Submittals ────────────────────────────────────────────
  static Map<String, dynamic> _submittalToJson(SubmittalItem s) => {
    'id': s.id, 'number': s.number, 'title': s.title,
    'specSection': s.specSection, 'status': s.status,
    'dateSubmitted': s.dateSubmitted.toIso8601String(),
    'dateReturned': s.dateReturned?.toIso8601String(),
    'submittedBy': s.submittedBy, 'assignedTo': s.assignedTo,
  };
  static SubmittalItem _submittalFromJson(Map<String, dynamic> j) => SubmittalItem(
    id: j['id'], number: j['number'], title: j['title'],
    specSection: j['specSection'], status: j['status'],
    dateSubmitted: DateTime.parse(j['dateSubmitted']),
    dateReturned: j['dateReturned'] != null ? DateTime.parse(j['dateReturned']) : null,
    submittedBy: j['submittedBy'], assignedTo: j['assignedTo'],
  );

  // ── Activities ────────────────────────────────────────────
  static Map<String, dynamic> _activityToJson(ActivityItem a) => {
    'id': a.id, 'title': a.title, 'description': a.description,
    'timestamp': a.timestamp.toIso8601String(), 'category': a.category,
    'isRead': a.isRead,
    if (a.filePath != null) 'filePath': a.filePath,
  };
  static ActivityItem _activityFromJson(Map<String, dynamic> j) => ActivityItem(
    id: j['id'], title: j['title'], description: j['description'],
    timestamp: DateTime.parse(j['timestamp']), category: j['category'],
    isRead: j['isRead'] ?? false,
    filePath: j['filePath'] as String?,
  );

  // ── Projects ──────────────────────────────────────────────
  static Map<String, dynamic> _projectToJson(ProjectEntry p) => {
    'id': p.id, 'name': p.name, 'number': p.number, 'folderPath': p.folderPath,
    'isPinned': p.isPinned, 'client': p.client, 'status': p.status, 'progress': p.progress,
  };
  static ProjectEntry _projectFromJson(Map<String, dynamic> j) => ProjectEntry(
    id: j['id'], name: j['name'], number: j['number'], folderPath: j['folderPath'],
    isPinned: j['isPinned'] ?? false,
    client: j['client'] ?? '',
    status: j['status'] ?? 'Active',
    progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
  );
}
