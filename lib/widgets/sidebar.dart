import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/nav_state.dart';
import 'sidebar_item.dart';
import 'sidebar_group.dart';
import 'import_dialog.dart';

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
          // ── Header ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Tokens.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dashboard_rounded, size: 18, color: Tokens.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PROJECT\nCOMMAND CENTER',
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Tokens.textPrimary,
                      height: 1.3,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Small project context placeholder
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
            child: Text(
              'Sample Project v1.0',
              style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // ── Dashboard top-level item ─────────────────
          SidebarItem(
            label: NavRoute.dashboard.label,
            icon: Icons.space_dashboard_outlined,
            isActive: navState.selectedRoute == NavRoute.dashboard,
            onTap: () {
              navNotifier.selectPage(NavRoute.dashboard);
              onItemSelected?.call();
            },
          ),
          SidebarItem(
            label: NavRoute.projectMap.label,
            icon: Icons.map_outlined,
            isActive: navState.selectedRoute == NavRoute.projectMap,
            onTap: () {
              navNotifier.selectPage(NavRoute.projectMap);
              onItemSelected?.call();
            },
          ),
          const SizedBox(height: 4),

          // ── Groups ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
              ],
            ),
          ),

          // ── Bottom actions ────────────────────────────
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
    );
  }
}
