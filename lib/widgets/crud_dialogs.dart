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

// -- Add Team Member --
Future<void> showAddTeamMemberDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text('Add Team Member', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
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
          child: Text('Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
        ),
      ],
    ),
  );

  if (confirmed == true &&
      nameCtrl.text.trim().isNotEmpty &&
      roleCtrl.text.trim().isNotEmpty &&
      companyCtrl.text.trim().isNotEmpty) {
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
        content: Text('Added to project team'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// -- Add RFI --
Future<void> showAddRfiDialog(BuildContext context, WidgetRef ref) async {
  final numberCtrl = TextEditingController();
  final subjectCtrl = TextEditingController();
  final assigneeCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text('New RFI', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
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
          child: Text('Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
        ),
      ],
    ),
  );

  if (confirmed == true &&
      numberCtrl.text.trim().isNotEmpty &&
      subjectCtrl.text.trim().isNotEmpty) {
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
        content: Text('RFI created successfully'),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// -- Add Todo --
Future<void> showAddTodoDialog(BuildContext context, WidgetRef ref) async {
  final textCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text('New To-Do', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: _DialogTextField(controller: textCtrl, label: 'Task description *'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Add', style: AppTheme.caption.copyWith(color: Tokens.accent)),
        ),
      ],
    ),
  );

  if (confirmed == true && textCtrl.text.trim().isNotEmpty) {
    ref.read(todosProvider.notifier).add(textCtrl.text.trim());
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
