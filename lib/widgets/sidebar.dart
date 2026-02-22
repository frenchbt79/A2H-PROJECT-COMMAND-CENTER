import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/nav_state.dart';
import '../state/folder_scan_providers.dart';
import '../state/ca_scan_providers.dart';
import '../models/project_models.dart';
import '../services/folder_scan_service.dart' show FolderScanService;
import '../main.dart' show storageServiceProvider, scanCacheServiceProvider;
import '../state/project_switcher.dart';
import 'sidebar_item.dart';
import 'sidebar_group.dart';
import 'import_dialog.dart';

/// Show the project selector dialog — callable from anywhere (top bar, sidebar, etc.)
void showProjectSelector(BuildContext context, WidgetRef ref) {
  final projects = ref.read(projectsProvider);
  final activeProject = ref.read(activeProjectProvider);
  showDialog(
    context: context,
    builder: (ctx) => _ProjectSelectorDialog(
      projects: projects,
      activeProjectId: activeProject?.id,
      onTogglePin: (id) {
        ref.read(projectsProvider.notifier).togglePin(id);
        Navigator.of(ctx).pop();
        // Re-open to refresh the list
        Future.microtask(() => showProjectSelector(context, ref));
      },
      onSelect: (project) {
        ref.read(storageServiceProvider).setProjectId(project.id);
        ref.read(scanCacheServiceProvider).setProjectId(project.id);
        ref.read(offlineModeProvider.notifier).state = false;
        ref.read(activeProjectIdProvider.notifier).state = project.id;
        ref.read(projectPathProvider.notifier).state = project.folderPath;
        ref.read(storageServiceProvider).saveActiveProjectId(project.id);
        ref.read(storageServiceProvider).saveProjectPath(project.folderPath);
        invalidateAllScanProviders(ref);
        invalidateAllCaScanProviders(ref);
        ref.read(scanRefreshProvider.notifier).state++;
        Navigator.of(ctx).pop();
      },
      onAdd: () {
        Navigator.of(ctx).pop();
        _showAddProjectDialog(context, ref);
      },
      onDelete: (id) {
        ref.read(projectsProvider.notifier).remove(id);
        if (activeProject?.id == id) {
          final remaining = ref.read(projectsProvider);
          if (remaining.isNotEmpty) {
            final next = remaining.first;
            ref.read(storageServiceProvider).setProjectId(next.id);
            ref.read(scanCacheServiceProvider).setProjectId(next.id);
            ref.read(offlineModeProvider.notifier).state = false;
            ref.read(activeProjectIdProvider.notifier).state = next.id;
            ref.read(projectPathProvider.notifier).state = next.folderPath;
            ref.read(storageServiceProvider).saveActiveProjectId(next.id);
            ref.read(storageServiceProvider).saveProjectPath(next.folderPath);
            invalidateAllScanProviders(ref);
            invalidateAllCaScanProviders(ref);
          } else {
            ref.read(storageServiceProvider).setProjectId('');
            ref.read(scanCacheServiceProvider).setProjectId('');
            ref.read(activeProjectIdProvider.notifier).state = null;
            ref.read(projectPathProvider.notifier).state = '';
            invalidateAllScanProviders(ref);
            invalidateAllCaScanProviders(ref);
          }
          ref.read(scanRefreshProvider.notifier).state++;
        }
        Navigator.of(ctx).pop();
      },
    ),
  );
}

void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => _AddProjectDialog(
      onAdd: (project) {
        ref.read(projectsProvider.notifier).add(project);
        // Use ProjectSwitcher for staggered invalidation (no UI freeze)
        ProjectSwitcher.switchProject(ref, project);
        Navigator.of(ctx).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${project.number}" added — scanning folder...'),
            backgroundColor: Tokens.chipGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    ),
  );
}

class Sidebar extends ConsumerWidget {
  final VoidCallback? onItemSelected; // called after tap (for closing drawer on mobile)

