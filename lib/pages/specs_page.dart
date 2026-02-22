import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/scanned_files_view.dart';
import '../state/folder_scan_providers.dart';

/// Specifications page — scans Front End-Specs folder.
class SpecsPage extends ConsumerWidget {
  const SpecsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScannedFilesView(
      title: 'Specifications',
      icon: Icons.description_outlined,
      accentColor: const Color(0xFF7986CB),
      provider: scannedSpecsProvider,
      destinationFolder: r'0 Project Management\Construction Documents\Front End-Specs',
    );
  }
}
