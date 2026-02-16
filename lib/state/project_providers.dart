import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';

// ═══════════════════════════════════════════════════════════
// TEAM
// ═══════════════════════════════════════════════════════════
final teamProvider = Provider<List<TeamMember>>((ref) => [
  TeamMember(id: '1', name: 'Sarah Chen', role: 'Project Manager', company: 'Meridian Architecture', email: 'schen@meridian.com', phone: '(555) 100-2001', avatarColor: const Color(0xFF4FC3F7)),
  TeamMember(id: '2', name: 'James Rivera', role: 'Lead Architect', company: 'Meridian Architecture', email: 'jrivera@meridian.com', phone: '(555) 100-2002', avatarColor: const Color(0xFF81C784)),
  TeamMember(id: '3', name: 'Emily Nguyen', role: 'Structural Engineer', company: 'CoreStruct Engineering', email: 'enguyen@corestruct.com', phone: '(555) 200-3001', avatarColor: const Color(0xFFFFB74D)),
  TeamMember(id: '4', name: 'Michael Torres', role: 'MEP Coordinator', company: 'SystemFlow MEP', email: 'mtorres@systemflow.com', phone: '(555) 300-4001', avatarColor: const Color(0xFFE57373)),
  TeamMember(id: '5', name: 'David Park', role: 'Civil Engineer', company: 'Greystone Civil', email: 'dpark@greystone.com', phone: '(555) 400-5001', avatarColor: const Color(0xFFBA68C8)),
  TeamMember(id: '6', name: 'Lisa Martinez', role: 'Landscape Architect', company: 'GreenEdge Design', email: 'lmartinez@greenedge.com', phone: '(555) 500-6001', avatarColor: const Color(0xFF4DB6AC)),
  TeamMember(id: '7', name: 'Robert Kim', role: 'Owner Representative', company: 'Northstar Development', email: 'rkim@northstar.com', phone: '(555) 600-7001', avatarColor: const Color(0xFF7986CB)),
  TeamMember(id: '8', name: 'Amanda Foster', role: 'Interior Designer', company: 'Meridian Architecture', email: 'afoster@meridian.com', phone: '(555) 100-2003', avatarColor: const Color(0xFFF06292)),
]);

// ═══════════════════════════════════════════════════════════
// CONTRACTS
// ═══════════════════════════════════════════════════════════
final contractsProvider = Provider<List<ContractItem>>((ref) => [
  ContractItem(id: 'c1', title: 'Original A/E Services Agreement', type: 'Original', amount: 2450000, status: 'Executed', date: DateTime(2025, 3, 15)),
  ContractItem(id: 'c2', title: 'Amendment 01 — Expanded Scope', type: 'Amendment', amount: 185000, status: 'Executed', date: DateTime(2025, 6, 10)),
  ContractItem(id: 'c3', title: 'Amendment 02 — Additional Renderings', type: 'Amendment', amount: 45000, status: 'Executed', date: DateTime(2025, 9, 22)),
  ContractItem(id: 'c4', title: 'CO-001 — Foundation Redesign', type: 'Change Order', amount: 72000, status: 'Pending', date: DateTime(2026, 1, 8)),
  ContractItem(id: 'c5', title: 'CO-002 — HVAC Value Engineering', type: 'Change Order', amount: -38000, status: 'Draft', date: DateTime(2026, 2, 3)),
]);

