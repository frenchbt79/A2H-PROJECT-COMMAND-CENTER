import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/folder_scan_providers.dart';
import 'folder_scan_service.dart';

/// Reusable right-click / long-press context menu for any file row or tile.
/// Provides: Open, Open in Explorer, Copy Path, Copy File, Rename, Duplicate, Delete.
/// On web, file-modification actions are hidden.
Future<void> showFileContextMenu(
  BuildContext context,
  WidgetRef ref,
  Offset position,
  String fullPath, {
  String openLabel = 'Open File',
}) async {
  final fileName = fullPath.split('\\').last;

  final value = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx, position.dy),
    color: const Color(0xFF1E2A3A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: [
      PopupMenuItem(
        value: 'open',
        child: Row(children: [
          const Icon(Icons.open_in_new, size: 16, color: Tokens.textPrimary),
          const SizedBox(width: 8),
          Text(openLabel,
              style: const TextStyle(color: Tokens.textPrimary, fontSize: 13)),
        ]),
      ),
      PopupMenuItem(
        value: 'folder',
        child: Row(children: [
          const Icon(Icons.folder_open, size: 16, color: Tokens.textPrimary),
          const SizedBox(width: 8),
          const Text('Open in Explorer',
              style: TextStyle(color: Tokens.textPrimary, fontSize: 13)),
        ]),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'copyPath',
        child: Row(children: [
          const Icon(Icons.link, size: 16, color: Tokens.textPrimary),
          const SizedBox(width: 8),
          const Text('Copy Path',
              style: TextStyle(color: Tokens.textPrimary, fontSize: 13)),
        ]),
      ),
      if (!kIsWeb) ...[
        PopupMenuItem(
          value: 'copyFile',
          child: Row(children: [
            const Icon(Icons.content_copy, size: 16, color: Tokens.textPrimary),
            const SizedBox(width: 8),
            const Text('Copy File',
                style: TextStyle(color: Tokens.textPrimary, fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            const Icon(Icons.edit_outlined, size: 16, color: Tokens.textPrimary),
            const SizedBox(width: 8),
            const Text('Rename\u2026',
                style: TextStyle(color: Tokens.textPrimary, fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(children: [
            const Icon(Icons.file_copy_outlined, size: 16, color: Tokens.textPrimary),
            const SizedBox(width: 8),
            const Text('Duplicate',
                style: TextStyle(color: Tokens.textPrimary, fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
            const SizedBox(width: 8),
            Text('Delete\u2026',
                style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
          ]),
        ),
      ],
    ],
  );

  if (value == null || !context.mounted) return;

  switch (value) {
    case 'open':
      FolderScanService.openFile(fullPath);
    case 'folder':
      FolderScanService.openContainingFolder(fullPath);
    case 'copyPath':
      await Clipboard.setData(ClipboardData(text: fullPath));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Path copied to clipboard'),
          backgroundColor: Tokens.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    case 'copyFile':
      try {
        await FolderScanService.copyFileToClipboard(fullPath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('File copied \u2014 paste in Explorer'),
            backgroundColor: Tokens.accent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
      } catch (e) {
        if (context.mounted) _showError(context, e.toString());
      }
    case 'rename':
      await _handleRename(context, ref, fullPath, fileName);
    case 'duplicate':
      await _handleDuplicate(context, ref, fullPath);
    case 'delete':
      await _handleDelete(context, ref, fullPath, fileName);
  }
}

Future<void> _handleRename(
    BuildContext context, WidgetRef ref,
    String fullPath, String fileName) async {
  final dotIdx = fileName.lastIndexOf('.');
  final stem = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
  final ext = dotIdx > 0 ? fileName.substring(dotIdx) : '';
  final controller = TextEditingController(text: stem);
  final formKey = GlobalKey<FormState>();

  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Tokens.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.edit_outlined, color: Tokens.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Text('Rename File',
            style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
      ]),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filename',
                  style: AppTheme.caption.copyWith(
                      color: Tokens.textMuted, fontSize: 10)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      autofocus: true,
                      style: AppTheme.body.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter filename',
                        hintStyle: AppTheme.caption.copyWith(
                            color: Tokens.textMuted.withValues(alpha: 0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          borderSide: const BorderSide(color: Tokens.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          borderSide: const BorderSide(color: Tokens.accent),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          borderSide: const BorderSide(color: Tokens.chipRed),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          borderSide: const BorderSide(color: Tokens.chipRed),
                        ),
                        filled: true,
                        fillColor: Tokens.bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Filename cannot be empty';
                        }
                        if (!FolderScanService.isValidFilename(value)) {
                          return 'Invalid characters in filename';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (ext.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(ext,
                          style: AppTheme.body.copyWith(
                              fontSize: 13,
                              color: Tokens.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text('Cancel',
              style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Tokens.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Tokens.radiusSm)),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop('${controller.text.trim()}$ext');
            }
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );

  if (newName == null || newName == fileName || !context.mounted) return;

  try {
    await FolderScanService.renameFileOnDisk(fullPath, newName);
    ref.read(scanRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Renamed to $newName'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  } catch (e) {
    if (context.mounted) _showError(context, e.toString());
  }
}

Future<void> _handleDuplicate(
    BuildContext context, WidgetRef ref, String fullPath) async {
  try {
    final newFile = await FolderScanService.duplicateFile(fullPath);
    ref.read(scanRefreshProvider.notifier).state++;
    if (context.mounted) {
      final newName = newFile.path.split('\\').last;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Created $newName'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  } catch (e) {
    if (context.mounted) _showError(context, e.toString());
  }
}

Future<void> _handleDelete(
    BuildContext context, WidgetRef ref,
    String fullPath, String fileName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Tokens.chipRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(Icons.delete_outline,
              color: Colors.red.shade300, size: 18),
        ),
        const SizedBox(width: 10),
        Text('Delete File',
            style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "$fileName"?',
                style: AppTheme.body.copyWith(color: Tokens.textPrimary)),
            const SizedBox(height: 8),
            Text('This cannot be undone.',
                style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel',
              style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Tokens.chipRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Tokens.radiusSm)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await FolderScanService.deleteFileOnDisk(fullPath);
    ref.read(scanRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Deleted $fileName'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  } catch (e) {
    if (context.mounted) _showError(context, e.toString());
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Tokens.chipRed,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
  ));
}
