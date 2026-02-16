import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

Future<void> showAddTodoDialog(BuildContext context, WidgetRef ref) async {
  final textCtrl = TextEditingController();
  final assigneeCtrl = TextEditingController();
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Row(children: [
        const Icon(Icons.add_task, size: 20, color: Tokens.accent),
        const SizedBox(width: 8),
        Text('New To-Do', style: AppTheme.subheading),
      ]),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _DialogTextField(controller: textCtrl, label: 'Task description', autofocus: true),
        const SizedBox(height: 12),
        _DialogTextField(controller: assigneeCtrl, label: 'Assignee (optional)'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary))),
        FilledButton(
          onPressed: () {
            final text = textCtrl.text.trim();
            if (text.isEmpty) return;
            ref.read(todosProvider.notifier).add(text,
              assignee: assigneeCtrl.text.trim().isEmpty ? null : assigneeCtrl.text.trim());
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: Tokens.accent),
          child: const Text('Add')),
      ],
    ),
  );
}
// Convenience aliases used by pages
Future<void> showAddTeamMemberDialog(BuildContext context, WidgetRef ref) =>
    showTeamMemberDialog(context, ref);

Future<void> showAddRfiDialog(BuildContext context, WidgetRef ref) =>
    showRfiDialog(context, ref);

Future<void> showTeamMemberDialog(BuildContext context, WidgetRef ref, {TeamMember? existing}) async {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final roleCtrl = TextEditingController(text: existing?.role ?? '');
  final companyCtrl = TextEditingController(text: existing?.company ?? '');
  final emailCtrl = TextEditingController(text: existing?.email ?? '');
  final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Row(children: [
        Icon(isEdit ? Icons.edit_outlined : Icons.person_add_outlined, size: 20, color: Tokens.accent),
        const SizedBox(width: 8),
        Text(isEdit ? 'Edit Team Member' : 'Add Team Member', style: AppTheme.subheading),
      ]),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _DialogTextField(controller: nameCtrl, label: 'Full name', autofocus: !isEdit),
        const SizedBox(height: 10),
        _DialogTextField(controller: roleCtrl, label: 'Role / Title'),
        const SizedBox(height: 10),
        _DialogTextField(controller: companyCtrl, label: 'Company / Firm'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _DialogTextField(controller: emailCtrl, label: 'Email')),
          const SizedBox(width: 10),
          Expanded(child: _DialogTextField(controller: phoneCtrl, label: 'Phone')),
        ]),
      ])),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirmed = await showDeleteConfirmation(context, existing.name);
              if (confirmed) ref.read(teamProvider.notifier).remove(existing.id);
            },
            child: Text('Delete', style: AppTheme.body.copyWith(color: Tokens.chipRed)),
          ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary))),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            if (isEdit) {
              ref.read(teamProvider.notifier).update(TeamMember(
                id: existing.id, name: name,
                role: roleCtrl.text.trim(), company: companyCtrl.text.trim(),
                email: emailCtrl.text.trim(), phone: phoneCtrl.text.trim(),
                avatarColor: existing.avatarColor,
              ));
            } else {
              final colors = [Colors.blue, Colors.teal, Colors.indigo, Colors.deepPurple,
                Colors.cyan, Colors.green, Colors.orange, Colors.pink];
              ref.read(teamProvider.notifier).add(TeamMember(
                id: 'tm${DateTime.now().millisecondsSinceEpoch}', name: name,
                role: roleCtrl.text.trim(), company: companyCtrl.text.trim(),
                email: emailCtrl.text.trim(), phone: phoneCtrl.text.trim(),
                avatarColor: colors[DateTime.now().millisecond % colors.length],
              ));
            }
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: Tokens.accent),
          child: Text(isEdit ? 'Save' : 'Add')),
      ],
    ),
  );
}
Future<void> showRfiDialog(BuildContext context, WidgetRef ref, {RfiItem? existing}) async {
  final isEdit = existing != null;
  final numberCtrl = TextEditingController(text: existing?.number ?? '');
  final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
  final assigneeCtrl = TextEditingController(text: existing?.assignee ?? '');
  if (!isEdit) {
    final rfis = ref.read(rfisProvider);
    final nextNum = rfis.length + 1;
    numberCtrl.text = 'RFI-${nextNum.toString().padLeft(3, '0')}';
  }
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Row(children: [
        const Icon(Icons.help_outline, size: 20, color: Tokens.accent),
        const SizedBox(width: 8),
        Text(isEdit ? 'Edit RFI' : 'New RFI', style: AppTheme.subheading),
      ]),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _DialogTextField(controller: numberCtrl, label: 'RFI Number'),
        const SizedBox(height: 10),
        _DialogTextField(controller: subjectCtrl, label: 'Subject', autofocus: !isEdit),
        const SizedBox(height: 10),
        _DialogTextField(controller: assigneeCtrl, label: 'Assignee (optional)'),
      ])),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirmed = await showDeleteConfirmation(context, existing.number);
              if (confirmed) ref.read(rfisProvider.notifier).remove(existing.id);
            },
            child: Text('Delete', style: AppTheme.body.copyWith(color: Tokens.chipRed)),
          ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary))),
        FilledButton(
          onPressed: () {
            final subject = subjectCtrl.text.trim();
            if (subject.isEmpty) return;
            if (isEdit) {
              ref.read(rfisProvider.notifier).remove(existing.id);
              ref.read(rfisProvider.notifier).add(RfiItem(
                id: existing.id, number: numberCtrl.text.trim(),
                subject: subject, status: existing.status,
                dateOpened: existing.dateOpened, dateClosed: existing.dateClosed,
                assignee: assigneeCtrl.text.trim().isEmpty ? null : assigneeCtrl.text.trim(),
              ));
            } else {
              ref.read(rfisProvider.notifier).add(RfiItem(
                id: 'rfi${DateTime.now().millisecondsSinceEpoch}',
                number: numberCtrl.text.trim(), subject: subject,
                status: 'Open', dateOpened: DateTime.now(),
                assignee: assigneeCtrl.text.trim().isEmpty ? null : assigneeCtrl.text.trim(),
              ));
            }
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: Tokens.accent),
          child: Text(isEdit ? 'Save' : 'Create')),
      ],
    ),
  );
}
Future<bool> showDeleteConfirmation(BuildContext context, String itemName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      title: Text('Delete?', style: AppTheme.subheading),
      content: Text(
        'Remove "$itemName"? This cannot be undone.',
        style: AppTheme.body.copyWith(fontSize: 13),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: AppTheme.body.copyWith(color: Tokens.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
          child: Text('Delete', style: AppTheme.body.copyWith(color: Tokens.chipRed, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  return result ?? false;
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  const _DialogTextField({required this.controller, required this.label, this.autofocus = false});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
        filled: true,
        fillColor: Tokens.bgDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          borderSide: const BorderSide(color: Tokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          borderSide: const BorderSide(color: Tokens.accent, width: 1.2),
        ),
      ),
    );
  }
}
