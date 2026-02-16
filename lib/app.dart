import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/app_theme.dart';
import 'state/nav_state.dart';
import 'widgets/sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/team_page.dart';
import 'pages/contract_page.dart';
import 'pages/schedule_page.dart';
import 'pages/budget_page.dart';
import 'pages/rfi_page.dart';
import 'pages/files_page.dart';

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
// PAGE BUILDER — routes to real pages
// ═══════════════════════════════════════════════════════════
Widget _buildPage(NavRoute route) {
  return switch (route) {
    NavRoute.dashboard => const DashboardPage(),
    NavRoute.projectTeam => const TeamPage(),
    NavRoute.contract => const ContractPage(),
    NavRoute.schedule => const SchedulePage(),
    NavRoute.budget => const BudgetPage(),
    NavRoute.rfis => const RfiPage(),
    // Files-related routes
    NavRoute.clientProvided || NavRoute.photos => const FilesPage(),
    // Everything else → placeholder
    _ => PlaceholderPage(title: route.label),
  };
}
