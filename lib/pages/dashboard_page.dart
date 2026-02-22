import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../state/nav_state.dart';
import '../state/folder_scan_providers.dart';
import '../services/folder_scan_service.dart' show DiscoveredMilestone;
import '../models/project_models.dart';
import '../widgets/crud_dialogs.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < Tokens.mobileBreakpoint;
    if (isMobile) return _MobileLayout();
    return _DesktopLayout();
  }
}

class _DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const _DashCard({required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.dashCardRadius),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          Tokens.dashGradientTop.withValues(alpha: 0.78),
          Tokens.dashGradientBottom.withValues(alpha: 0.82),
        ]),
        border: Border.all(color: Tokens.dashBorder),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 24, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.dashCardRadius),
        child: Stack(children: [
          Positioned(top: 0, left: 16, right: 16, child: Container(height: 1, color: Tokens.dashHighlight)),
          Padding(padding: padding, child: child),
        ]),
      ),
    );
    if (onTap != null) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: Material(color: Colors.transparent, child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.dashCardRadius),
        hoverColor: const Color(0x0AFFFFFF),
        splashColor: Tokens.accent.withValues(alpha: 0.08),
        highlightColor: const Color(0x08FFFFFF),
        child: card,
      )));
    }
    return card;
  }
}
class _DesktopLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Row 1: Stacked KPIs | Date+Weather | Calendar
        SizedBox(height: 230, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // CO stacked over Submittals
          Expanded(child: Column(children: [
            Expanded(child: _KpiChangeOrdersCard()),
            const SizedBox(height: 8),
            Expanded(child: _KpiSubmittalsCard()),
          ])),
          const SizedBox(width: 16),
          // Budget stacked over RFIs
          Expanded(child: Column(children: [
            Expanded(child: _KpiBudgetCard()),
            const SizedBox(height: 8),
            Expanded(child: _KpiRfisCard()),
          ])),
          const SizedBox(width: 16),
          // Today + Weather combined card
          Expanded(child: _TodayWeatherCard()),
          const SizedBox(width: 16),
          // Calendar
          Expanded(child: _MiniCalendarCard()),
        ])),
        const SizedBox(height: 16),
        // Row 2: Map (50%) | Full Project Info (50%)
        Expanded(flex: 4, child: Row(children: [
          Expanded(child: _MapPanel()),
          const SizedBox(width: 16),
          Expanded(child: _FullProjectInfoPanel()),
        ])),
        const SizedBox(height: 16),
        // Row 3: Project Team | Todos
        Expanded(flex: 3, child: Row(children: [
          Expanded(flex: 7, child: _ProjectTeamCard()),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _TodosCard()),
        ])),
      ]),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(Tokens.spaceMd),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _KpiChangeOrdersCard()), const SizedBox(width: 8), Expanded(child: _KpiBudgetCard())]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _KpiSubmittalsCard()), const SizedBox(width: 8), Expanded(child: _KpiRfisCard())]),
        const SizedBox(height: 8),
        SizedBox(height: 200, child: _TodayWeatherCard()),
        const SizedBox(height: 8),
        _MiniCalendarCard(),
        const SizedBox(height: 12),
        SizedBox(height: 300, child: _MapPanel()),
        const SizedBox(height: 12),
        SizedBox(height: 400, child: _FullProjectInfoPanel()),
        const SizedBox(height: 12),
        SizedBox(height: 300, child: _ProjectTeamCard()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _TodosCard()),
      ],
    );
  }
}
class _KpiBudgetCard extends ConsumerWidget {
  static final _fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final total = budget.fold<double>(0, (s, b) => s + b.budgeted);
    final spent = budget.fold<double>(0, (s, b) => s + b.spent);
    final pct = total > 0 ? spent / total : 0.0;
    final color = pct > 0.9 ? Tokens.accentRed : pct > 0.75 ? Tokens.accentYellow : Tokens.accentGreen;
    return _DashCard(onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.budget), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('BUDGET', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF), fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Text(_fmt.format(total - spent), style: AppTheme.subheading.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      Text('remaining', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct.clamp(0, 1), minHeight: 3, backgroundColor: const Color(0x14FFFFFF), color: color)),
    ]));
  }
}
class _KpiChangeOrdersCard extends ConsumerWidget {
  static final _fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cos = ref.watch(changeOrdersProvider);
    final approved = cos.where((c) => c.status == 'Approved').toList();
    final pending = cos.where((c) => c.status == 'Pending').length;
    final totalAmt = approved.fold<double>(0, (s, c) => s + c.amount);
    final total = cos.length;
    final approvedPct = total > 0 ? approved.length / total : 0.0;
    final color = pending > 3 ? Tokens.accentRed : pending > 0 ? Tokens.accentYellow : Tokens.accentGreen;
    return _DashCard(onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.changeOrders), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('CHANGE ORDERS', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF), fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Text(_fmt.format(totalAmt), style: AppTheme.subheading.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      Text('$pending pending \u2022 ${approved.length} approved', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: approvedPct.clamp(0, 1), minHeight: 3, backgroundColor: const Color(0x14FFFFFF), color: color)),
    ]));
  }
}
class _KpiSubmittalsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(submittalsProvider);
    final approved = subs.where((s) => s.status == 'Approved').length;
    final pending = subs.where((s) => s.status == 'Pending' || s.status == 'Submitted').length;
    final total = subs.length;
    final pct = total > 0 ? approved / total : 0.0;
    return _DashCard(onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.submittals), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('SUBMITTALS', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF), fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(mainAxisSize: MainAxisSize.min, children: [Text('$approved', style: AppTheme.subheading.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Tokens.accentGreen)), Text(' / $total', style: AppTheme.body.copyWith(fontSize: 12, color: const Color(0x9EFFFFFF)))]),
      Text('$pending pending', style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.accentYellow)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct.clamp(0, 1), minHeight: 3, backgroundColor: const Color(0x14FFFFFF), color: Tokens.accentGreen)),
    ]));
  }
}