  const Sidebar({super.key, this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navProvider);
    final navNotifier = ref.read(navProvider.notifier);

    return Container(
      width: Tokens.sidebarWidth,
      color: Tokens.bgDark.withValues(alpha: 0.85),
      child: Column(
        children: [
          // ── Static Header ─────────────────
          const _ProjectHeader(),
          const Divider(color: Tokens.glassBorder, height: 1, indent: 16, endIndent: 16),

          // ── Everything else scrolls ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                // ── Dashboard top-level items ─────────────────
                SidebarItem(
                  label: NavRoute.dashboard.label,
                  icon: Icons.space_dashboard_outlined,
                  isActive: navState.selectedRoute == NavRoute.dashboard,
                  onTap: () {
                    navNotifier.selectPage(NavRoute.dashboard);
                    onItemSelected?.call();
                  },
                ),
                const SizedBox(height: 4),
                for (final group in sidebarGroups)
                  SidebarGroupWidget(
                    group: group,
                    isExpanded: navState.isGroupExpanded(group.id),
                    selectedRoute: navState.selectedRoute,
                    onToggle: () => navNotifier.toggleGroup(group.id),
                    onSelectItem: (route) {
                      navNotifier.selectPage(route);
                      onItemSelected?.call();
                    },
                  ),
                const Divider(color: Tokens.glassBorder, height: 1, indent: 16, endIndent: 16),
                SidebarItem(
                  label: NavRoute.importProjectInformation.label,
                  icon: Icons.file_upload_outlined,
                  isActive: false,
                  onTap: () => showImportDialog(context, ref),
                ),
                SidebarItem(
                  label: NavRoute.settings.label,
                  icon: Icons.settings_outlined,
                  isActive: navState.selectedRoute == NavRoute.settings,
                  onTap: () {
                    navNotifier.selectPage(NavRoute.settings);
                    onItemSelected?.call();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // ── Offline indicator ──
          if (ref.watch(offlineModeProvider))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 14, color: Colors.orange.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Offline — using cached data',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Project Header — shows active project + selector
// ═══════════════════════════════════════════════════════════

class _ProjectHeader extends ConsumerWidget {
  const _ProjectHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: InkWell(
        onTap: () => showProjectSelector(context, ref),
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0x0AFFFFFF),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Tokens.bgMid.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Tokens.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.dashboard_rounded, size: 16, color: Tokens.accent),
              ),
              const SizedBox(width: 8),
              if (activeProject != null) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeProject.number,
                        style: AppTheme.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Tokens.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        activeProject.name,
                        style: AppTheme.caption.copyWith(
                          fontSize: 10,
                          color: Tokens.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    'Select Project',
                    style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textMuted),
                  ),
                ),
              const Icon(Icons.expand_more, size: 14, color: Tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Project Selector Dialog
// ═══════════════════════════════════════════════════════════

class _ProjectSelectorDialog extends StatelessWidget {
  final List<ProjectEntry> projects;
  final String? activeProjectId;
  final void Function(ProjectEntry) onSelect;
  final VoidCallback onAdd;
  final void Function(String) onDelete;
  final void Function(String) onTogglePin;

  const _ProjectSelectorDialog({
    required this.projects,
    required this.activeProjectId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Row(
        children: [
          const Icon(Icons.folder_copy_outlined, color: Tokens.accent, size: 20),
          const SizedBox(width: 8),
          Text('Select Project', style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Tokens.accent, size: 20),
            tooltip: 'Add Project',
            onPressed: onAdd,
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: projects.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 40, color: Tokens.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No projects yet', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
                    const SizedBox(height: 4),
                    Text('Tap + to add your first project', style: AppTheme.caption),
                  ],
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                  itemBuilder: (context, i) {
                    final p = projects[i];
                    final isActive = p.id == activeProjectId;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusSm)),
                      tileColor: isActive ? Tokens.accent.withValues(alpha: 0.08) : null,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Tokens.accent.withValues(alpha: 0.2)
                              : Tokens.glassFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: isActive ? Tokens.accent : Tokens.textMuted,
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? Tokens.textPrimary : Tokens.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${p.number}  •  ${p.folderPath}',
                        style: AppTheme.caption.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Tokens.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('ACTIVE', style: AppTheme.caption.copyWith(fontSize: 8, color: Tokens.accent, fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              p.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 16,
                              color: p.isPinned ? Tokens.chipYellow : Tokens.textMuted,
                            ),
                            tooltip: p.isPinned ? 'Unpin project' : 'Pin to top bar',
                            onPressed: () => onTogglePin(p.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Tokens.chipRed),
                            tooltip: 'Remove project',
                            onPressed: () => onDelete(p.id),
                          ),
                        ],
                      ),
                      onTap: () => onSelect(p),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Add Project Dialog — type project number, auto-derives path
// ═══════════════════════════════════════════════════════════

class _AddProjectDialog extends StatefulWidget {
  final void Function(ProjectEntry) onAdd;
  const _AddProjectDialog({required this.onAdd});

  @override
  State<_AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<_AddProjectDialog> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _resolvedPath = '';
  bool _pathExists = false;
  bool _checking = false;
  bool _scanningName = false;
  String _status = 'Active';
  final double _progress = 0.0;
  bool _scanComplete = false;

  /// Derives folder path from project number.
  /// Pattern: first 2 digits = year suffix → I:\20XX\NUMBER
  static String _derivePath(String number) {
    if (number.length < 4) return '';
    final yearSuffix = number.substring(0, 2);
    return 'I:\\20$yearSuffix\\$number';
  }

  Future<void> _onNumberChanged(String value) async {
    final number = value.trim();
    final path = _derivePath(number);
    if (path.isEmpty) {
      setState(() {
        _resolvedPath = '';
        _pathExists = false;
        _scanComplete = false;
      });
      return;
    }
    setState(() {
      _resolvedPath = path;
      _checking = true;
      _scanComplete = false;
    });
    if (!kIsWeb) {
      // Timeout protects against network drive hangs when I: is offline
      bool exists = false;
      try {
        exists = await Directory(path).exists().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
      } catch (_) {
        exists = false;
      }
      if (mounted && _resolvedPath == path) {
        setState(() {
          _pathExists = exists;
          _checking = false;
        });
        if (exists) {
          _scanForInfo(path);
        } else {
          setState(() => _scanComplete = true);
        }
      }
    } else {
      setState(() => _checking = false);
    }
  }

  Future<void> _scanForInfo(String path) async {
    if (_scanningName) return;
    setState(() => _scanningName = true);

    try {
      // ── Priority 0: Folder name itself (instant, no I/O) ──
      final folderName = path.split(RegExp(r'[/\\]')).last;
      final folderMatch = RegExp(r'^\d{4,6}\s*[-–—]\s*(.+)$').firstMatch(folderName);
      if (folderMatch != null && mounted && _resolvedPath == path) {
        final raw = folderMatch.group(1)!.trim();
        if (raw.length > 2 && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = raw;
          setState(() { _scanningName = false; _scanComplete = true; });
          return;
        }
      }

      // ── Priority 1: Quick scan (folder + contract filenames, no PDF parsing) ──
      final svc = FolderScanService(path);
      final quick = await svc.extractProjectInfoQuick().timeout(
        const Duration(seconds: 5),
        onTimeout: () => (name: null, client: null),
      );
      if (mounted && _resolvedPath == path && quick.name != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = quick.name!;
        setState(() { _scanningName = false; _scanComplete = true; });
        return;
      }

      // ── Priority 2: Deep scan (PDF content extraction) ──
      if (_nameCtrl.text.isEmpty) {
        final name = await svc.extractProjectNameFromContracts().timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
        if (mounted && _resolvedPath == path && name != null && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = name;
        }
      }
    } catch (_) {
      // Network timeout or other error — just stop scanning
    }

    if (mounted) setState(() { _scanningName = false; _scanComplete = true; });
  }

  void _submit() {
    final number = _numberCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (number.isEmpty || _resolvedPath.isEmpty || name.isEmpty) return;
    widget.onAdd(ProjectEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      number: number,
      folderPath: _resolvedPath,
      status: _status,
      progress: _progress,
    ));
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Row(
        children: [
          const Icon(Icons.add_business, color: Tokens.accent, size: 20),
          const SizedBox(width: 8),
          Text('Add Project', style: AppTheme.subheading.copyWith(color: Tokens.textPrimary)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Project Number — primary field
            TextField(
              controller: _numberCtrl,
              autofocus: true,
              style: AppTheme.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
              onChanged: _onNumberChanged,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Project Number',
                labelStyle: AppTheme.caption.copyWith(color: Tokens.textMuted),
                hintText: 'e.g. 24402',
                hintStyle: AppTheme.caption.copyWith(color: Tokens.textMuted.withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  borderSide: const BorderSide(color: Tokens.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  borderSide: const BorderSide(color: Tokens.accent),
                ),
                filled: true,
                fillColor: Tokens.bgDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // Auto-resolved path indicator
            if (_resolvedPath.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _pathExists
                      ? Tokens.chipGreen.withValues(alpha: 0.08)
                      : Tokens.chipRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                  border: Border.all(
                    color: _pathExists
                        ? Tokens.chipGreen.withValues(alpha: 0.3)
                        : Tokens.chipRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_checking)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.accent))
                    else
                      Icon(
                        _pathExists ? Icons.check_circle_outline : Icons.cloud_off,
                        size: 14,
                        color: _pathExists ? Tokens.chipGreen : Tokens.chipRed,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _resolvedPath,
                            style: AppTheme.caption.copyWith(
                              fontSize: 11,
                              color: _pathExists ? Tokens.chipGreen : Tokens.chipRed,
                            ),
                          ),
                          if (!_pathExists && !_checking)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _resolvedPath.startsWith('I:') ? 'Offline — network drive not accessible' : 'Folder not found',
                                style: AppTheme.caption.copyWith(fontSize: 9, color: Colors.orange.shade300),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Project Name — required, auto-scanned from folder name or contracts
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: AppTheme.body.copyWith(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: _scanningName ? 'Scanning project folder...' : 'Project Name',
                      suffixIcon: _scanningName
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.accent)))
                          : null,
                      labelStyle: AppTheme.caption.copyWith(color: Tokens.textMuted),
                      hintText: 'Auto-detected from folder name or contracts',
                      hintStyle: AppTheme.caption.copyWith(color: Tokens.textMuted.withValues(alpha: 0.5), fontSize: 11),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                        borderSide: BorderSide(color: _nameCtrl.text.trim().isEmpty && _scanComplete ? Tokens.chipRed.withValues(alpha: 0.5) : Tokens.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Tokens.radiusSm),
                        borderSide: const BorderSide(color: Tokens.accent),
                      ),
                      filled: true,
                      fillColor: Tokens.bgDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                if (_pathExists && !_scanningName && _scanComplete)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        _nameCtrl.clear();
                        setState(() => _scanComplete = false);
                        _scanForInfo(_resolvedPath);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Tooltip(
                        message: 'Rescan folder',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Tokens.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.refresh, size: 16, color: Tokens.accent),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Status chips
            Row(
              children: [
                Text('Status: ', style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 11)),
                const SizedBox(width: 8),
                for (final s in ['Active', 'Review', 'On Hold', 'Closed']) ...[
                  GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _status == s ? Tokens.accent.withValues(alpha: 0.15) : Tokens.bgDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _status == s ? Tokens.accent : Tokens.glassBorder),
                      ),
                      child: Text(s, style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: _status == s ? Tokens.accent : Tokens.textMuted)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Tokens.accent),
          onPressed: _resolvedPath.isNotEmpty && _nameCtrl.text.trim().isNotEmpty ? _submit : null,
          child: const Text('Add Project', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}