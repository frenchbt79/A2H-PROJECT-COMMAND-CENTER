import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/scanned_files_view.dart';
import '../state/folder_scan_providers.dart';

/// Client Provided page — scans Common\Client Provided Information recursively.
class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScannedFilesView(
      title: 'Client Provided',
      icon: Icons.folder_shared_outlined,
      accentColor: const Color(0xFF4DB6AC),
      provider: scannedClientProvidedProvider,
      destinationFolder: r'Common\Client Provided Information',
    );
  }
}