class _KpiRfisCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rfis = ref.watch(rfisProvider);
    final open = rfis.where((r) => r.status == 'Open').length;
    final pending = rfis.where((r) => r.status == 'Pending').length;
    final total = rfis.length;
    final closedPct = total > 0 ? (total - open - pending) / total : 0.0;
    final color = open > 5 ? Tokens.accentRed : open > 0 ? Tokens.accentYellow : Tokens.accentGreen;
    return _DashCard(onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.rfis), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('RFIs', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF), fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(mainAxisSize: MainAxisSize.min, children: [Text('$open', style: AppTheme.subheading.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: color)), Text(' open', style: AppTheme.body.copyWith(fontSize: 12, color: const Color(0x9EFFFFFF)))]),
      Text('$pending pending', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: closedPct.clamp(0, 1), minHeight: 3, backgroundColor: const Color(0x14FFFFFF), color: Tokens.accentBlue)),
    ]));
  }
}
class _MiniCalendarCard extends ConsumerWidget {
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final cells = List.generate(startWeekday, (_) => 0) + List.generate(daysInMonth, (i) => i + 1);

    // Collect deadline/milestone days in this month
    final deadlines = ref.watch(deadlinesProvider);
    final milestonesAsync = ref.watch(discoveredMilestonesProvider);
    final milestones = milestonesAsync.valueOrNull ?? <DiscoveredMilestone>[];
    final highlightDays = <int, Color>{};
    for (final dl in deadlines) {
      if (dl.date.year == now.year && dl.date.month == now.month) {
        final c = switch (dl.severity) { 'red' => Tokens.accentRed, 'yellow' => Tokens.accentYellow, 'green' => Tokens.accentGreen, _ => Tokens.accentBlue };
        highlightDays[dl.date.day] = c;
      }
    }
    for (final m in milestones) {
      if (m.date.year == now.year && m.date.month == now.month) {
        highlightDays.putIfAbsent(m.date.day, () => Tokens.accentYellow);
      }
    }

