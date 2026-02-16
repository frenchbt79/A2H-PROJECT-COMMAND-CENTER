import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROJECT TEAM', style: AppTheme.heading),
              const Spacer(),
              _StatChip(label: '${team.length} Members', icon: Icons.people_outline),
              const SizedBox(width: 8),
              _StatChip(label: '${team.map((m) => m.company).toSet().length} Firms', icon: Icons.business_outlined),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 550 ? 2 : 1;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: team.length,
                  itemBuilder: (context, i) => _TeamCard(member: team[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Tokens.glassFill,
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border: Border.all(color: Tokens.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Tokens.accent),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textPrimary)),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamMember member;
  const _TeamCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: member.avatarColor.withValues(alpha: 0.2),
            child: Text(
              member.name.split(' ').map((w) => w[0]).take(2).join(),
              style: AppTheme.body.copyWith(
                color: member.avatarColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(member.name, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(member.role, style: AppTheme.caption.copyWith(color: Tokens.accent, fontSize: 11)),
                const SizedBox(height: 2),
                Text(member.company, style: AppTheme.caption.copyWith(fontSize: 10)),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 11, color: Tokens.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(member.email, style: AppTheme.caption.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
