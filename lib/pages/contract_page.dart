import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class ContractPage extends ConsumerWidget {
  const ContractPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsProvider);
    final totalOriginal = contracts.where((c) => c.type == 'Original').fold(0.0, (s, c) => s + c.amount);
    final totalAmendments = contracts.where((c) => c.type == 'Amendment').fold(0.0, (s, c) => s + c.amount);
    final totalCOs = contracts.where((c) => c.type == 'Change Order').fold(0.0, (s, c) => s + c.amount);
    final grandTotal = totalOriginal + totalAmendments + totalCOs;

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONTRACT', style: AppTheme.heading),
          const SizedBox(height: Tokens.spaceLg),
          // Summary row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final items = [
                _SummaryTile(label: 'Original Contract', value: _fmt(totalOriginal), color: Tokens.chipGreen),
                _SummaryTile(label: 'Amendments', value: _fmt(totalAmendments), color: Tokens.chipBlue),
                _SummaryTile(label: 'Change Orders', value: _fmt(totalCOs), color: Tokens.chipYellow),
                _SummaryTile(label: 'Current Value', value: _fmt(grandTotal), color: Tokens.accent),
              ];
              if (isWide) {
                return Row(children: items.map((t) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: t))).toList());
              }
              return Wrap(spacing: 12, runSpacing: 12, children: items.map((t) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: t)).toList());
            },
          ),
          const SizedBox(height: Tokens.spaceLg),
          // Contract list
          Expanded(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text('DESCRIPTION', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 2, child: Text('TYPE', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 2, child: Text('AMOUNT', style: AppTheme.sidebarGroupLabel.copyWith(height: 1))),
                        Expanded(flex: 1, child: Text('STATUS', style: AppTheme.sidebarGroupLabel)),
                      ],
                    ),
                  ),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: contracts.length,
                      separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                      itemBuilder: (context, i) => _ContractRow(contract: contracts[i]),
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

  static String _fmt(double v) {
    final neg = v < 0;
    final abs = v.abs();
    if (abs >= 1000000) return '${neg ? '-' : ''}\$${(abs / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '${neg ? '-' : ''}\$${(abs / 1000).toStringAsFixed(0)}K';
    return '${neg ? '-' : ''}\$${abs.toStringAsFixed(0)}';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Text(value, style: AppTheme.subheading.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  final ContractItem contract;
  const _ContractRow({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(contract.title, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: _TypeChip(type: contract.type),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ContractPage._fmt(contract.amount),
              style: AppTheme.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: contract.amount < 0 ? Tokens.chipRed : Tokens.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _StatusDot(status: contract.status),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'Original' => Tokens.chipGreen,
      'Amendment' => Tokens.chipBlue,
      _ => Tokens.chipYellow,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
        ),
        child: Text(type, style: AppTheme.caption.copyWith(fontSize: 10, color: color)),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Executed' => Tokens.chipGreen,
      'Pending' => Tokens.chipYellow,
      _ => Tokens.textMuted,
    };
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(status, style: AppTheme.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