    return _DashCard(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('${_months[now.month - 1]} ${now.year}', style: AppTheme.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xEBFFFFFF))),
      const SizedBox(height: 4),
      Row(children: _days.map((d) => Expanded(child: Center(child: Text(d, style: AppTheme.caption.copyWith(fontSize: 7, color: const Color(0x6BFFFFFF)))))).toList()),
      const SizedBox(height: 2),
      GridView.count(crossAxisCount: 7, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.4, shrinkWrap: true,
        children: cells.map((d) {
          if (d == 0) return const SizedBox.shrink();
          final isToday = d == now.day;
          final deadlineColor = highlightDays[d];
          return Center(child: Container(width: 18, height: 18,
            decoration: isToday
                ? BoxDecoration(color: Tokens.accent, borderRadius: BorderRadius.circular(9))
                : deadlineColor != null
                    ? BoxDecoration(border: Border.all(color: deadlineColor, width: 1.5), borderRadius: BorderRadius.circular(9))
                    : null,
            alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$d', style: TextStyle(fontSize: 8, fontWeight: isToday || deadlineColor != null ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? Tokens.bgDark : deadlineColor ?? const Color(0x9EFFFFFF))),
            ]),
          ));
        }).toList()),
    ]));
  }
}
class _MapPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends ConsumerState<_MapPanel> {
  bool _isSatellite = false;

