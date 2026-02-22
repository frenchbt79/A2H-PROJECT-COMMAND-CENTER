import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
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
  String? _expandedFirm; // firm name currently expanded in detail panel
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(teamProvider);

    // Collect unique companies for filter chips
    final companies = team.map((m) => m.company).toSet().toList()..sort();

    // Apply filters
    final filtered = team.where((m) {
      if (_companyFilter != null && m.company != _companyFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack = '${m.name} ${m.role} ${m.company} ${m.email}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    // Group by company for firm view
    final firmMap = <String, List<TeamMember>>{};
    for (final m in filtered) {
      firmMap.putIfAbsent(m.company, () => []).add(m);
    }
    final firmNames = firmMap.keys.toList()..sort();

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
              _PasteButton(onPaste: () => _handlePasteText()),
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
                onTap: () => setState(() {
                  _companyFilter = null;
                  _expandedFirm = null;
                }),
              ),

              // One chip per company
              ...companies.map((c) => _FilterChip(
                label: c,
                selected: _companyFilter == c,
                onTap: () => setState(() {
                  _companyFilter = _companyFilter == c ? null : c;
                  _expandedFirm = c;
                }),
              )),
            ],
          ),
          const SizedBox(height: Tokens.spaceMd),

          // ── Main content ─────────────────────────────────────
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
                      final wide = constraints.maxWidth > 800;
                      if (wide && _expandedFirm != null && firmMap.containsKey(_expandedFirm)) {
                        // Desktop: firm detail panel on right
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Firm cards list
                            SizedBox(
                              width: 320,
                              child: _buildFirmList(firmNames, firmMap),
                            ),
                            const SizedBox(width: 16),
                            // Detail panel
                            Expanded(
                              child: _FirmDetailPanel(
                                firmName: _expandedFirm!,
                                members: firmMap[_expandedFirm!]!,
                                onEditMember: (m) => showTeamMemberDialog(context, ref, existing: m),
                                onDeleteMember: (m) async {
                                  final confirmed = await showDeleteConfirmation(context, m.name);
                                  if (confirmed) ref.read(teamProvider.notifier).remove(m.id);
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      // Default: firm cards grid with drop zone
                      return _buildDropTarget(
                        child: _buildFirmGrid(firmNames, firmMap, constraints),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmList(List<String> firmNames, Map<String, List<TeamMember>> firmMap) {
    return ListView.builder(
      itemCount: firmNames.length,
      itemBuilder: (context, i) {
        final firm = firmNames[i];
        final members = firmMap[firm]!;
        final isSelected = _expandedFirm == firm;
        return RepaintBoundary(child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FirmCard(
            firmName: firm,
            members: members,
            isSelected: isSelected,
            onTap: () => setState(() => _expandedFirm = firm),
          ),
        ));
      },
    );
  }

  Widget _buildFirmGrid(List<String> firmNames, Map<String, List<TeamMember>> firmMap, BoxConstraints constraints) {
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
        childAspectRatio: 1.6,
      ),
      itemCount: firmNames.length,
      itemBuilder: (context, i) {
        final firm = firmNames[i];
        final members = firmMap[firm]!;
        return RepaintBoundary(child: _FirmCard(
          firmName: firm,
          members: members,
          isSelected: false,
          onTap: () => setState(() => _expandedFirm = firm),
        ));
      },
    );
  }

  Widget _buildDropTarget({required Widget child}) {
    if (kIsWeb) return child;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(details);
      },
      child: Stack(
        children: [
          child,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.08),
                  border: Border.all(color: Tokens.accent, width: 2),
                  borderRadius: BorderRadius.circular(Tokens.radiusMd),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add, size: 40, color: Tokens.accent),
                      const SizedBox(height: 12),
                      Text(
                        'Drop text file to import team members',
                        style: AppTheme.body.copyWith(color: Tokens.accent, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CSV, TXT, or vCard files supported',
                        style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    int added = 0;
    for (final xfile in details.files) {
      final path = xfile.path;
      final lower = path.toLowerCase();
      if (!lower.endsWith('.txt') && !lower.endsWith('.csv') && !lower.endsWith('.vcf')) continue;
      try {
        final content = await File(path).readAsString();
        added += _parseAndAddMembers(content);
      } catch (_) {}
    }
    if (added > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imported $added team member${added == 1 ? '' : 's'}'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else if (added == 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No valid team data found in dropped file(s)'),
        backgroundColor: Tokens.chipYellow,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _handlePasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Clipboard is empty'),
          backgroundColor: Tokens.chipYellow,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
      return;
    }
    final added = _parseAndAddMembers(data.text!);
    if (added > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imported $added team member${added == 1 ? '' : 's'} from clipboard'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No valid team data found in clipboard'),
        backgroundColor: Tokens.chipYellow,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  /// Parse text content (CSV or line-based) and add team members.
  /// Expected formats:
  ///   CSV: Name, Role, Company, Email, Phone (one per line)
  ///   Simple: Name - Role - Company (one per line)
  /// Returns number of members added.
  int _parseAndAddMembers(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    int added = 0;

    for (final line in lines) {
      // Skip obvious headers
      if (line.toLowerCase().startsWith('name') && (line.contains(',') || line.contains('\t'))) continue;
      if (line.startsWith('#') || line.startsWith('//')) continue;

      String name = '', role = '', company = '', email = '', phone = '';

      // Try CSV (comma-separated)
      final csvParts = line.split(',').map((p) => p.trim()).toList();
      if (csvParts.length >= 3) {
        name = csvParts[0];
        role = csvParts[1];
        company = csvParts[2];
        if (csvParts.length > 3) email = csvParts[3];
        if (csvParts.length > 4) phone = csvParts[4];
      } else {
        // Try tab-separated
        final tabParts = line.split('\t').map((p) => p.trim()).toList();
        if (tabParts.length >= 3) {
          name = tabParts[0];
          role = tabParts[1];
          company = tabParts[2];
          if (tabParts.length > 3) email = tabParts[3];
          if (tabParts.length > 4) phone = tabParts[4];
        } else {
          // Try dash-separated
          final dashParts = line.split(' - ').map((p) => p.trim()).toList();
          if (dashParts.length >= 3) {
            name = dashParts[0];
            role = dashParts[1];
            company = dashParts[2];
          } else if (dashParts.length == 2) {
            name = dashParts[0];
            role = dashParts[1];
          }
        }
      }

      // Validate: at minimum need a name
      if (name.isEmpty || name.length < 2) continue;
      // Skip if name looks like a header
      if (name.toLowerCase() == 'name') continue;

      final id = DateTime.now().millisecondsSinceEpoch.toString() + added.toString();
      ref.read(teamProvider.notifier).add(TeamMember(
        id: id,
        name: name,
        role: role.isNotEmpty ? role : 'Team Member',
        company: company.isNotEmpty ? company : 'TBD',
        email: email,
        phone: phone,
      ));
      added++;
    }
    return added;
  }
}

// ── Firm Card (company overview) ────────────────────────────
class _FirmCard extends StatelessWidget {
  final String firmName;
  final List<TeamMember> members;
  final bool isSelected;
  final VoidCallback onTap;

  const _FirmCard({
    required this.firmName,
    required this.members,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pick the accent color from the first member
    final firmColor = members.first.avatarColor;
    final roles = members.map((m) => m.role).toSet().toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          border: isSelected
              ? Border.all(color: Tokens.accent, width: 1.5)
              : null,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Firm header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: firmColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        firmName.substring(0, firmName.length >= 2 ? 2 : 1).toUpperCase(),
                        style: AppTheme.body.copyWith(
                          color: firmColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firmName,
                          style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${members.length} member${members.length == 1 ? '' : 's'}',
                          style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Tokens.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              // Roles summary
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: roles.take(4).map((r) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Tokens.glassFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r,
                    style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.accent),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),
              // Member avatar row
              Row(
                children: [
                  ...members.take(5).map((m) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: m.avatarColor.withValues(alpha: 0.2),
                      child: Text(
                        m.name.split(' ').map((w) => w[0]).take(2).join(),
                        style: TextStyle(color: m.avatarColor, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )),
                  if (members.length > 5)
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Tokens.glassFill,
                      child: Text(
                        '+${members.length - 5}',
                        style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.textMuted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Firm Detail Panel (right side) ──────────────────────────
class _FirmDetailPanel extends StatelessWidget {
  final String firmName;
  final List<TeamMember> members;
  final ValueChanged<TeamMember> onEditMember;
  final ValueChanged<TeamMember> onDeleteMember;

  const _FirmDetailPanel({
    required this.firmName,
    required this.members,
    required this.onEditMember,
    required this.onDeleteMember,
  });

  @override
  Widget build(BuildContext context) {
    final firmColor = members.first.avatarColor;
    final roles = members.map((m) => m.role).toSet().toList()..sort();
    final emails = members.where((m) => m.email.isNotEmpty).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Firm header card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: firmColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          firmName.substring(0, firmName.length >= 3 ? 3 : firmName.length).toUpperCase(),
                          style: AppTheme.body.copyWith(
                            color: firmColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(firmName, style: AppTheme.heading.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            '${members.length} team member${members.length == 1 ? '' : 's'} \u2022 ${roles.length} role${roles.length == 1 ? '' : 's'}',
                            style: AppTheme.caption.copyWith(color: Tokens.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Discipline / role chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: roles.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Tokens.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      border: Border.all(color: Tokens.accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(r, style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.accent)),
                  )).toList(),
                ),
                if (emails.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 12, color: Tokens.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          emails.map((m) => m.email).join(', '),
                          style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textSecondary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // People list
          Text(
            'PEOPLE',
            style: AppTheme.caption.copyWith(fontSize: 10, letterSpacing: 0.8, color: Tokens.textMuted),
          ),
          const SizedBox(height: 8),
          ...members.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberDetailCard(
              member: m,
              onEdit: () => onEditMember(m),
              onDelete: () => onDeleteMember(m),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Member Detail Card (inside firm panel) ──────────────────
class _MemberDetailCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberDetailCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              children: [
                Text(member.name, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(member.role, style: AppTheme.caption.copyWith(color: Tokens.accent, fontSize: 11)),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 11, color: Tokens.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          member.email,
                          style: AppTheme.caption.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (member.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 11, color: Tokens.textMuted),
                      const SizedBox(width: 4),
                      Text(member.phone, style: AppTheme.caption.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16, color: Tokens.textMuted),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 16, color: Tokens.textMuted),
                ),
              ),
            ],
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
      child: Container(
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

// ── Paste Button ────────────────────────────────────────────
class _PasteButton extends StatelessWidget {
  final VoidCallback onPaste;
  const _PasteButton({required this.onPaste});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Import from clipboard\n(Name, Role, Company per line)',
      child: GestureDetector(
        onTap: onPaste,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Tokens.chipIndigo.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Tokens.radiusSm),
            border: Border.all(color: Tokens.chipIndigo.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.content_paste, size: 14, color: Tokens.chipIndigo),
              const SizedBox(width: 4),
              Text('Paste', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.chipIndigo, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
