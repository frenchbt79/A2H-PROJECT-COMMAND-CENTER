import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/storage_service.dart';
import '../main.dart' show storageServiceProvider;

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('SETTINGS', style: AppTheme.heading),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: ListView(
              children: [
                // App Info
                _SectionHeader(title: 'APP INFORMATION'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'App Name', value: 'Project Command Center'),
                      _InfoRow(label: 'Version', value: '1.0.0'),
                      _InfoRow(label: 'Build', value: '1'),
                      _InfoRow(label: 'Platform', value: Theme.of(context).platform.name.toUpperCase()),
                    ],
                  ),
                ),
                const SizedBox(height: Tokens.spaceLg),

                // Data Management
                _SectionHeader(title: 'DATA MANAGEMENT'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.download_outlined,
                        label: 'Export Project Data',
                        description: 'Copy all project data as JSON to clipboard',
                        onTap: () {
                          final json = storage.exportAll();
                          Clipboard.setData(ClipboardData(text: json));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Project data copied to clipboard (${(json.length / 1024).toStringAsFixed(0)} KB)'),
                              backgroundColor: Tokens.chipGreen,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      _ActionRow(
                        icon: Icons.refresh_outlined,
                        label: 'Reset to Demo Data',
                        description: 'Clear all changes and restore default sample data',
                        isDestructive: true,
                        onTap: () => _confirmReset(context, storage),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Tokens.spaceLg),

                // Storage Info
                _SectionHeader(title: 'STORAGE'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Storage Type', value: 'SharedPreferences (Local)'),
                      _InfoRow(label: 'Data Persisted', value: storage.hasAnyData ? 'Yes' : 'No'),
                    ],
                  ),
                ),
                const SizedBox(height: Tokens.spaceLg),

                // About
                _SectionHeader(title: 'ABOUT'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project Command Center', style: AppTheme.subheading),
                      const SizedBox(height: 4),
                      Text(
                        'A cross-platform project management dashboard built for architecture, '
                        'engineering, and construction professionals. Track drawings, documents, '
                        'RFIs, ASIs, budgets, schedules, and team collaboration in one place.',
                        style: AppTheme.caption.copyWith(fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text('Built with Flutter & Riverpod', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        title: Text('Reset All Data?', style: AppTheme.subheading),
        content: Text(
          'This will clear all your changes and restore the default demo data. This action cannot be undone.',
          style: AppTheme.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await storage.clearAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data reset to defaults. Restart the app to see changes.'),
                    backgroundColor: Tokens.chipYellow,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Reset', style: AppTheme.body.copyWith(color: Tokens.chipRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.5));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: AppTheme.caption.copyWith(fontSize: 12, color: Tokens.textMuted))),
          Expanded(child: Text(value, style: AppTheme.body.copyWith(fontSize: 12))),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionRow({required this.icon, required this.label, required this.description, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Tokens.chipRed : Tokens.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.body.copyWith(fontSize: 13, color: color)),
                  Text(description, style: AppTheme.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Tokens.textMuted),
          ],
        ),
      ),
    );
  }
}
