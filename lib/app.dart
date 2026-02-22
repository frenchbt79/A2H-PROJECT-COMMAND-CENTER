import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/app_theme.dart';
import 'state/nav_state.dart';
import 'models/project_models.dart';
import 'widgets/sidebar.dart';
import 'widgets/splash_screen.dart';
import 'pages/dashboard_page.dart';
import 'pages/team_page.dart';
import 'pages/contract_page.dart';
import 'pages/schedule_page.dart';
import 'pages/budget_page.dart';
import 'pages/files_page.dart';
import 'pages/discipline_page.dart';
import 'pages/fire_protection_page.dart';
import 'pages/closeout_documents_page.dart';
import 'pages/print_sets_page.dart';
import 'pages/renderings_page.dart';
import 'pages/programming_page.dart';
import 'pages/project_info_page.dart';
import 'widgets/global_search.dart';
import 'widgets/notification_panel.dart';
import 'pages/settings_page.dart';
import 'pages/specs_page.dart';
import 'pages/photos_gallery_page.dart';
import 'pages/ca_list_page.dart';
import 'widgets/scanned_files_view.dart';
import 'widgets/keyboard_shortcuts_help.dart';
import 'widgets/info_bar.dart';
import 'pages/location_map_page.dart';
import 'pages/project_map_page.dart';
import 'state/folder_scan_providers.dart';
import 'state/ca_scan_providers.dart';
import 'state/project_switcher.dart';
import 'state/project_providers.dart' show computedProgressProvider;
import 'constants.dart';
import 'widgets/quick_add_panel.dart';
import 'services/background_sync_service.dart';
import 'widgets/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

