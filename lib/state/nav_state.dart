import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Route identifiers ──────────────────────────────────────
enum NavRoute {
  dashboard,
  projectMap,
  locationMap,
  // PROJECT ADMIN
  projectTeam,
  contract,
  schedule,
  budget,
  // PROJECT DETAILS
  programming,
  clientProvided,
  photos,
  projectInformationList,
  // DESIGN PHASES
  schematicDesign,
  designDevelopment,
  constructionDocuments,
  // DISCIPLINES
  architectural,
  civil,
  landscape,
  mechanical,
  electrical,
  plumbing,
  fireProtection,
  // DELIVERABLES & MEDIA
  progressPrints,
  signedPrints,
  specs,
  renderings,
  // CONSTRUCTION ADMIN
  rfis,
  asis,
  changeOrders,
  submittals,
  // Standalone action
  importProjectInformation,
  // Settings
  settings,
}

extension NavRouteLabel on NavRoute {
  String get label {
    switch (this) {
      case NavRoute.dashboard:
        return 'Project Dashboard';
      case NavRoute.projectMap:
        return 'Project Map';
      case NavRoute.locationMap:
        return 'Location Map';
      case NavRoute.projectTeam:
        return 'Project Team';
      case NavRoute.contract:
        return 'Contract';
      case NavRoute.schedule:
        return 'Schedule';
      case NavRoute.budget:
        return 'Budget';
      case NavRoute.programming:
        return 'Programming';
      case NavRoute.clientProvided:
        return 'Client Provided';
      case NavRoute.photos:
        return 'Photos';
      case NavRoute.projectInformationList:
        return 'Project Information List';
      case NavRoute.schematicDesign:
        return 'Schematic Design';
      case NavRoute.designDevelopment:
        return 'Design Development';
      case NavRoute.constructionDocuments:
        return 'Construction Documents';
      case NavRoute.architectural:
        return 'Architectural';
      case NavRoute.civil:
        return 'Civil';
      case NavRoute.landscape:
        return 'Landscape';
      case NavRoute.mechanical:
        return 'Mechanical';
      case NavRoute.electrical:
        return 'Electrical';
      case NavRoute.plumbing:
        return 'Plumbing';
      case NavRoute.fireProtection:
        return 'Fire Protection';
      case NavRoute.progressPrints:
        return 'Progress Prints';
      case NavRoute.signedPrints:
        return 'Signed Prints';
      case NavRoute.specs:
        return 'Specifications';
      case NavRoute.renderings:
        return 'Renderings';
      case NavRoute.rfis:
        return 'RFIs';
      case NavRoute.asis:
        return "ASI's";
      case NavRoute.changeOrders:
        return 'Change Orders';
      case NavRoute.submittals:
        return 'Submittals';
      case NavRoute.importProjectInformation:
        return 'Import Project Information';
      case NavRoute.settings:
        return 'Settings';
    }
  }
}

// ── Sidebar group definitions ──────────────────────────────
class SidebarGroup {
  final String id;
  final String label;
  final List<NavRoute> items;
  const SidebarGroup({required this.id, required this.label, required this.items});
}

const List<SidebarGroup> sidebarGroups = [
  SidebarGroup(id: 'admin', label: 'PROJECT ADMIN', items: [
    NavRoute.projectTeam,
    NavRoute.contract,
    NavRoute.schedule,
    NavRoute.budget,
  ]),
  SidebarGroup(id: 'details', label: 'PROJECT DETAILS', items: [
    NavRoute.programming,
    NavRoute.clientProvided,
    NavRoute.photos,
    NavRoute.projectInformationList,
  ]),
  SidebarGroup(id: 'design', label: 'DESIGN PHASES', items: [
    NavRoute.schematicDesign,
    NavRoute.designDevelopment,
    NavRoute.constructionDocuments,
  ]),
  SidebarGroup(id: 'disciplines', label: 'DISCIPLINES', items: [
    NavRoute.architectural,
    NavRoute.civil,
    NavRoute.landscape,
    NavRoute.mechanical,
    NavRoute.electrical,
    NavRoute.plumbing,
    NavRoute.fireProtection,
  ]),
  SidebarGroup(id: 'deliverables', label: 'DELIVERABLES & MEDIA', items: [
    NavRoute.progressPrints,
    NavRoute.signedPrints,
    NavRoute.specs,
    NavRoute.renderings,
  ]),
  SidebarGroup(id: 'construction', label: 'CONSTRUCTION ADMIN', items: [
    NavRoute.rfis,
    NavRoute.asis,
    NavRoute.changeOrders,
    NavRoute.submittals,
  ]),
];

// ── State class ────────────────────────────────────────────
class NavState {
  final NavRoute selectedRoute;
  final Map<String, bool> expandedGroups;

  const NavState({
    this.selectedRoute = NavRoute.dashboard,
    this.expandedGroups = const {},
  });

  bool isGroupExpanded(String groupId) => expandedGroups[groupId] ?? true;

  NavState copyWith({
    NavRoute? selectedRoute,
    Map<String, bool>? expandedGroups,
  }) {
    return NavState(
      selectedRoute: selectedRoute ?? this.selectedRoute,
      expandedGroups: expandedGroups ?? this.expandedGroups,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────
class NavNotifier extends StateNotifier<NavState> {
  NavNotifier() : super(const NavState());

  void selectPage(NavRoute route) {
    state = state.copyWith(selectedRoute: route);
  }

  void toggleGroup(String groupId) {
    final current = state.isGroupExpanded(groupId);
    final updated = Map<String, bool>.from(state.expandedGroups);
    updated[groupId] = !current;
    state = state.copyWith(expandedGroups: updated);
  }
}

// ── Provider ───────────────────────────────────────────────
final navProvider = StateNotifierProvider<NavNotifier, NavState>((ref) {
  return NavNotifier();
});
