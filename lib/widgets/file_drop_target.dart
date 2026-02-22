import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/folder_scan_providers.dart';
import 'file_rename_dialog.dart';

/// Wraps a child widget with a drag-and-drop target that accepts files
/// from Windows Explorer. On drop, shows a rename dialog and copies each
/// file to the specified project subfolder.
class FileDropTarget extends ConsumerStatefulWidget {
  final Widget child;
  final String destinationRelativePath;

  const FileDropTarget({
    super.key,
    required this.child,
    required this.destinationRelativePath,
  });

  @override
  ConsumerState<FileDropTarget> createState() => _FileDropTargetState();
}

class _FileDropTargetState extends ConsumerState<FileDropTarget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // No drop functionality on web
    if (kIsWeb) return widget.child;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDrop(details);
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Tokens.accent.withValues(alpha: 0.08),
                    border: Border.all(color: Tokens.accent, width: 2),
                    borderRadius: BorderRadius.circular(Tokens.radiusLg),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Tokens.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.file_download, size: 40, color: Tokens.accent),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Drop files here',
                          style: AppTheme.subheading.copyWith(color: Tokens.accent),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.destinationRelativePath.split(r'\').last,
                          style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    final svc = ref.read(folderScanServiceProvider);
    final basePath = ref.read(projectPathProvider);
    final fullDest = '$basePath\\${widget.destinationRelativePath}';

    for (final xfile in details.files) {
      if (!mounted) return;

      // Get file size
      int? sizeBytes;
      try {
        final stat = await File(xfile.path).stat();
        sizeBytes = stat.size;
      } catch (_) {}

      if (!mounted) return;

      // Show rename dialog
      final newName = await showFileRenameDialog(
        context,
        originalName: xfile.name,
        destinationFolder: fullDest,
        sizeBytes: sizeBytes,
      );

      if (newName == null || !mounted) continue;

      // Copy the file
      try {
        await svc.copyFileToProjectFolder(
          sourcePath: xfile.path,
          relativePath: widget.destinationRelativePath,
          newName: newName,
        );

        if (!mounted) return;

        // Refresh scan providers
        ref.read(scanRefreshProvider.notifier).state++;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Tokens.chipGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Copied "$newName" to ${widget.destinationRelativePath.split(r'\').last}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Tokens.chipRed, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to copy: $e')),
              ],
            ),
            backgroundColor: Tokens.chipRed.withValues(alpha: 0.2),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