// ═══════════════════════════════════════════════════════════
// SCHEDULE
// ═══════════════════════════════════════════════════════════
final scheduleProvider = Provider<List<SchedulePhase>>((ref) => [
  SchedulePhase(id: 's1', name: 'Schematic Design', start: DateTime(2025, 3, 1), end: DateTime(2025, 7, 15), progress: 1.0, status: 'Complete'),
  SchedulePhase(id: 's2', name: 'Design Development', start: DateTime(2025, 6, 1), end: DateTime(2025, 11, 30), progress: 0.85, status: 'In Progress'),
  SchedulePhase(id: 's3', name: 'Construction Documents', start: DateTime(2025, 10, 1), end: DateTime(2026, 5, 15), progress: 0.30, status: 'In Progress'),
  SchedulePhase(id: 's4', name: 'Permitting', start: DateTime(2026, 3, 1), end: DateTime(2026, 6, 30), progress: 0.0, status: 'Upcoming'),
  SchedulePhase(id: 's5', name: 'Bidding & Negotiation', start: DateTime(2026, 5, 1), end: DateTime(2026, 7, 31), progress: 0.0, status: 'Upcoming'),
  SchedulePhase(id: 's6', name: 'Construction Admin', start: DateTime(2026, 8, 1), end: DateTime(2027, 12, 31), progress: 0.0, status: 'Upcoming'),
]);

// ═══════════════════════════════════════════════════════════
// BUDGET
// ═══════════════════════════════════════════════════════════
final budgetProvider = Provider<List<BudgetLine>>((ref) => [
  BudgetLine(id: 'b1', category: 'Architecture', budgeted: 1200000, spent: 620000, committed: 280000),
  BudgetLine(id: 'b2', category: 'Structural', budgeted: 380000, spent: 195000, committed: 95000),
  BudgetLine(id: 'b3', category: 'MEP Engineering', budgeted: 520000, spent: 210000, committed: 180000),
  BudgetLine(id: 'b4', category: 'Civil / Site', budgeted: 290000, spent: 145000, committed: 85000),
  BudgetLine(id: 'b5', category: 'Landscape', budgeted: 180000, spent: 72000, committed: 54000),
  BudgetLine(id: 'b6', category: 'Interior Design', budgeted: 340000, spent: 102000, committed: 136000),
  BudgetLine(id: 'b7', category: 'Renderings / Media', budgeted: 95000, spent: 45000, committed: 20000),
  BudgetLine(id: 'b8', category: 'Consultants / Other', budgeted: 150000, spent: 38000, committed: 52000),
]);

// ═══════════════════════════════════════════════════════════
// TODOS
// ═══════════════════════════════════════════════════════════
class TodoNotifier extends StateNotifier<List<TodoItem>> {
  TodoNotifier() : super([
    TodoItem(id: 't1', text: 'Review SD package comments', assignee: 'Sarah Chen', dueDate: DateTime(2026, 2, 18)),
    TodoItem(id: 't2', text: 'Update civil grading plan', done: true, assignee: 'David Park', dueDate: DateTime(2026, 2, 14)),
    TodoItem(id: 't3', text: 'Coordinate MEP clash detection', assignee: 'Michael Torres', dueDate: DateTime(2026, 2, 20)),
    TodoItem(id: 't4', text: 'Submit landscape revisions', assignee: 'Lisa Martinez', dueDate: DateTime(2026, 2, 22)),
    TodoItem(id: 't5', text: 'Schedule client DD review', assignee: 'Sarah Chen', dueDate: DateTime(2026, 2, 25)),
    TodoItem(id: 't6', text: 'Finalize permit checklist', done: true, assignee: 'James Rivera', dueDate: DateTime(2026, 2, 10)),
    TodoItem(id: 't7', text: 'Update door schedule', assignee: 'Amanda Foster', dueDate: DateTime(2026, 3, 1)),
    TodoItem(id: 't8', text: 'Review structural calcs rev 2', assignee: 'Emily Nguyen', dueDate: DateTime(2026, 2, 28)),
  ]);

  void toggle(String id) {
    state = [
      for (final t in state)
        if (t.id == id) (t..done = !t.done) else t,
    ];
  }

  void add(String text) {
    state = [...state, TodoItem(id: 'tn${state.length}', text: text)];
  }
}

final todosProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) => TodoNotifier());

