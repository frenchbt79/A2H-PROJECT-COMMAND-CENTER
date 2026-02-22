import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/folder_scan_providers.dart';
import 'file_rename_dialog.dart';

/// Destination folders available in the global import dialog.
const _importDestinations = <String, String>{
  'RFIs': r'0 Project Management\Construction Admin\RFIs',
  'ASIs': r'0 Project Management\Construction Admin\ASIs',
  'Change Orders': r'0 Project Management\Construction Admin\Change Orders',
  'Submittals': r'0 Project Management\Construction Admin\Submittals',
  'Punchlist Documents': r'0 Project Management\Construction Admin\Punchlist Documents',
  'Scanned Drawings': r'0 Project Management\Construction Documents\Scanned Drawings',
  'Progress Prints': r'0 Project Management\Construction Documents\Scanned Drawings\Progress',
  'Signed Prints': r'0 Project Management\Construction Documents\Scanned Drawings\Signed',
  'Specifications': r'0 Project Management\Construction Documents\Front End-Specs',
  'Executed Contracts': r'0 Project Management\Contracts\Executed',
  'Client Provided': r'Common\Client Provided Information',
  'Photos': r'0 Project Management\Photos',
};

/// Shows the global import dialog with drag-and-drop + folder picker.
Future<void> showImportDialog(BuildContext context, WidgetRef ref) async {
  await showDialog(
    context: context,
    builder: (ctx) => _ImportDialog(ref: ref),
  );
}

class _ImportDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ImportDialog({required this.ref});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  String? _selectedDest;
  bool _isDragging = false;
  final List<String> _completedFiles = [];

  @override
  Widget build(BuildContext context) {
    final basePath = widget.ref.read(projectPathProvider);

    return Dialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Tokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: Tokens.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Import Project Files', style: AppTheme.subheading),
                ],
              ),
              const SizedBox(height: 20),

              // Destination picker
              Text('Destination Folder', style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 10)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Tokens.bgDark,
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(color: Tokens.glassBorder),
                ),
                child: DropdownButton<String>(
                  value: _selectedDest,
                  hint: Text('Select destination...', style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textMuted)),
                  isExpanded: true,
                  dropdownColor: Tokens.bgMid,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.unfold_more, size: 16, color: Tokens.textMuted),
                  style: AppTheme.body.copyWith(fontSize: 12),
                  items: _importDestinations.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key, style: AppTheme.body.copyWith(fontSize: 12)),
                          Text(e.value, style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDest = val),
                ),
              ),
              const SizedBox(height: 16),

              // Drop zone
              _buildDropZone(basePath),

              // Completed files list
              if (_completedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('COMPLETED', style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.chipGreen)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _completedFiles.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Tokens.chipGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _completedFiles[i],
                              style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      _completedFiles.isEmpty ? 'Cancel' : 'Done',
                      style: AppTheme.body.copyWith(color: Tokens.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone(String basePath) {
    if (kIsWeb) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Tokens.glassBorder),
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          color: Tokens.glassFill,
        ),
        child: Column(
          children: [
            Icon(Icons.desktop_windows_outlined, size: 36, color: Tokens.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('File import available in desktop app', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
          ],
        ),
      );
    }

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDrop(details, basePath);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging ? Tokens.accent : Tokens.glassBorder,
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          color: _isDragging
              ? Tokens.accent.withValues(alpha: 0.08)
              : Tokens.glassFill,
        ),
        child: Column(
          children: [
            Icon(
              _isDragging ? Icons.file_download : Icons.cloud_upload_outlined,
              size: 36,
              color: _isDragging ? Tokens.accent : Tokens.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _isDragging ? 'Drop files to import' : 'Drag files here from Explorer',
              style: AppTheme.body.copyWith(
                color: _isDragging ? Tokens.accent : Tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DWG, XLSX, PNG, JPG and more',
              style: AppTheme.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDrop(DropDoneDetails details, String basePath) async {
    if (_selectedDest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Tokens.chipYellow, size: 18),
              const SizedBox(width: 8),
              const Text('Please select a destination folder first'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final destRelPath = _importDestinations[_selectedDest]!;
    final fullDest = '$basePath\\$destRelPath';
    final svc = widget.ref.read(folderScanServiceProvider);

    for (final xfile in details.files) {
      if (!mounted) return;

      // Get file size
      int? sizeBytes;
      try {
        final stat = await File(xfile.path).stat();
        sizeBytes = stat.size;
      } catch (_) {}

      if (!mounted) return;

      final newName = await showFileRenameDialog(
        context,
        originalName: xfile.name,
        destinationFolder: fullDest,
        sizeBytes: sizeBytes,
      );

      if (newName == null || !mounted) continue;

      try {
        await svc.copyFileToProjectFolder(
          sourcePath: xfile.path,
          relativePath: destRelPath,
          newName: newName,
        );

        if (!mounted) return;
        setState(() => _completedFiles.add(newName));
        widget.ref.read(scanRefreshProvider.notifier).state++;
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