  @override
  Widget build(BuildContext context) {
    final projectInfo = ref.watch(projectInfoProvider);
    double lat = 0, lng = 0;
    String address = '', city = '', zoning = '', lotSize = '';
    for (final e in projectInfo) {
      switch (e.label) {
        case 'Latitude': lat = double.tryParse(e.value) ?? 0;
        case 'Longitude': lng = double.tryParse(e.value) ?? 0;
        case 'Project Address': address = e.value;
        case 'City': city = e.value;
        case 'Zoning Classification': zoning = e.value;
        case 'Lot Size': lotSize = e.value;
      }
    }
    final hasCoords = lat != 0 || lng != 0;
    return _DashCard(padding: EdgeInsets.zero, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
        Text('Project Map & Location', style: AppTheme.subheading.copyWith(fontSize: 14)),
        const Spacer(),
        Container(decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [
          InkWell(onTap: () => setState(() => _isSatellite = false), mouseCursor: SystemMouseCursors.click, borderRadius: BorderRadius.circular(8),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: !_isSatellite ? Tokens.accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text('Project Map', style: AppTheme.caption.copyWith(fontSize: 10, color: !_isSatellite ? Tokens.accent : const Color(0x42FFFFFF), fontWeight: FontWeight.w600)))),
          InkWell(onTap: () => setState(() => _isSatellite = true), mouseCursor: SystemMouseCursors.click, borderRadius: BorderRadius.circular(8), hoverColor: const Color(0x0AFFFFFF),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _isSatellite ? Tokens.accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text('Satellite', style: AppTheme.caption.copyWith(fontSize: 10, color: _isSatellite ? Tokens.accent : const Color(0x42FFFFFF), fontWeight: FontWeight.w600)))),
        ])),
        const SizedBox(width: 8),
        InkWell(onTap: () {}, mouseCursor: SystemMouseCursors.click, borderRadius: BorderRadius.circular(8), hoverColor: const Color(0x0AFFFFFF),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.layers_outlined, size: 12, color: Color(0x9EFFFFFF)), const SizedBox(width: 4), Text('Layers', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x9EFFFFFF)))]))),
      ])),
      Expanded(child: Stack(children: [
        ClipRRect(borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(Tokens.dashCardRadius), bottomRight: Radius.circular(Tokens.dashCardRadius)),
          child: hasCoords ? FlutterMap(key: ValueKey('map_${lat}_${lng}_$_isSatellite'), options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15.0, minZoom: 3.0, maxZoom: 18.0), children: [
            TileLayer(
              urlTemplate: _isSatellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: _isSatellite ? const [] : const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.a2h.project_command_center'),
            MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 48, height: 48, child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Tokens.accent.withValues(alpha: 0.2), border: Border.all(color: Tokens.accent.withValues(alpha: 0.5), width: 2)),
              child: const Icon(Icons.location_on, color: Tokens.accent, size: 24)))]),
          ]) : Container(color: const Color(0xFF0D1B2A), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.map_outlined, size: 48, color: Tokens.textMuted.withValues(alpha: 0.3)), const SizedBox(height: 8),
            Text('No coordinates set', style: AppTheme.caption.copyWith(color: Tokens.textMuted))]))),
        ),
        if (address.isNotEmpty) Positioned(left: 12, bottom: 12, child: Container(width: 320, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Tokens.dashGradientBottom.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(14), border: Border.all(color: Tokens.dashBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Project Site', style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xEBFFFFFF))),
            const SizedBox(height: 6),
            Text(address, style: AppTheme.body.copyWith(fontSize: 11, color: const Color(0xEBFFFFFF))),
            if (city.isNotEmpty) Text(city, style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x9EFFFFFF))),
            if (hasCoords) ...[const SizedBox(height: 4),
              Text('${lat.toStringAsFixed(4)}\u00B0N, ${lng.toStringAsFixed(4)}\u00B0W', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF), fontFamily: 'monospace'))],
            if (lotSize.isNotEmpty || zoning.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [
              if (lotSize.isNotEmpty) Text('Lot: $lotSize', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
              if (lotSize.isNotEmpty && zoning.isNotEmpty) const SizedBox(width: 12),
              if (zoning.isNotEmpty) Text('Zoning: $zoning', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
            ])],
          ]),
        )),
      ])),
    ]));
  }
}
// ── Today + Weather + Deadlines combined card ──────────────
class _TodayWeatherCard extends ConsumerWidget {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static IconData _weatherIcon(int code) => switch (code) {
    0 => Icons.wb_sunny,
    1 || 2 => Icons.cloud_queue,
    3 => Icons.cloud,
    45 || 48 => Icons.foggy,
    51 || 53 || 55 || 61 || 63 || 65 || 80 || 81 || 82 => Icons.water_drop,
    66 || 67 => Icons.ac_unit,
    71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
    95 || 96 || 99 => Icons.thunderstorm,
    _ => Icons.cloud_queue,
  };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final deadlines = ref.watch(deadlinesProvider);
    final milestonesAsync = ref.watch(discoveredMilestonesProvider);
    final milestones = milestonesAsync.valueOrNull ?? <DiscoveredMilestone>[];
    final now = DateTime.now();
    final dayName = _weekdays[now.weekday % 7];
    final monthDay = '${_months[now.month - 1]} ${now.day}, ${now.year}';

    // Build deadline items
    final items = <_DeadlineItem>[];
    for (final dl in deadlines) {
      final color = switch (dl.severity) { 'green' => Tokens.accentGreen, 'yellow' => Tokens.accentYellow, 'red' => Tokens.accentRed, _ => Tokens.accentBlue };
      items.add(_DeadlineItem(label: dl.label, date: dl.date, color: color));
    }
    for (final m in milestones.take(3)) { items.add(_DeadlineItem(label: m.label, date: m.date, color: Tokens.accentYellow)); }
    items.sort((a, b) => a.date.compareTo(b.date));
    final upcomingDeadlines = items.take(3).toList();

