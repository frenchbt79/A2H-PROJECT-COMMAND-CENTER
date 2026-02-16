import 'package:flutter/material.dart';

// ── Team Member ────────────────────────────────────────────
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String company;
  final String email;
  final String phone;
  final Color avatarColor;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    this.email = '',
    this.phone = '',
    this.avatarColor = Colors.blueGrey,
  });
}

// ── Contract ───────────────────────────────────────────────
class ContractItem {
  final String id;
  final String title;
  final String type; // 'Original', 'Amendment', 'Change Order'
  final double amount;
  final String status; // 'Executed', 'Pending', 'Draft'
  final DateTime date;

  const ContractItem({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
  });

  double get displayAmount => amount;
}

// ── Schedule Phase ─────────────────────────────────────────
class SchedulePhase {
  final String id;
  final String name;
  final DateTime start;
  final DateTime end;
  final double progress; // 0.0 – 1.0
  final String status; // 'Complete', 'In Progress', 'Upcoming'

  const SchedulePhase({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.progress,
    required this.status,
  });

  int get durationDays => end.difference(start).inDays;
}

// ── Budget Line ────────────────────────────────────────────
class BudgetLine {
  final String id;
  final String category;
  final double budgeted;
  final double spent;
  final double committed;

  const BudgetLine({
    required this.id,
    required this.category,
    required this.budgeted,
    required this.spent,
    required this.committed,
  });

  double get remaining => budgeted - spent - committed;
  double get percentUsed => budgeted > 0 ? (spent + committed) / budgeted : 0;
}

// ── Todo Item ──────────────────────────────────────────────
class TodoItem {
  final String id;
  final String text;
  bool done;
  final String? assignee;
  final DateTime? dueDate;

  TodoItem({
    required this.id,
    required this.text,
    this.done = false,
    this.assignee,
    this.dueDate,
  });
}

// ── Project File ───────────────────────────────────────────
class ProjectFile {
  final String id;
  final String name;
  final String category; // discipline or phase
  final int sizeBytes;
  final DateTime modified;

  const ProjectFile({
    required this.id,
    required this.name,
    required this.category,
    required this.sizeBytes,
    required this.modified,
  });

  String get sizeLabel {
    if (sizeBytes > 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}

// ── Deadline ───────────────────────────────────────────────
class Deadline {
  final String id;
  final String label;
  final DateTime date;
  final String severity; // 'green', 'yellow', 'red', 'blue'

  const Deadline({
    required this.id,
    required this.label,
    required this.date,
    required this.severity,
  });
}

// ── RFI ────────────────────────────────────────────────────
class RfiItem {
  final String id;
  final String number;
  final String subject;
  final String status; // 'Open', 'Closed', 'Pending'
  final DateTime dateOpened;
  final DateTime? dateClosed;
  final String? assignee;

  const RfiItem({
    required this.id,
    required this.number,
    required this.subject,
    required this.status,
    required this.dateOpened,
    this.dateClosed,
    this.assignee,
  });
}