// ═══════════════════════════════════════════════════════════
// FILES
// ═══════════════════════════════════════════════════════════
class FilesNotifier extends StateNotifier<List<ProjectFile>> {
  FilesNotifier() : super([
    ProjectFile(id: 'f1', name: 'SD_Floorplan_Rev3.pdf', category: 'Architectural', sizeBytes: 4500000, modified: DateTime(2026, 2, 16, 10, 30)),
    ProjectFile(id: 'f2', name: 'MEP_Coordination.pdf', category: 'MEP', sizeBytes: 3200000, modified: DateTime(2026, 2, 15, 14, 0)),
    ProjectFile(id: 'f3', name: 'Landscape_Plan_v2.pdf', category: 'Landscape', sizeBytes: 2800000, modified: DateTime(2026, 2, 14, 9, 15)),
    ProjectFile(id: 'f4', name: 'Structural_Calcs.pdf', category: 'Structural', sizeBytes: 1500000, modified: DateTime(2026, 2, 12, 16, 45)),
    ProjectFile(id: 'f5', name: 'Site_Survey_Final.pdf', category: 'Civil', sizeBytes: 8900000, modified: DateTime(2026, 2, 10, 11, 0)),
    ProjectFile(id: 'f6', name: 'Contract_Amendment_4.pdf', category: 'Admin', sizeBytes: 420000, modified: DateTime(2026, 2, 8, 13, 30)),
    ProjectFile(id: 'f7', name: 'Interior_Finish_Schedule.xlsx', category: 'Interior', sizeBytes: 980000, modified: DateTime(2026, 2, 7, 10, 0)),
    ProjectFile(id: 'f8', name: 'Rendering_Lobby_Final.png', category: 'Renderings', sizeBytes: 15600000, modified: DateTime(2026, 2, 5, 17, 20)),
  ]);

  void addFile(ProjectFile file) {
    state = [file, ...state];
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, List<ProjectFile>>((ref) => FilesNotifier());

// ═══════════════════════════════════════════════════════════
// DEADLINES
// ═══════════════════════════════════════════════════════════
final deadlinesProvider = Provider<List<Deadline>>((ref) => [
  Deadline(id: 'd1', label: 'SD Submittal', date: DateTime(2026, 3, 15), severity: 'green'),
  Deadline(id: 'd2', label: 'DD Milestone', date: DateTime(2026, 4, 2), severity: 'yellow'),
  Deadline(id: 'd3', label: 'CD Review', date: DateTime(2026, 5, 10), severity: 'red'),
  Deadline(id: 'd4', label: 'Permit Set', date: DateTime(2026, 6, 1), severity: 'blue'),
  Deadline(id: 'd5', label: 'Bid Package', date: DateTime(2026, 7, 15), severity: 'blue'),
]);

// ═══════════════════════════════════════════════════════════
// RFIs
// ═══════════════════════════════════════════════════════════
final rfisProvider = Provider<List<RfiItem>>((ref) => [
  RfiItem(id: 'r1', number: 'RFI-001', subject: 'Foundation footing depth at grid B-4', status: 'Closed', dateOpened: DateTime(2025, 11, 3), dateClosed: DateTime(2025, 11, 18), assignee: 'Emily Nguyen'),
  RfiItem(id: 'r2', number: 'RFI-002', subject: 'Exterior cladding material substitution', status: 'Closed', dateOpened: DateTime(2025, 12, 1), dateClosed: DateTime(2025, 12, 20), assignee: 'James Rivera'),
  RfiItem(id: 'r3', number: 'RFI-003', subject: 'MEP routing conflict at Level 3 corridor', status: 'Open', dateOpened: DateTime(2026, 1, 12), assignee: 'Michael Torres'),
  RfiItem(id: 'r4', number: 'RFI-004', subject: 'ADA compliance — restroom clearances', status: 'Open', dateOpened: DateTime(2026, 1, 28), assignee: 'James Rivera'),
  RfiItem(id: 'r5', number: 'RFI-005', subject: 'Stormwater retention basin sizing', status: 'Pending', dateOpened: DateTime(2026, 2, 5), assignee: 'David Park'),
]);
