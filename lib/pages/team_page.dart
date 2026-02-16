import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';
import '../widgets/crud_dialogs.dart';

class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});

  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  String _searchQuery = '';
  String? _companyFilter; // null means "All"

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(teamProvider);

    // Collect unique companies for filter chips
    final companies = team.map((m) => m.company).toSet().toList()..sort();

    // Apply filters
    final filtered = team.where((m) {
      // Company filter
      if (_companyFilter != null && m.company != _companyFilter) return false;
      // Search filter (case-insensitive on name, role, company)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack =
            '${m.name} ${m.role} ${m.company}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Row(
            children: [
              Text('PROJECT TEAM', style: AppTheme.heading),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add_outlined, size: 20, color: Tokens.accent),
                tooltip: 'Add Team Member',
                onPressed: () => showTeamMemberDialog(context, ref),
              ),
              const Spacer(),
              _StatChip(label: '${team.length} Members', icon: Icons.people_outline),
              const SizedBox(width: 8),
              _StatChip(label: '${companies.length} Firms', icon: Icons.business_outlined),
              const SizedBox(width: 8),
              _AddButton(onTap: () => showTeamMemberDialog(context, ref)),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),

          // ── Search + Company filter row ─────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search field
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTheme.body.copyWith(fontSize: 12, color: Tokens.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search name, role, company...',
                    hintStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Tokens.textMuted),
                    prefixIconConstraints: const BoxConstraints(minWidth: 34),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    filled: true,
                    fillColor: Tokens.glassFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      borderSide: const BorderSide(color: Tokens.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      borderSide: const BorderSide(color: Tokens.accent, width: 1.2),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // "All" chip
              _FilterChip(
                label: 'All',
                selected: _companyFilter == null,
                onTap: () => setState(() => _companyFilter = null),
              ),

              // One chip per company
              ...companies.map((c) => _FilterChip(
                label: c,
                selected: _companyFilter == c,
                onTap: () => setState(() => _companyFilter = c),
              )),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),

          // ── Grid or empty state ─────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 40, color: Tokens.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No matches',
                          style: AppTheme.body.copyWith(color: Tokens.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search or filter.',
                          style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth > 900
                          ? 3
                          : constraints.maxWidth > 550
                              ? 2
                              : 1;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _TeamCard(member: filtered[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Tokens.accent.withValues(alpha: 0.18) : Tokens.glassFill,
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(
            color: selected ? Tokens.accent : Tokens.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            color: selected ? Tokens.accent : Tokens.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Stat chip ───────────────────────────────────────────────
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

// ── Team card ───────────────────────────────────────────────
class _TeamCard extends ConsumerWidget {
  final TeamMember member;
  const _TeamCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => showTeamMemberDialog(context, ref, existing: member),
                child: const Icon(Icons.edit_outlined, size: 16, color: Tokens.textMuted),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final confirmed = await showDeleteConfirmation(context, member.name);
                  if (confirmed) ref.read(teamProvider.notifier).remove(member.id);
                },
                child: const Icon(Icons.delete_outline, size: 16, color: Tokens.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Tokens.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: Tokens.accent),
            const SizedBox(width: 4),
            Text('Add', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