    return _DashCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Date section
      Text(dayName, style: AppTheme.subheading.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xEBFFFFFF))),
      const SizedBox(height: 2),
      Text(monthDay, style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x9EFFFFFF))),
      const SizedBox(height: 8),
      Container(height: 1, color: Tokens.dashBorder),
      const SizedBox(height: 8),
      // Weather section
      weatherAsync.when(
        loading: () => Row(children: [
          const Icon(Icons.cloud_queue, size: 20, color: Color(0x6BFFFFFF)), const SizedBox(width: 8),
          Text('Loading weather...', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF))),
        ]),
        error: (_, __) => Row(children: [
          const Icon(Icons.cloud_off, size: 20, color: Color(0x42FFFFFF)), const SizedBox(width: 8),
          Text('No weather data', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF))),
        ]),
        data: (weather) {
          if (weather == null) return Row(children: [
            const Icon(Icons.cloud_off, size: 20, color: Color(0x42FFFFFF)), const SizedBox(width: 8),
            Text('No weather data', style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x6BFFFFFF))),
          ]);
          return Row(children: [
            Icon(_weatherIcon(weather.weatherCode), size: 24, color: Tokens.accentYellow),
            const SizedBox(width: 8),
            Text('${weather.temperature.round()}\u00B0F', style: AppTheme.subheading.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xEBFFFFFF))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(weather.iconLabel, style: AppTheme.caption.copyWith(fontSize: 10, color: const Color(0x9EFFFFFF))),
              Text('Wind ${weather.windSpeed.round()} mph', style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF))),
            ])),
          ]);
        },
      ),
      // Deadlines section
      if (upcomingDeadlines.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(height: 1, color: Tokens.dashBorder),
        const SizedBox(height: 6),
        Text('UPCOMING', style: AppTheme.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0x6BFFFFFF), letterSpacing: 1)),
        const SizedBox(height: 4),
        Expanded(child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: upcomingDeadlines.length,
          itemBuilder: (context, i) {
            final item = upcomingDeadlines[i];
            final dateStr = '${_months[item.date.month - 1]} ${item.date.day}';
            final daysLeft = item.date.difference(now).inDays;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(item.label, style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0xEBFFFFFF)), overflow: TextOverflow.ellipsis)),
              Text('${daysLeft}d · $dateStr', style: AppTheme.caption.copyWith(fontSize: 8, color: item.color, fontWeight: FontWeight.w600)),
            ]));
          },
        )),
      ] else
        const Spacer(),
    ]));
  }
}