/// Shows LoginScreen until authenticated, then SplashWrapper.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  bool _authenticated = false;

  void _onLogin() {
    if (mounted) setState(() => _authenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _authenticated
          ? const KeyedSubtree(key: ValueKey('app'), child: _SplashWrapper())
          : KeyedSubtree(key: const ValueKey('login'), child: LoginScreen(onLogin: _onLogin)),
    );
  }
}

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _showSplash = true;

  void _onSplashReady() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? SplashScreen(key: const ValueKey('splash'), onReady: _onSplashReady)
          : const KeyedSubtree(key: ValueKey('shell'), child: _Shell()),
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navProvider);
    final navNotifier = ref.read(navProvider.notifier);

    // Quick-nav routes for Ctrl+1 through Ctrl+9
    const quickNavRoutes = [
      NavRoute.dashboard,      // Ctrl+1
      NavRoute.contract,       // Ctrl+2
      NavRoute.schedule,       // Ctrl+3
      NavRoute.budget,         // Ctrl+4
      NavRoute.rfis,           // Ctrl+5
      NavRoute.architectural,  // Ctrl+6
      NavRoute.submittals,     // Ctrl+7
      NavRoute.changeOrders,   // Ctrl+8
      NavRoute.settings,       // Ctrl+9
    ];

    return CallbackShortcuts(
      bindings: {
        // Ctrl+K — Focus search bar
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          ref.read(searchFocusRequestProvider.notifier).state++;
        },
        // Ctrl+R — Refresh scanned files
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
          ref.read(scanRefreshProvider.notifier).state++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refreshing scanned files...'),
              backgroundColor: Tokens.accent,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        // Ctrl+/ — Show keyboard shortcuts help
        const SingleActivator(LogicalKeyboardKey.slash, control: true): () {
          showKeyboardShortcutsHelp(context);
        },
        // F1 — Show keyboard shortcuts help
        const SingleActivator(LogicalKeyboardKey.f1): () {
          showKeyboardShortcutsHelp(context);
        },
        // Ctrl+N — Add new project
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          showProjectSelector(context, ref);
        },
        // Ctrl+1 through Ctrl+9 — Quick navigation
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => navNotifier.selectPage(quickNavRoutes[0]),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => navNotifier.selectPage(quickNavRoutes[1]),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => navNotifier.selectPage(quickNavRoutes[2]),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => navNotifier.selectPage(quickNavRoutes[3]),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => navNotifier.selectPage(quickNavRoutes[4]),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => navNotifier.selectPage(quickNavRoutes[5]),
        const SingleActivator(LogicalKeyboardKey.digit7, control: true): () => navNotifier.selectPage(quickNavRoutes[6]),
        const SingleActivator(LogicalKeyboardKey.digit8, control: true): () => navNotifier.selectPage(quickNavRoutes[7]),
        const SingleActivator(LogicalKeyboardKey.digit9, control: true): () => navNotifier.selectPage(quickNavRoutes[8]),
        // Ctrl+Home — Go to Dashboard
        const SingleActivator(LogicalKeyboardKey.home, control: true): () => navNotifier.selectPage(NavRoute.dashboard),
      },
      child: Focus(
        autofocus: true,
        // Use LayoutBuilder for stable constraint-based breakpoint (not MediaQuery
        // which can report stale/transitional sizes during window drag on Win11).
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < Tokens.mobileBreakpoint;
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.5),
                    radius: 1.4,
                    colors: [Tokens.bloomBlue, Tokens.bgDark],
                  ),
                ),
                child: Stack(
                  children: [
                    // Second bloom (decorative, may extend outside bounds)
                    Positioned(
                      right: -100, bottom: -100,
                      child: Container(
                        width: 500, height: 500,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Tokens.bloomPurple.withValues(alpha: 0.4), Colors.transparent]),
                        ),
                      ),
                    ),
                    // Main layout — Positioned.fill guarantees it occupies the
                    // full Stack area even when the decorative bloom has negative offsets.
                    Positioned.fill(
                      child: isMobile
                          ? _MobileLayout(navState: navState)
                          : _DesktopLayout(navState: navState),
                    ),
                  ],
                ),
              ),
              drawer: isMobile
                  ? Drawer(
                      backgroundColor: Tokens.bgDark,
                      child: Sidebar(onItemSelected: () => Navigator.of(context).pop()),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════
class _DesktopLayout extends ConsumerWidget {
  final NavState navState;
  const _DesktopLayout({required this.navState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedProjects = ref.watch(pinnedProjectsProvider);

    return Row(
      children: [
        SizedBox(
          width: Tokens.sidebarWidth,
          child: const Sidebar(),
        ),
        Container(width: 1, color: Tokens.glassBorder),
        Expanded(
          child: ClipRect(
            child: Column(
              children: [
                // Top Bar — actions row + pinned projects data table
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Spacer(),
                      // Sync indicator
                      const _SyncIndicator(),
                      const SizedBox(width: 8),
                      // Right: Quick Add + Search + Notifications + About
                      const QuickAddButton(),
                      const SizedBox(width: 8),
                      const GlobalSearchBar(),
                      const SizedBox(width: 12),
                      const NotificationBell(),
                      const SizedBox(width: 12),
                      const _AboutButton(),
                    ],
                  ),
                ),
                // Pinned Projects — data-table style
                if (pinnedProjects.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: _PinnedProjectsTable(projects: pinnedProjects),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Pin projects for quick access (right-click a project in the selector)',
                      style: AppTheme.caption.copyWith(
                        color: Tokens.textMuted.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Container(height: 1, color: Tokens.glassBorder),
                // Info bar with Scan Now
                const InfoBar(),
                Container(height: 1, color: Tokens.glassBorder.withValues(alpha: 0.3)),
                // Quick Add panel (shown when toggled)
                Consumer(builder: (context, ref, _) {
                  final isVisible = ref.watch(quickAddVisibleProvider);
                  if (!isVisible) return const SizedBox.shrink();
                  return const QuickAddPanel();
                }),
                // Page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 60),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(navState.selectedRoute),
                      child: _buildPage(navState.selectedRoute),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SYNC STATUS INDICATOR — animated icon in the top bar
// ═══════════════════════════════════════════════════════════

class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);

    IconData icon;
    Color color;
    String tooltip;

    switch (sync.state) {
      case SyncState.syncing:
        icon = Icons.sync;
        color = Tokens.accent;
        tooltip = sync.message.isNotEmpty ? sync.message : 'Syncing...';
      case SyncState.done:
        icon = Icons.cloud_done_outlined;
        color = const Color(0xFF4CAF50);
        final ago = sync.lastSync != null
            ? _timeAgo(sync.lastSync!)
            : '';
        tooltip = 'Synced${ago.isNotEmpty ? ' $ago' : ''}';
      case SyncState.error:
        icon = Icons.cloud_off;
        color = const Color(0xFFEF5350);
        tooltip = sync.message.isNotEmpty ? sync.message : 'Sync error';
      case SyncState.idle:
        icon = Icons.cloud_outlined;
        color = Tokens.textMuted;
        tooltip = 'Not synced yet';
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          // Manual refresh — trigger background sync
          final container = ProviderScope.containerOf(context);
          BackgroundSyncService.sync(container);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: sync.state == SyncState.syncing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                    value: sync.progress > 0 ? sync.progress : null,
                  ),
                )
              : Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════
// PINNED PROJECT CARDS — compact 3-row cards in the top bar
// Row 1: Project Number + Status
// Row 2: Project Name
// Row 3: Progress bar (derived from schedule phases)
// ═══════════════════════════════════════════════════════════

class _PinnedProjectsTable extends ConsumerWidget {
  final List<ProjectEntry> projects;
  const _PinnedProjectsTable({required this.projects});

  static Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'active'  => const Color(0xFF4CAF50),
      'review'  => const Color(0xFFFF9800),
      'closed'  => const Color(0xFFBDBDBD),
      'on hold' => const Color(0xFF78909C),
      _         => const Color(0xFF4CAF50),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    // Watch computed progress to keep stored values up-to-date
    ref.watch(computedProgressProvider);

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = projects[i];
          final isActive = activeProject?.id == p.id;
          final statusColor = _statusColor(p.status);
          // For active project use live computed progress, for others use stored
          final progress = isActive
              ? ref.watch(computedProgressProvider)
              : p.progress;
          final pct = (progress * 100).round();

          return GestureDetector(
            onSecondaryTapDown: (details) {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx, details.globalPosition.dy,
                  details.globalPosition.dx, details.globalPosition.dy,
                ),
                color: Tokens.bgMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Tokens.glassBorder),
                ),
                items: [
                  PopupMenuItem(
                    height: 32,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.push_pin_outlined, size: 14, color: Tokens.textMuted),
                      const SizedBox(width: 8),
                      Text('Unpin', style: AppTheme.body.copyWith(fontSize: 11)),
                    ]),
                    onTap: () => ref.read(projectsProvider.notifier).togglePin(p.id),
                  ),
                  PopupMenuItem(
                    height: 32,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.edit_outlined, size: 14, color: Tokens.textMuted),
                      const SizedBox(width: 8),
                      Text('Edit Details', style: AppTheme.body.copyWith(fontSize: 11)),
                    ]),
                    onTap: () => _showEditDialog(context, ref, p),
                  ),
                ],
              );
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive ? null : () => ProjectSwitcher.switchProject(ref, p),
                borderRadius: BorderRadius.circular(8),
                hoverColor: Tokens.accent.withValues(alpha: 0.06),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Tokens.accent.withValues(alpha: 0.08)
                        : Tokens.glassFill.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Tokens.accent.withValues(alpha: 0.4) : Tokens.glassBorder,
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1: Number + Status chip
                      Row(
                        children: [
                          Text(
                            p.number,
                            style: AppTheme.body.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Tokens.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              p.status,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Row 2: Project Name
                      Text(
                        p.name,
                        style: AppTheme.body.copyWith(
                          fontSize: 10,
                          color: isActive ? Tokens.textPrimary : Tokens.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      // Row 3: Progress bar + percentage
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Tokens.glassBorder.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation(
                                  pct >= 100
                                      ? const Color(0xFF4CAF50)
                                      : pct >= 75
                                          ? Tokens.accent
                                          : pct >= 25
                                              ? const Color(0xFFFF9800)
                                              : Tokens.chipRed,
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pct%',
                            style: AppTheme.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: Tokens.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ProjectEntry project) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!context.mounted) return;
      final clientCtrl = TextEditingController(text: project.client);
      String status = project.status;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: Tokens.bgMid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Tokens.glassBorder),
            ),
            title: Row(children: [
              Text(project.number, style: AppTheme.body.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: Tokens.accent)),
              const SizedBox(width: 8),
              Expanded(child: Text(project.name, style: AppTheme.body.copyWith(fontSize: 14, color: Tokens.textPrimary), overflow: TextOverflow.ellipsis)),
            ]),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: clientCtrl,
                    style: AppTheme.body.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Client Name',
                      labelStyle: AppTheme.caption.copyWith(color: Tokens.textMuted),
                      hintText: 'e.g. Baptist Memorial',
                      hintStyle: AppTheme.caption.copyWith(color: Tokens.textMuted.withValues(alpha: 0.4)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Tokens.glassBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Tokens.accent)),
                      filled: true, fillColor: Tokens.bgDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Status', style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 11)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Active', 'Review', 'On Hold', 'Closed'].map((s) {
                      final isSelected = status == s;
                      final color = _statusColor(s);
                      return ChoiceChip(
                        label: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.3),
                        backgroundColor: Tokens.bgDark,
                        side: BorderSide(color: isSelected ? color : Tokens.glassBorder),
                        onSelected: (_) => setState(() => status = s),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Progress is auto-calculated from schedule phases.',
                    style: AppTheme.caption.copyWith(color: Tokens.textMuted.withValues(alpha: 0.6), fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textMuted, fontSize: 12)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Tokens.accent),
                onPressed: () {
                  ref.read(projectsProvider.notifier).update(
                    project.copyWith(
                      client: clientCtrl.text.trim(),
                      status: status,
                    ),
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
// PROFILE BUTTON — A2H circle that opens profile/settings popup
// ═══════════════════════════════════════════════════════════
class _AboutButton extends ConsumerWidget {
  const _AboutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Profile & Settings',
      child: InkWell(
        onTap: () => _showProfileMenu(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Tokens.accent.withValues(alpha: 0.15),
            border: Border.all(color: Tokens.accent.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text('A2H',
                style: AppTheme.caption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Tokens.accent)),
          ),
        ),
      ),
    );
  }

  static void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final navNotifier = ref.read(navProvider.notifier);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 180, offset.dy + button.size.height + 4,
        offset.dx + button.size.width, offset.dy + button.size.height + 4,
      ),
      color: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      items: [
        // Profile header
        PopupMenuItem<String>(
          enabled: false,
          height: 64,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Tokens.accent, Tokens.accent.withValues(alpha: 0.6)],
                  ),
                ),
                child: Center(
                  child: Text('BF',
                      style: AppTheme.caption.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Tokens.bgDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bradley French',
                        style: AppTheme.body.copyWith(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('Architect • A2H',
                        style: AppTheme.caption.copyWith(
                            fontSize: 10, color: Tokens.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Settings
        PopupMenuItem<String>(
          value: 'settings',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 16, color: Tokens.textSecondary),
              const SizedBox(width: 10),
              Text('Settings', style: AppTheme.body.copyWith(fontSize: 12)),
            ],
          ),
        ),
        // Keyboard Shortcuts
        PopupMenuItem<String>(
          value: 'shortcuts',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.keyboard_outlined, size: 16, color: Tokens.textSecondary),
              const SizedBox(width: 10),
              Text('Keyboard Shortcuts', style: AppTheme.body.copyWith(fontSize: 12)),
              const Spacer(),
              Text('F1', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // About
        PopupMenuItem<String>(
          value: 'about',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Tokens.textSecondary),
              const SizedBox(width: 10),
              Text('About Project Dashboard', style: AppTheme.body.copyWith(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Sign Out
        PopupMenuItem<String>(
          value: 'signout',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.logout, size: 16, color: Tokens.chipRed.withValues(alpha: 0.8)),
              const SizedBox(width: 10),
              Text('Sign Out',
                  style: AppTheme.body.copyWith(
                      fontSize: 12, color: Tokens.chipRed.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'settings':
          navNotifier.selectPage(NavRoute.settings);
          break;
        case 'shortcuts':
          showKeyboardShortcutsHelp(context);
          break;
        case 'about':
          _showAboutDialog(context);
          break;
        case 'signout':
          // TODO: Implement actual sign-out when auth is added
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign out — authentication coming soon'),
              backgroundColor: Tokens.accent,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
      }
    });
  }

  static void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Tokens.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Tokens.accent, Tokens.accent.withValues(alpha: 0.6)],
                    ),
                  ),
                  child: Center(
                    child: Text('A2H',
                        style: AppTheme.heading.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Tokens.bgDark)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Project Dashboard',
                    style: AppTheme.heading.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text(AppConstants.versionLabel,
                    style: AppTheme.caption.copyWith(color: Tokens.textMuted)),
                const SizedBox(height: 16),
                Text(
                  'A comprehensive project management dashboard for A2H architecture projects. '
                  'Automatically scans project folders, extracts drawing metadata, '
                  'tracks RFIs, ASIs, change orders, and more.',
                  style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Divider(color: Tokens.glassBorder),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shortcutHint('Ctrl+K', 'Search'),
                    _shortcutHint('Ctrl+R', 'Refresh'),
                    _shortcutHint('F1', 'Help'),
                    _shortcutHint('Ctrl+N', 'New Project'),
                  ],
                ),
                const SizedBox(height: 20),
                Text('© 2026 A2H • Built by Bradley French',
                    style: AppTheme.caption
                        .copyWith(fontSize: 10, color: Tokens.textMuted)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Tokens.accent.withValues(alpha: 0.15),
                      foregroundColor: Tokens.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Tokens.accent.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _shortcutHint(String key, String desc) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Tokens.glassFill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Tokens.glassBorder),
          ),
          child: Text(key,
              style: AppTheme.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Tokens.textPrimary)),
        ),
        const SizedBox(height: 4),
        Text(desc,
            style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════
class _MobileLayout extends ConsumerWidget {
  final NavState navState;
  const _MobileLayout({required this.navState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Tokens.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                if (activeProject != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Tokens.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                    ),
                    child: Text(activeProject.number, style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: Tokens.accent)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeProject.name,
                      style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: Tokens.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Text(
                    'PROJECT DASHBOARD',
                    style: AppTheme.caption.copyWith(fontWeight: FontWeight.w800, color: Tokens.textPrimary, letterSpacing: 1.1),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            child: KeyedSubtree(
              key: ValueKey(navState.selectedRoute),
              child: _buildPage(navState.selectedRoute),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAGE BUILDER — all 24 routes wired to real pages
// ═══════════════════════════════════════════════════════════
Widget _buildPage(NavRoute route) {
  return switch (route) {
    // Dashboard
    NavRoute.dashboard => const DashboardPage(),
    NavRoute.projectMap => const ProjectMapPage(),
    NavRoute.locationMap => const LocationMapPage(),
    // Project Admin
    NavRoute.projectTeam => const TeamPage(),
    NavRoute.contract => const ContractPage(),
    NavRoute.schedule => const SchedulePage(),
    NavRoute.budget => const BudgetPage(),
    // Project Details
    NavRoute.programming => const ProgrammingPage(),
    NavRoute.clientProvided => ScannedFilesView(title: 'Client Provided', icon: Icons.folder_shared_outlined, accentColor: const Color(0xFF4DB6AC), provider: scannedClientProvidedProvider, destinationFolder: r'Common\Client Provided Information'),
    NavRoute.photos => const PhotosGalleryPage(),
    NavRoute.projectInformationList => const ProjectInfoPage(),
    // Disciplines
    NavRoute.general => const DisciplinePage(disciplineName: 'General', icon: Icons.grid_view_outlined, accentColor: Color(0xFFB0BEC5)),
    NavRoute.structural => const DisciplinePage(disciplineName: 'Structural', icon: Icons.foundation_outlined, accentColor: Color(0xFFBCAAA4)),
    NavRoute.architectural => const DisciplinePage(disciplineName: 'Architectural', icon: Icons.architecture, accentColor: Color(0xFF4FC3F7)),
    NavRoute.civil => const DisciplinePage(disciplineName: 'Civil', icon: Icons.terrain_outlined, accentColor: Color(0xFF81C784)),
    NavRoute.landscape => const DisciplinePage(disciplineName: 'Landscape', icon: Icons.park_outlined, accentColor: Color(0xFF4DB6AC)),
    NavRoute.mechanical => const DisciplinePage(disciplineName: 'Mechanical', icon: Icons.settings_outlined, accentColor: Color(0xFFFFB74D)),
    NavRoute.electrical => const DisciplinePage(disciplineName: 'Electrical', icon: Icons.bolt_outlined, accentColor: Color(0xFFF06292)),
    NavRoute.plumbing => const DisciplinePage(disciplineName: 'Plumbing', icon: Icons.water_drop_outlined, accentColor: Color(0xFF7986CB)),
    NavRoute.fireProtection => const FireProtectionPage(),
    NavRoute.closeoutDocuments => const CloseoutDocumentsPage(),
    // Deliverables & Media
    NavRoute.progressPrints => const PrintSetsPage(printType: 'Progress', title: 'Progress Prints'),
    NavRoute.signedPrints => const PrintSetsPage(printType: 'Signed/Sealed', title: 'Signed & Sealed Prints'),
    NavRoute.specs => const SpecsPage(),
    NavRoute.renderings => const RenderingsPage(),
    // Construction Admin — auto-scanned from project folders
    NavRoute.rfis => CaListPage(
      title: 'RFIs',
      icon: Icons.help_outline,
      provider: scannedCaRfisProvider,
      caType: 'RFI',
    ),
    NavRoute.asis => CaListPage(
      title: "ASI's",
      icon: Icons.assignment_outlined,
      provider: scannedCaAsisProvider,
      caType: 'ASI',
    ),
    NavRoute.changeOrders => CaListPage(
      title: 'Change Orders',
      icon: Icons.swap_horiz,
      provider: scannedCaChangeOrdersProvider,
      caType: 'CO',
    ),
    NavRoute.submittals => CaListPage(
      title: 'Submittals',
      icon: Icons.fact_check_outlined,
      provider: scannedCaSubmittalsProvider,
      caType: 'SUB',
    ),
    NavRoute.punchlists => CaListPage(
      title: 'Punchlists',
      icon: Icons.checklist,
      provider: scannedCaPunchlistsProvider,
      caType: 'PL',
    ),
    // Import (not a real page route — handled by dialog)
    NavRoute.importProjectInformation => const FilesPage(),
    NavRoute.settings => const SettingsPage(),
  };
}
