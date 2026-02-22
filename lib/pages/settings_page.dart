import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/storage_service.dart';
import '../state/folder_scan_providers.dart';
import '../main.dart' show storageServiceProvider, scanCacheServiceProvider;
import '../constants.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final scanCache = ref.watch(scanCacheServiceProvider);
    final projectPath = ref.watch(projectPathProvider);
    final isOffline = ref.watch(offlineModeProvider);

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
                // Project Folder
                _SectionHeader(title: 'PROJECT FOLDER'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Project Path', value: projectPath),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      _ActionRow(
                        icon: Icons.folder_outlined,
                        label: 'Change Project Folder',
                        description: 'Relink to a different project folder on your drive',
                        onTap: () => _showChangePathDialog(context, ref, storage, projectPath),
                      ),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      _ActionRow(
                        icon: Icons.refresh_outlined,
                        label: 'Rescan All Folders',
                        description: 'Refresh all file listings from the project folder',
                        onTap: () {
                          ref.read(scanRefreshProvider.notifier).state++;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rescanning project folders...'),
                              backgroundColor: Tokens.accent,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Tokens.spaceLg),

                // App Info
                _SectionHeader(title: 'APP INFORMATION'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    children: [
                      _InfoRow(label: 'App Name', value: 'Project Command Center'),
                      _InfoRow(label: 'Version', value: AppConstants.appVersion),
                      _InfoRow(label: 'Build', value: '${AppConstants.buildNumber}'),
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
                        icon: Icons.upload_outlined,
                        label: 'Import Project Data',
                        description: 'Paste JSON data from clipboard to restore a backup',
                        onTap: () => _confirmImport(context, storage),
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
                      _InfoRow(label: 'Network Status', value: isOffline ? 'Offline (cached)' : 'Online'),
                      const Divider(color: Tokens.glassBorder, height: 1),
                      _ActionRow(
                        icon: Icons.cached_outlined,
                        label: 'Clear Scan Cache',
                        description: 'Remove cached file listings (will re-scan from network on next load)',
                        onTap: () async {
                          await scanCache.clearAll();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Scan cache cleared'),
                                backgroundColor: Tokens.accent,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
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

  void _showChangePathDialog(BuildContext context, WidgetRef ref, StorageService storage, String currentPath) {
    final controller = TextEditingController(text: currentPath);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        title: Text('Change Project Folder', style: AppTheme.subheading),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the full path to your project folder (e.g. I:\\2024\\24402).',
                style: AppTheme.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: AppTheme.body.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: r'I:\2024\24402',
                  hintStyle: AppTheme.caption.copyWith(fontSize: 12, color: Tokens.textMuted),
                  filled: true,
                  fillColor: Tokens.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    borderSide: const BorderSide(color: Tokens.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final newPath = controller.text.trim();
              if (newPath.isEmpty) return;
              await storage.saveProjectPath(newPath);
              ref.read(projectPathProvider.notifier).state = newPath;
              ref.read(scanRefreshProvider.notifier).state++;
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project folder updated to: $newPath'),
                    backgroundColor: Tokens.chipGreen,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text('Save', style: AppTheme.body.copyWith(color: Tokens.accent, fontWeight: FontWeight.w700)),
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
  void _confirmImport(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        title: Text('Import from Clipboard?', style: AppTheme.subheading),
        content: Text(
          'This will read JSON data from your clipboard and overwrite current project data. '
          'Make sure you have valid exported JSON copied. This cannot be undone.',
          style: AppTheme.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text == null || data!.text!.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clipboard is empty. Copy exported JSON first.'),
                      backgroundColor: Tokens.chipRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              final error = await storage.importAll(data.text!);
              if (context.mounted) {
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data imported successfully! Restart the app to see changes.'),
                      backgroundColor: Tokens.chipGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $error'),
                      backgroundColor: Tokens.chipRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Import', style: AppTheme.body.copyWith(color: Tokens.accent, fontWeight: FontWeight.w700)),
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
