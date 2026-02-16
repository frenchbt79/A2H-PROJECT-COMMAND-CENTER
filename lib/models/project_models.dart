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

// ── Drawing Sheet ────────────────────────────────────────
class DrawingSheet {
  final String id;
  final String sheetNumber;
  final String title;
  final String discipline;
  final String phase; // 'SD', 'DD', 'CD'
  final int revision;
  final DateTime lastRevised;
  final String status; // 'Current', 'Superseded', 'In Progress', 'Review'

  const DrawingSheet({
    required this.id,
    required this.sheetNumber,
    required this.title,
    required this.discipline,
    required this.phase,
    required this.revision,
    required this.lastRevised,
    required this.status,
  });
}

// ── Phase Document ───────────────────────────────────────
class PhaseDocument {
  final String id;
  final String name;
  final String phase; // 'SD', 'DD', 'CD', ''
  final String discipline;
  final String docType; // 'Drawing', 'Specification', 'Report', 'Submittal', 'Correspondence'
  final String source; // 'Architect', 'Client', 'Consultant', 'Contractor'
  final int sizeBytes;
  final DateTime modified;
  final String status; // 'Current', 'Superseded', 'Draft', 'Under Review'
  final int revision;

  const PhaseDocument({
    required this.id,
    required this.name,
    required this.phase,
    this.discipline = '',
    required this.docType,
    required this.source,
    required this.sizeBytes,
    required this.modified,
    required this.status,
    this.revision = 0,
  });

  String get sizeLabel {
    if (sizeBytes > 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}

// ── Print Set ────────────────────────────────────────────
class PrintSet {
  final String id;
  final String title;
  final String type; // 'Progress', 'Signed/Sealed'
  final DateTime date;
  final int sheetCount;
  final String distributedTo;
  final String status; // 'Distributed', 'Pending', 'Archived'
  final String? sealedBy;

  const PrintSet({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.sheetCount,
    required this.distributedTo,
    required this.status,
    this.sealedBy,
  });
}

// ── Rendering Item ───────────────────────────────────────
class RenderingItem {
  final String id;
  final String title;
  final String viewType; // 'Exterior', 'Interior', 'Aerial', 'Detail'
  final DateTime created;
  final String status; // 'Final', 'Draft', 'In Progress', 'Client Review'
  final int sizeBytes;
  final Color placeholderColor;

  const RenderingItem({
    required this.id,
    required this.title,
    required this.viewType,
    required this.created,
    required this.status,
    required this.sizeBytes,
    this.placeholderColor = const Color(0xFF2A3A5C),
  });
}

// ── ASI Item ─────────────────────────────────────────────
class AsiItem {
  final String id;
  final String number;
  final String subject;
  final String status; // 'Issued', 'Draft', 'Void'
  final DateTime dateIssued;
  final String? affectedSheets;
  final String? issuedBy;

  const AsiItem({
    required this.id,
    required this.number,
    required this.subject,
    required this.status,
    required this.dateIssued,
    this.affectedSheets,
    this.issuedBy,
  });
}

// ── Space Requirement ────────────────────────────────────
class SpaceRequirement {
  final String id;
  final String roomName;
  final String department;
  final int programmedSF;
  final int designedSF;
  final String adjacency;
  final String notes;

  const SpaceRequirement({
    required this.id,
    required this.roomName,
    required this.department,
    required this.programmedSF,
    required this.designedSF,
    this.adjacency = '',
    this.notes = '',
  });

  int get varianceSF => designedSF - programmedSF;
  double get variancePercent => programmedSF > 0 ? varianceSF / programmedSF : 0;
}

// ── Activity / Notification ─────────────────────────────
class ActivityItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String category; // 'rfi', 'asi', 'schedule', 'budget', 'document', 'team', 'todo'
  final bool isRead;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });

  ActivityItem copyWith({bool? isRead}) => ActivityItem(
    id: id,
    title: title,
    description: description,
    timestamp: timestamp,
    category: category,
    isRead: isRead ?? this.isRead,
  );
}

// ── Project Info Entry ───────────────────────────────────
class ProjectInfoEntry {
  final String id;
  final String category; // 'General', 'Codes & Standards', 'Zoning', 'Contacts', 'Site'
  final String label;
  final String value;

  const ProjectInfoEntry({
    required this.id,
    required this.category,
    required this.label,
    required this.value,
  });
}
