import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

Future<bool> showDeleteConfirmation(BuildContext context, String itemName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text('Delete "$itemName"?', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      content: Text('This action cannot be undone.', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Delete', style: AppTheme.caption.copyWith(color: Tokens.chipRed)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// -- Team Member (Add / Edit) --
Future<void> showTeamMemberDialog(BuildContext context, WidgetRef ref, {TeamMember? existing}) async {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final roleCtrl = TextEditingController(text: existing?.role ?? '');
  final companyCtrl = TextEditingController(text: existing?.company ?? '');
  final emailCtrl = TextEditingController(text: existing?.email ?? '');
  final phoneCtrl = TextEditingController(text: existing?.phone ?? '');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text(isEdit ? 'Edit Team Member' : 'Add Team Member', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(controller: nameCtrl, label: 'Name *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: roleCtrl, label: 'Role *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: companyCtrl, label: 'Company *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: emailCtrl, label: 'Email'),
              const SizedBox(height: 12),
              _DialogTextField(controller: phoneCtrl, label: 'Phone'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
        ),
      ],
    ),
  );

  if (confirmed == true &&
      nameCtrl.text.trim().isNotEmpty &&
      roleCtrl.text.trim().isNotEmpty &&
      companyCtrl.text.trim().isNotEmpty) {
    if (isEdit) {
      ref.read(teamProvider.notifier).update(TeamMember(
        id: existing.id,
        name: nameCtrl.text.trim(),
        role: roleCtrl.text.trim(),
        company: companyCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        avatarColor: existing.avatarColor,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Team member updated'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(teamProvider.notifier).add(TeamMember(
        id: id,
        name: nameCtrl.text.trim(),
        role: roleCtrl.text.trim(),
        company: companyCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Added to project team'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- RFI (Add / Edit) --
Future<void> showRfiDialog(BuildContext context, WidgetRef ref, {RfiItem? existing}) async {
  final isEdit = existing != null;
  final numberCtrl = TextEditingController(text: existing?.number ?? '');
  final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
  final assigneeCtrl = TextEditingController(text: existing?.assignee ?? '');
  String selectedStatus = existing?.status ?? 'Open';

  if (!isEdit) {
    numberCtrl.text = ref.read(rfisProvider.notifier).nextNumber();
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        title: Text(isEdit ? 'Edit RFI' : 'New RFI', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: numberCtrl, label: 'RFI Number *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: subjectCtrl, label: 'Subject *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: assigneeCtrl, label: 'Assignee'),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    dropdownColor: Tokens.bgMid,
                    style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    items: ['Open', 'Pending', 'Closed'].map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true &&
      numberCtrl.text.trim().isNotEmpty &&
      subjectCtrl.text.trim().isNotEmpty) {
    if (isEdit) {
      ref.read(rfisProvider.notifier).update(RfiItem(
        id: existing.id,
        number: numberCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        status: selectedStatus,
        dateOpened: existing.dateOpened,
        dateClosed: selectedStatus == 'Closed' && existing.dateClosed == null ? DateTime.now() : existing.dateClosed,
        assignee: assigneeCtrl.text.trim().isNotEmpty ? assigneeCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('RFI updated'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(rfisProvider.notifier).add(RfiItem(
        id: id,
        number: numberCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        status: 'Open',
        dateOpened: DateTime.now(),
        assignee: assigneeCtrl.text.trim().isNotEmpty ? assigneeCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('RFI created successfully'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- Todo (Add / Edit) --
Future<void> showTodoDialog(BuildContext context, WidgetRef ref, {TodoItem? existing}) async {
  final isEdit = existing != null;
  final textCtrl = TextEditingController(text: existing?.text ?? '');
  final assigneeCtrl = TextEditingController(text: existing?.assignee ?? '');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text(isEdit ? 'Edit To-Do' : 'New To-Do', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(controller: textCtrl, label: 'Task description *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: assigneeCtrl, label: 'Assignee'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
        ),
      ],
    ),
  );

  if (confirmed == true && textCtrl.text.trim().isNotEmpty) {
    if (isEdit) {
      ref.read(todosProvider.notifier).edit(
        existing.id,
        text: textCtrl.text.trim(),
        assignee: assigneeCtrl.text.trim().isNotEmpty ? assigneeCtrl.text.trim() : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('To-do updated'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      ref.read(todosProvider.notifier).add(
        textCtrl.text.trim(),
        assignee: assigneeCtrl.text.trim().isNotEmpty ? assigneeCtrl.text.trim() : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('To-do added'),
          backgroundColor: Tokens.chipGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- Reusable styled text field --
class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _DialogTextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    );
  }
}
