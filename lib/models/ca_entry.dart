import '../utils/format_utils.dart';

/// Represents a Construction Admin document entry (RFI, ASI, CO, Submittal, Punchlist)
/// parsed from folder structure and PDF filenames.
class CaEntry {
  final String id;
  final String type;           // 'RFI', 'ASI', 'CO', 'SUB', 'PL'
  final String number;         // e.g. 'RFI #3', 'ASI #10', 'CO-001'
  final String description;    // Parsed from folder/file name
  final String? assignedTo;    // Parsed from filename or PDF
  final String? issuedBy;      // Parsed from filename or PDF
  final String? affectedSheets;// Sheet numbers found in folder
  final DateTime? date;        // Parsed from filename or file modified
  final String status;         // 'Open', 'Closed', 'Issued', 'Draft', etc.
  final String folderPath;     // Full path to the folder
  final List<CaFile> files;    // All files in this entry's folder

  const CaEntry({
    required this.id,
    required this.type,
    required this.number,
    required this.description,
    this.assignedTo,
    this.issuedBy,
    this.affectedSheets,
    this.date,
    required this.status,
    required this.folderPath,
    this.files = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'number': number,
    'description': description,
    'assignedTo': assignedTo,
    'issuedBy': issuedBy,
    'affectedSheets': affectedSheets,
    'date': date?.millisecondsSinceEpoch,
    'status': status,
    'folderPath': folderPath,
    'files': files.map((f) => f.toJson()).toList(),
  };

  factory CaEntry.fromJson(Map<String, dynamic> j) => CaEntry(
    id: j['id'] as String,
    type: j['type'] as String,
    number: j['number'] as String,
    description: j['description'] as String,
    assignedTo: j['assignedTo'] as String?,
    issuedBy: j['issuedBy'] as String?,
    affectedSheets: j['affectedSheets'] as String?,
    date: j['date'] != null ? DateTime.fromMillisecondsSinceEpoch(j['date'] as int) : null,
    status: j['status'] as String,
    folderPath: j['folderPath'] as String,
    files: (j['files'] as List?)?.map((f) => CaFile.fromJson(f as Map<String, dynamic>)).toList() ?? const [],
  );

  CaEntry copyWith({
    String? description,
    String? assignedTo,
    String? issuedBy,
    String? affectedSheets,
    DateTime? date,
    String? status,
    List<CaFile>? files,
  }) {
    return CaEntry(
      id: id,
      type: type,
      number: number,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      issuedBy: issuedBy ?? this.issuedBy,
      affectedSheets: affectedSheets ?? this.affectedSheets,
      date: date ?? this.date,
      status: status ?? this.status,
      folderPath: folderPath,
      files: files ?? this.files,
    );
  }
}

/// A single file within a CA entry folder.
class CaFile {
  final String name;
  final String fullPath;
  final int sizeBytes;
  final DateTime modified;
  final String extension;
  final bool isPrimary; // The main PDF for this entry

  const CaFile({
    required this.name,
    required this.fullPath,
    required this.sizeBytes,
    required this.modified,
    required this.extension,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'n': name,
    'f': fullPath,
    's': sizeBytes,
    'm': modified.millisecondsSinceEpoch,
    'e': extension,
    'p': isPrimary,
  };

  factory CaFile.fromJson(Map<String, dynamic> j) => CaFile(
    name: j['n'] as String,
    fullPath: j['f'] as String,
    sizeBytes: j['s'] as int,
    modified: DateTime.fromMillisecondsSinceEpoch(j['m'] as int),
    extension: j['e'] as String,
    isPrimary: j['p'] as bool? ?? false,
  );

  bool get isPdf => extension.toLowerCase() == '.pdf';

  String get sizeLabel => FormatUtils.fileSize(sizeBytes);
}
