// Quick diagnostic: does the scan logic work on this machine?
// Run: dart run test_scan.dart
import 'dart:io';

void main() async {
  const basePath = r'I:\2024\24402';
  const relPath = r'0 Project Management\Construction Documents\Scanned Drawings';
  final fullPath = '$basePath\\$relPath';
  
  print('=== SCAN DIAGNOSTIC ===');
  print('basePath: $basePath');
  print('fullPath: $fullPath');
  
  // Check root
  final rootDir = Directory(basePath);
  print('Root exists: ${await rootDir.exists()}');
  
  // Check scan dir
  final scanDir = Directory(fullPath);
  print('Scan dir exists: ${await scanDir.exists()}');
  
  if (!await scanDir.exists()) {
    print('ERROR: Scan directory does not exist!');
    return;
  }
  
  // Count all files
  int totalFiles = 0;
  int pdfFiles = 0;
  int aPrefixFiles = 0;
  
  await for (final entity in scanDir.list(recursive: true)) {
    if (entity is! File) continue;
    totalFiles++;
    final name = entity.uri.pathSegments.last;
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      pdfFiles++;
      if (name.toLowerCase().startsWith('a')) {
        aPrefixFiles++;
        if (aPrefixFiles <= 5) {
          print('  Found: $name');
        }
      }
    }
  }
  
  print('\n=== RESULTS ===');
  print('Total files: $totalFiles');
  print('PDF files: $pdfFiles');
  print('A-prefixed PDFs: $aPrefixFiles');
  print('\nIf A-prefixed > 0, the scan logic WORKS and the issue is elsewhere.');
  print('If 0, there is a filesystem access problem.');
}
