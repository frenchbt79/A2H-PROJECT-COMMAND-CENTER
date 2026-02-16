import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

/// Shows a dialog that simulates importing project files.
/// In a future version this will use a real file picker.
Future<void> showImportDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _ImportDialog(),
  );

  if (result == true && context.mounted) {
    // Simulate adding a new imported file
    ref.read(filesProvider.notifier).addFile(
      ProjectFile(
        id: 'imp_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Imported_Document.pdf',
        category: 'Imported',
        sizeBytes: 2350000,
        modified: DateTime.now(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Tokens.chipGreen, size: 18),
            const SizedBox(width: 8),
            const Text('File imported successfully'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusLg),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  Text('Import Project Information', style: AppTheme.subheading),
                ],
              ),
              const SizedBox(height: 20),
              // Drop zone
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  border: Border.all(color: Tokens.glassBorder, width: 1),
                  borderRadius: BorderRadius.circular(Tokens.radiusMd),
                  color: Tokens.glassFill,
                ),
                child: Column(
                  children: [
                    Icon(
                      _importing ? Icons.hourglass_top : Icons.cloud_upload_outlined,
                      size: 36,
                      color: Tokens.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _importing ? 'Importing...' : 'Drag files here or click to browse',
                      style: AppTheme.body.copyWith(color: Tokens.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports PDF, DWG, XLSX, PNG, JPG',
                      style: AppTheme.caption.copyWith(fontSize: 10),
                    ),
                    if (_importing) ...[
                      const SizedBox(height: 16),
                      const SizedBox(width: 120, child: LinearProgressIndicator(color: Tokens.accent, backgroundColor: Tokens.glassFill)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _importing ? null : () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _importing ? null : _doImport,
                    icon: const Icon(Icons.file_upload, size: 16),
                    label: const Text('Import'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Tokens.accent,
                      foregroundColor: Tokens.bgDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm)),
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

  Future<void> _doImport() async {
    setState(() => _importing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop(true);
  }
}
