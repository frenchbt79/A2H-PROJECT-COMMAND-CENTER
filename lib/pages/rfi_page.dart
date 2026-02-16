import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';

class RfiPage extends ConsumerWidget {
  const RfiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rfis = ref.watch(rfisProvider);
    final open = rfis.where((r) => r.status == 'Open').length;
    final pending = rfis.where((r) => r.status == 'Pending').length;
    final closed = rfis.where((r) => r.status == 'Closed').length;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('RFIs', style: AppTheme.heading),
              const Spacer(),
              _CountChip(label: 'Open', count: open, color: Tokens.chipYellow),
              const SizedBox(width: 8),
              _CountChip(label: 'Pending', count: pending, color: Tokens.chipBlue),
              const SizedBox(width: 8),
              _CountChip(label: 'Closed', count: closed, color: Tokens.chipGreen),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 80, child: Text('RFI #', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 4, child: Text('SUBJECT', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 2, child: Text('ASSIGNEE', style: AppTheme.sidebarGroupLabel)),
                        SizedBox(width: 90, child: Text('OPENED', style: AppTheme.sidebarGroupLabel)),
                        SizedBox(width: 70, child: Text('STATUS', style: AppTheme.sidebarGroupLabel)),
                      ],
                    ),
                  ),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: rfis.length,
                      separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                      itemBuilder: (context, i) {
                        final rfi = rfis[i];
                        final statusColor = switch (rfi.status) {
                          'Open' => Tokens.chipYellow,
                          'Pending' => Tokens.chipBlue,
                          _ => Tokens.chipGreen,
                        };
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(rfi.number, style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Tokens.accent)),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(rfi.subject, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(rfi.assignee ?? '—', style: AppTheme.caption.copyWith(fontSize: 11)),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  '${rfi.dateOpened.month}/${rfi.dateOpened.day}/${rfi.dateOpened.year}',
                                  style: AppTheme.caption.copyWith(fontSize: 10),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(Tokens.radiusSm),
                                  ),
                                  child: Text(rfi.status, style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor), textAlign: TextAlign.center),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
