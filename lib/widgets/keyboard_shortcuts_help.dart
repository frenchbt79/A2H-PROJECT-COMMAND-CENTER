import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

void showKeyboardShortcutsHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _KeyboardShortcutsDialog(),
  );
}

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.keyboard_outlined, color: Tokens.accent, size: 22),
                  const SizedBox(width: 10),
                  Text('KEYBOARD SHORTCUTS', style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Tokens.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'GENERAL'),
                      const _ShortcutRow(keys: 'Ctrl + K', description: 'Focus search bar'),
                      const _ShortcutRow(keys: 'Ctrl + R', description: 'Refresh scanned files'),
                      const _ShortcutRow(keys: 'Ctrl + /', description: 'Show this help'),
                      const _ShortcutRow(keys: 'F1', description: 'Show this help'),
                      const _ShortcutRow(keys: 'Ctrl + Home', description: 'Go to Dashboard'),
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'QUICK NAVIGATION'),
                      const _ShortcutRow(keys: 'Ctrl + 1', description: 'Dashboard'),
                      const _ShortcutRow(keys: 'Ctrl + 2', description: 'Contract'),
                      const _ShortcutRow(keys: 'Ctrl + 3', description: 'Schedule'),
                      const _ShortcutRow(keys: 'Ctrl + 4', description: 'Budget'),
                      const _ShortcutRow(keys: 'Ctrl + 5', description: 'RFIs'),
                      const _ShortcutRow(keys: 'Ctrl + 6', description: 'Architectural'),
                      const _ShortcutRow(keys: 'Ctrl + 7', description: 'Submittals'),
                      const _ShortcutRow(keys: 'Ctrl + 8', description: 'Change Orders'),
                      const _ShortcutRow(keys: 'Ctrl + 9', description: 'Settings'),
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'FILE ROWS'),
                      const _ShortcutRow(keys: 'Click', description: 'Open file'),
                      const _ShortcutRow(keys: 'Double-click', description: 'Open file'),
                      const _ShortcutRow(keys: 'Right-click', description: 'Context menu (Open File / Open in Explorer)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Tokens.glassBorder, height: 1),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Right-click any file row for Open File and Open in Explorer options',
                  style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String description;
  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: keys.split(' + ').map((key) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Tokens.glassFill,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Tokens.glassBorder),
                        ),
                        child: Text(
                          key.trim(),
                          style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: Tokens.textPrimary),
                        ),
                      ),
                      if (key != keys.split(' + ').last)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text('+', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