// ── Full Project Information Panel ────────────────────────
class _FullProjectInfoPanel extends ConsumerWidget {
  static const _sourceColors = {
    'sheet': Tokens.accentGreen,
    'city': Tokens.accentBlue,
    'contract': Tokens.accentYellow,
    'inferred': Color(0xFFFF9800),
    'manual': Color(0x9EFFFFFF),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure enrichment provider runs (populates site, codes, address data)
    ref.watch(enrichProjectInfoProvider);
    final entries = ref.watch(projectInfoProvider);
    final contractMeta = ref.watch(contractMetadataProvider);

    // Group by category — only show project-relevant categories on dashboard
    const showCategories = {'General', 'Codes & Standards', 'Zoning', 'Site'};
    final grouped = <String, List<ProjectInfoEntry>>{};
    for (final e in entries) {
      if (showCategories.contains(e.category)) {
        grouped.putIfAbsent(e.category, () => []).add(e);
      }
    }
    // Split into 2 columns: Left = General, Zoning, Site | Right = Codes & Standards + Contract meta
    final leftCats = ['General', 'Zoning', 'Site'].where((c) => grouped.containsKey(c)).toList();
    final rightCats = ['Codes & Standards'].where((c) => grouped.containsKey(c)).toList();

    Widget buildCatSection(String cat) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.only(top: 6, bottom: 4), child: Text(cat.toUpperCase(),
        style: AppTheme.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w700, color: Tokens.accent, letterSpacing: 1.2))),
      ...grouped[cat]!.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(e.label, style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF)))),
        Expanded(child: Text(e.value.isEmpty ? '—' : e.value, style: AppTheme.body.copyWith(fontSize: 10, color: e.value.isEmpty ? const Color(0x42FFFFFF) : const Color(0xEBFFFFFF)), overflow: TextOverflow.ellipsis)),
        if (e.source != 'manual') Padding(padding: const EdgeInsets.only(left: 4), child: Container(
          width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _sourceColors[e.source] ?? const Color(0x42FFFFFF)))),
      ]))),
      const SizedBox(height: 2),
      Container(height: 1, color: Tokens.dashBorder.withValues(alpha: 0.5)),
    ]);

    return _DashCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline, size: 14, color: Tokens.accent),
        const SizedBox(width: 6),
        Text('PROJECT INFORMATION', style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xEBFFFFFF), letterSpacing: 1)),
      ]),
      const SizedBox(height: 8),
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Left column: General, Zoning, Site
        Expanded(child: ListView(padding: EdgeInsets.zero, children: [
          for (final cat in leftCats) buildCatSection(cat),
          // Contract metadata at bottom of left column
          contractMeta.when(
            loading: () => Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: SizedBox(height: 12, width: 80,
              child: LinearProgressIndicator(color: Tokens.accent, backgroundColor: const Color(0x14FFFFFF))))),
            error: (_, __) => const SizedBox.shrink(),
            data: (contracts) {
              if (contracts.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('DISCOVERED FROM FILES',
                  style: AppTheme.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w700, color: Tokens.accent, letterSpacing: 1.2))),
                _infoRow('Contracts Found', '${contracts.length}'),
                if (contracts.first.projectNumber.isNotEmpty)
                  _infoRow('Project Number', contracts.first.projectNumber),
                if (contracts.first.parties.isNotEmpty)
                  _infoRow('Parties', contracts.first.parties),
                _infoRow('Contract Date', '${_months[contracts.first.date.month - 1]} ${contracts.first.date.day}, ${contracts.first.date.year}'),
              ]);
            },
          ),
        ])),
        const SizedBox(width: 16),
        // Right column: Codes & Standards
        Expanded(child: ListView(padding: EdgeInsets.zero, children: [
          for (final cat in rightCats) buildCatSection(cat),
        ])),
      ])),
    ]));
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  Widget _infoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(children: [
    SizedBox(width: 110, child: Text(label, style: AppTheme.caption.copyWith(fontSize: 9, color: const Color(0x6BFFFFFF)))),
    Expanded(child: Text(value, style: AppTheme.body.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis)),
  ]));
}
// ── Project Team Card ─────────────────────────────────────
class _ProjectTeamCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProjectTeamCard> createState() => _ProjectTeamCardState();
}

class _ProjectTeamCardState extends ConsumerState<_ProjectTeamCard> {
  String? _activeCompany; // null = All

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(teamProvider);
    final companies = team.map((m) => m.company).toSet().toList()..sort();
    final filtered = _activeCompany == null ? team : team.where((m) => m.company == _activeCompany).toList();

