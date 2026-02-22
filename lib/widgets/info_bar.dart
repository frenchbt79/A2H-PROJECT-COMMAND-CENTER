import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../state/nav_state.dart';
import '../state/folder_scan_providers.dart';
import '../services/background_sync_service.dart';

/// Persistent info strip showing date, next deadline, open RFIs, pending todos, current phase.
class InfoBar extends ConsumerWidget {
  const InfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(deadlinesProvider);
    final rfis = ref.watch(rfisProvider);
    final todos = ref.watch(todosProvider);
    final phases = ref.watch(scheduleProvider);

    void nav(NavRoute route) => ref.read(navProvider.notifier).selectPage(route);

    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    // Next upcoming deadline
    final upcoming = deadlines.where((d) => d.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final nextDeadline = upcoming.isNotEmpty ? upcoming.first : null;
    final daysUntil = nextDeadline?.date.difference(now).inDays;

    // Open RFI count
    final openRfis = rfis.where((r) => r.status == 'Open').length;
    final pendingRfis = rfis.where((r) => r.status == 'Pending').length;

    // Pending todos
    final pendingTodos = todos.where((t) => !t.done).length;

    // Current phase
    final currentPhase = phases.where((p) => p.status == 'In Progress').toList();
    final phaseLabel = currentPhase.isNotEmpty ? currentPhase.first.name : 'No active phase';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Tokens.glassFill,
        border: Border(bottom: BorderSide(color: Tokens.glassBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Date
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: dateStr,
                    color: Tokens.accent,
                    onTap: () => nav(NavRoute.dashboard),
                  ),
                  const SizedBox(width: 20),
                  // Current phase
                  _InfoChip(
                    icon: Icons.play_circle_outline,
                    label: phaseLabel,
                    color: Tokens.chipBlue,
                    onTap: () => nav(NavRoute.schedule),
                  ),
                  const SizedBox(width: 20),
                  // Next deadline
                  if (nextDeadline != null) ...[
                    _InfoChip(
                      icon: Icons.flag_outlined,
                      label: '${nextDeadline.label} — ${daysUntil}d',
                      color: daysUntil! <= 7
                          ? Tokens.chipRed
                          : daysUntil <= 30
                              ? Tokens.chipYellow
                              : Tokens.chipGreen,
                      onTap: () => nav(NavRoute.schedule),
                    ),
                    const SizedBox(width: 20),
                  ],
                  // Open RFIs
                  _InfoChip(
                    icon: Icons.help_outline,
                    label: '$openRfis open · $pendingRfis pending RFIs',
                    color: openRfis > 0 ? Tokens.chipYellow : Tokens.chipGreen,
                    onTap: () => nav(NavRoute.rfis),
                  ),
                  const SizedBox(width: 20),
                  // Pending todos
                  _InfoChip(
                    icon: Icons.check_circle_outline,
                    label: '$pendingTodos to-dos',
                    color: pendingTodos > 5 ? Tokens.chipRed : Tokens.textSecondary,
                    onTap: () => nav(NavRoute.dashboard),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Scan Now button
          const _ScanNowButton(),
        ],
      ),
    );
  }
}

// ── Scan Now Button ─────────────────────────────────────────
class _ScanNowButton extends ConsumerWidget {
  const _ScanNowButton();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _lastScanLabel(ScanStatus scanStatus) {
    final t = scanStatus.lastScanTime;
    if (t == null) return 'Not scanned';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${_months[t.month - 1]} ${t.day}';
  }

  /// Build a label describing what's currently being scanned
  static String _scanTarget(WidgetRef ref) {
    final targets = <String>[];
    if (ref.watch(scannedGeneralProvider).isLoading) targets.add('Drawings');
    if (ref.watch(scannedContractsProvider).isLoading) targets.add('Contracts');
    if (ref.watch(scannedRfisProvider).isLoading) targets.add('RFIs');
    if (ref.watch(scannedAsisProvider).isLoading) targets.add('ASIs');
    if (ref.watch(enrichProjectInfoProvider).isLoading) targets.add('Project Info');
    if (ref.watch(weatherProvider).isLoading) targets.add('Weather');
    if (ref.watch(drawingMetadataProvider).isLoading) targets.add('Metadata');
    if (targets.isEmpty) return 'Scanning...';
    return 'Scanning ${targets.first}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanStatus = ref.watch(scanStatusProvider);
    final isScanning = scanStatus.isScanning;
    // Also detect if providers are actively loading (initial load or refresh)
    final anyLoading = ref.watch(scannedGeneralProvider).isLoading ||
        ref.watch(scannedContractsProvider).isLoading ||
        ref.watch(scannedRfisProvider).isLoading ||
        ref.watch(enrichProjectInfoProvider).isLoading;
    final showScanning = isScanning || anyLoading;
    final scanLabel = showScanning ? _scanTarget(ref) : 'Scan Now';

    return Tooltip(
      message: scanStatus.lastScanTime != null
          ? 'Last scan: ${_lastScanLabel(scanStatus)} \u2022 ${scanStatus.filesFound} files\nClick to scan for new & modified files'
          : 'Scan project folder for documents',
      child: InkWell(
        onTap: showScanning ? null : () => _runScan(context, ref),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: showScanning
                ? Tokens.chipYellow.withValues(alpha: 0.1)
                : Tokens.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Tokens.radiusSm),
            border: Border.all(
              color: showScanning
                  ? Tokens.chipYellow.withValues(alpha: 0.3)
                  : Tokens.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showScanning)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Tokens.chipYellow,
                  ),
                )
              else
                const Icon(Icons.radar, size: 13, color: Tokens.accent),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanLabel,
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: showScanning ? Tokens.chipYellow : Tokens.accent,
                    ),
                  ),
                  if (!showScanning)
                    Text(
                      _lastScanLabel(scanStatus),
                      style: AppTheme.caption.copyWith(fontSize: 8, color: Tokens.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runScan(BuildContext context, WidgetRef ref) async {
    final statusNotifier = ref.read(scanStatusProvider.notifier);
    statusNotifier.startScan();

    try {
      final container = ProviderScope.containerOf(context);
      await BackgroundSyncService.sync(
        container,
        onProgress: (status, progress) {
          // Status updates handled by the sync service
        },
      );

      final fileCount = ref.read(backgroundFileDataProvider)?.length ?? 0;
      statusNotifier.completeScan(fileCount);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync complete \u2022 $fileCount files indexed'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      statusNotifier.completeScan(0);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Tokens.chipRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _InfoChip({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppTheme.caption.copyWith(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
