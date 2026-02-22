import '../utils/format_utils.dart';

/// Represents a file discovered by scanning a project folder on disk.
class ScannedFile {
  final String name;
  final String fullPath;
  final String relativePath;
  final int sizeBytes;
  final DateTime modified;
  final String extension;

  const ScannedFile({
    required this.name,
    required this.fullPath,
    required this.relativePath,
    required this.sizeBytes,
    required this.modified,
    required this.extension,
  });

  Map<String, dynamic> toJson() => {
    'n': name,
    'f': fullPath,
    'r': relativePath,
    's': sizeBytes,
    'm': modified.millisecondsSinceEpoch,
    'e': extension,
  };

  factory ScannedFile.fromJson(Map<String, dynamic> j) => ScannedFile(
    name: j['n'] as String,
    fullPath: j['f'] as String,
    relativePath: j['r'] as String,
    sizeBytes: j['s'] as int,
    modified: DateTime.fromMillisecondsSinceEpoch(j['m'] as int),
    extension: j['e'] as String,
  );

  String get sizeLabel => FormatUtils.fileSize(sizeBytes);

  bool get isPdf => extension.toLowerCase() == '.pdf';
  bool get isImage => const ['.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff'].contains(extension.toLowerCase());
  bool get isDocument => const ['.docx', '.doc', '.xlsx', '.xls', '.pptx', '.ppt'].contains(extension.toLowerCase());
  bool get isVideo => const ['.mp4', '.avi', '.mov', '.wmv'].contains(extension.toLowerCase());
}
