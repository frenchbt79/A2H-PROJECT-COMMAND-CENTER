import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/app_theme.dart';
import 'state/nav_state.dart';
import 'widgets/sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/team_page.dart';
import 'pages/contract_page.dart';
import 'pages/schedule_page.dart';
import 'pages/budget_page.dart';
import 'pages/rfi_page.dart';
import 'pages/files_page.dart';
import 'pages/document_registry_page.dart';
import 'pages/discipline_page.dart';
import 'pages/print_sets_page.dart';
import 'pages/asi_page.dart';
import 'pages/renderings_page.dart';
import 'pages/programming_page.dart';
import 'pages/project_info_page.dart';
import 'widgets/global_search.dart';
import 'widgets/notification_panel.dart';
import 'pages/settings_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Command Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Shell(),
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < Tokens.mobileBreakpoint;
    final navState = ref.watch(navProvider);

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
            // Second bloom
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
            // Main layout
            if (isMobile)
              _MobileLayout(navState: navState)
            else
              _DesktopLayout(navState: navState),
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
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final NavState navState;
  const _DesktopLayout({required this.navState});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Sidebar(),
        Container(width: 1, color: Tokens.glassBorder),
        Expanded(
          child: Column(
            children: [
              // Top bar with search + actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      navState.selectedRoute.label.toUpperCase(),
                      style: AppTheme.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Tokens.textMuted),
                    ),
                    const Spacer(),
                    const GlobalSearchBar(),
                    const SizedBox(width: 16),
                    const NotificationBell(),
                  ],
                ),
              ),
              Container(height: 1, color: Tokens.glassBorder),
              // Page content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(navState.selectedRoute),
                    child: _buildPage(navState.selectedRoute),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final NavState navState;
  const _MobileLayout({required this.navState});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'PROJECT COMMAND CENTER',
                  style: AppTheme.caption.copyWith(fontWeight: FontWeight.w800, color: Tokens.textPrimary, letterSpacing: 1.1),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
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
    // Project Admin
    NavRoute.projectTeam => const TeamPage(),
    NavRoute.contract => const ContractPage(),
    NavRoute.schedule => const SchedulePage(),
    NavRoute.budget => const BudgetPage(),
    // Project Details
    NavRoute.programming => const ProgrammingPage(),
    NavRoute.clientProvided => const DocumentRegistryPage(title: 'Client Provided', filterSource: 'Client'),
    NavRoute.photos => const DocumentRegistryPage(title: 'Photos', photosMode: true),
    NavRoute.projectInformationList => const ProjectInfoPage(),
    // Design Phases
    NavRoute.schematicDesign => const DocumentRegistryPage(title: 'Schematic Design', filterPhase: 'SD'),
    NavRoute.designDevelopment => const DocumentRegistryPage(title: 'Design Development', filterPhase: 'DD'),
    NavRoute.constructionDocuments => const DocumentRegistryPage(title: 'Construction Documents', filterPhase: 'CD'),
    // Disciplines
    NavRoute.architectural => const DisciplinePage(disciplineName: 'Architectural', icon: Icons.architecture, accentColor: Color(0xFF4FC3F7)),
    NavRoute.civil => const DisciplinePage(disciplineName: 'Civil', icon: Icons.terrain_outlined, accentColor: Color(0xFF81C784)),
    NavRoute.landscape => const DisciplinePage(disciplineName: 'Landscape', icon: Icons.park_outlined, accentColor: Color(0xFF4DB6AC)),
    NavRoute.mechanical => const DisciplinePage(disciplineName: 'Mechanical', icon: Icons.settings_outlined, accentColor: Color(0xFFFFB74D)),
    NavRoute.electrical => const DisciplinePage(disciplineName: 'Electrical', icon: Icons.bolt_outlined, accentColor: Color(0xFFF06292)),
    NavRoute.plumbing => const DisciplinePage(disciplineName: 'Plumbing', icon: Icons.water_drop_outlined, accentColor: Color(0xFF7986CB)),
    // Deliverables & Media
    NavRoute.progressPrints => const PrintSetsPage(printType: 'Progress', title: 'Progress Prints'),
    NavRoute.signedPrints => const PrintSetsPage(printType: 'Signed/Sealed', title: 'Signed & Sealed Prints'),
    NavRoute.renderings => const RenderingsPage(),
    // Construction Admin
    NavRoute.rfis => const RfiPage(),
    NavRoute.asis => const AsiPage(),
    // Import (not a real page route — handled by dialog)
    NavRoute.importProjectInformation => const FilesPage(),
    NavRoute.settings => const SettingsPage(),
  };
}
