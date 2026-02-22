import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// Shows a rename dialog before copying a dropped file.
/// Returns the new filename (with extension) if confirmed, or null if cancelled.
Future<String?> showFileRenameDialog(
  BuildContext context, {
  required String originalName,
  required String destinationFolder,
  int? sizeBytes,
}) async {
  // Split stem and extension
  final dotIdx = originalName.lastIndexOf('.');
  final stem = dotIdx > 0 ? originalName.substring(0, dotIdx) : originalName;
  final ext = dotIdx > 0 ? originalName.substring(dotIdx) : '';

  final controller = TextEditingController(text: stem);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Tokens.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.file_copy_outlined, color: Tokens.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Import File', style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Tokens.glassFill,
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(color: Tokens.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 14, color: Tokens.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        destinationFolder,
                        style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (sizeBytes != null) ...[
                const SizedBox(height: 6),
                Text(
                  FormatUtils.fileSize(sizeBytes),
                  style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                ),
              ],
              const SizedBox(height: 16),
              // Filename field
              Text('Filename', style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 10)),
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
                        hintStyle: AppTheme.caption.copyWith(color: Tokens.textMuted.withValues(alpha: 0.5)),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Filename cannot be empty';
                        final invalid = RegExp(r'[\\/:*?"<>|]');
                        if (invalid.hasMatch(value)) return 'Invalid characters in filename';
                        return null;
                      },
                    ),
                  ),
                  if (ext.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        ext,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          color: Tokens.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.file_download, size: 16),
          label: const Text('Copy File'),
          style: FilledButton.styleFrom(
            backgroundColor: Tokens.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm)),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final newName = '${controller.text.trim()}$ext';
              Navigator.of(ctx).pop(newName);
            }
          },
        ),
      ],
    ),
  );
}