    return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header + tabs
      Row(children: [
        Text('PROJECT TEAM', style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xEBFFFFFF))),
        const SizedBox(width: 6),
        Text('${team.length}', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w700)),
        const Spacer(),
        InkWell(onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.projectTeam),
          borderRadius: BorderRadius.circular(4), mouseCursor: SystemMouseCursors.click, hoverColor: const Color(0x0AFFFFFF),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('See all', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent)))),
      ]),
      const SizedBox(height: 6),
      // Company filter tabs
      SizedBox(height: 22, child: ListView(scrollDirection: Axis.horizontal, children: [
        _teamTab('All', _activeCompany == null, () => setState(() => _activeCompany = null)),
        ...companies.map((c) => _teamTab(c, _activeCompany == c, () => setState(() => _activeCompany = c))),
      ])),
      const SizedBox(height: 8),
      // Team members list
      Expanded(child: filtered.isEmpty
        ? Center(child: Text('No team members', style: AppTheme.caption.copyWith(color: const Color(0x6BFFFFFF))))
        : ListView.builder(padding: EdgeInsets.zero, itemCount: filtered.length, itemBuilder: (context, i) {
            final m = filtered[i];
            final initials = m.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
            return InkWell(
              onTap: () => ref.read(navProvider.notifier).selectPage(NavRoute.projectTeam),
              mouseCursor: SystemMouseCursors.click, hoverColor: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(6),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2), child: Row(children: [
                CircleAvatar(radius: 12, backgroundColor: m.avatarColor.withValues(alpha: 0.2),
                  child: Text(initials, style: TextStyle(color: m.avatarColor, fontSize: 8, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Expanded(child: Text(m.name, style: AppTheme.body.copyWith(fontSize: 11, color: const Color(0xEBFFFFFF)), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(m.role, style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.accent), overflow: TextOverflow.ellipsis)),
              ])),
            );
          })),
    ]));
  }

  Widget _teamTab(String label, bool active, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? Tokens.accent.withValues(alpha: 0.15) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? Tokens.accent.withValues(alpha: 0.4) : Tokens.dashBorder),
        ),
        child: Text(label, style: AppTheme.caption.copyWith(fontSize: 9, color: active ? Tokens.accent : const Color(0x6BFFFFFF), fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    ),
  );
}
class _DeadlineItem {
  final String label;
  final DateTime date;
  final Color color;
  const _DeadlineItem({required this.label, required this.date, required this.color});
}
class _TodosCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TodosCard> createState() => _TodosCardState();
}

class _TodosCardState extends ConsumerState<_TodosCard> {
  final _controller = TextEditingController();
  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(todosProvider.notifier).add(text);
    _controller.clear();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final incomplete = todos.where((t) => !t.done).toList();
    final display = incomplete.take(4).toList();
    return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('QUICK TO-DOS', style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xEBFFFFFF))),
        const Spacer(),
        InkWell(onTap: () => showTodoDialog(context, ref), borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click, hoverColor: Tokens.accent.withValues(alpha: 0.08),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Tokens.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text('+ New', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent, fontWeight: FontWeight.w600)))),
      ]),
      const SizedBox(height: 8),
      Expanded(child: display.isEmpty
        ? Center(child: Text('All done!', style: AppTheme.caption.copyWith(color: Tokens.accentGreen)))
        : ListView.builder(padding: EdgeInsets.zero, itemCount: display.length, itemBuilder: (context, i) {
            final todo = display[i];
            return InkWell(onTap: () => ref.read(todosProvider.notifier).toggle(todo.id),
              mouseCursor: SystemMouseCursors.click, hoverColor: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(4),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: Row(children: [
                SizedBox(width: 20, height: 20, child: Checkbox(value: todo.done, onChanged: (_) => ref.read(todosProvider.notifier).toggle(todo.id),
                  activeColor: Tokens.accent, side: const BorderSide(color: Color(0x6BFFFFFF)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
                const SizedBox(width: 8),
                Expanded(child: Text(todo.text, style: AppTheme.body.copyWith(fontSize: 11, color: const Color(0xEBFFFFFF)), overflow: TextOverflow.ellipsis)),
              ])));
          })),
      SizedBox(height: 30, child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: const Color(0x0AFFFFFF), border: Border.all(color: Tokens.dashBorder), borderRadius: BorderRadius.circular(6)),
          child: TextField(controller: _controller, style: AppTheme.body.copyWith(fontSize: 11, color: const Color(0xEBFFFFFF)),
            decoration: InputDecoration(hintText: 'Add to-do...', hintStyle: AppTheme.body.copyWith(fontSize: 11, color: const Color(0x42FFFFFF)),
              isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), border: InputBorder.none),
            onSubmitted: (_) => _addTodo()))),
        const SizedBox(width: 4),
        SizedBox(width: 30, height: 30, child: IconButton(padding: EdgeInsets.zero, iconSize: 16,
          icon: const Icon(Icons.add, color: Tokens.accent),
          style: IconButton.styleFrom(backgroundColor: Tokens.accent.withValues(alpha: 0.12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          onPressed: _addTodo)),
      ])),
    ]));
  }
}
