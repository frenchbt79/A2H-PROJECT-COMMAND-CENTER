import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/scanned_files_view.dart';
import '../state/folder_scan_providers.dart';

/// Serves 2 routes: Progress Prints and Signed Prints.
/// Now scans from project folders instead of hardcoded data.
class PrintSetsPage extends ConsumerWidget {
  final String printType; // 'Progress' or 'Signed/Sealed'
  final String title;

  const PrintSetsPage({
    super.key,
    required this.printType,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = printType == 'Progress'
        ? scannedProgressPrintsProvider
        : scannedSignedPrintsProvider;

    final destFolder = printType == 'Progress'
        ? r'0 Project Management\Construction Documents\Scanned Drawings\Progress'
        : r'0 Project Management\Construction Documents\Scanned Drawings\Signed';

    return ScannedFilesView(
      title: title,
      icon: printType == 'Progress' ? Icons.print_outlined : Icons.verified_outlined,
      accentColor: const Color(0xFF4FC3F7),
      provider: provider,
      destinationFolder: destFolder,
    );
  }
}
