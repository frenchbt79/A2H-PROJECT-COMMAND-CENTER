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

// -- ASI (Add / Edit) --
Future<void> showAsiDialog(BuildContext context, WidgetRef ref, {AsiItem? existing}) async {
  final isEdit = existing != null;
  final numberCtrl = TextEditingController(text: existing?.number ?? '');
  final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
  final sheetsCtrl = TextEditingController(text: existing?.affectedSheets ?? '');
  final issuedByCtrl = TextEditingController(text: existing?.issuedBy ?? '');
  String selectedStatus = existing?.status ?? 'Draft';

  if (!isEdit) {
    numberCtrl.text = ref.read(asisProvider.notifier).nextNumber();
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
        title: Text(isEdit ? 'Edit ASI' : 'New ASI', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: numberCtrl, label: 'ASI Number *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: subjectCtrl, label: 'Subject *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: sheetsCtrl, label: 'Affected Sheets'),
                const SizedBox(height: 12),
                _DialogTextField(controller: issuedByCtrl, label: 'Issued By'),
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
                  items: ['Draft', 'Issued', 'Void'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
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

  if (confirmed == true && numberCtrl.text.trim().isNotEmpty && subjectCtrl.text.trim().isNotEmpty) {
    if (isEdit) {
      ref.read(asisProvider.notifier).update(AsiItem(
        id: existing.id,
        number: numberCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        status: selectedStatus,
        dateIssued: existing.dateIssued,
        affectedSheets: sheetsCtrl.text.trim().isNotEmpty ? sheetsCtrl.text.trim() : null,
        issuedBy: issuedByCtrl.text.trim().isNotEmpty ? issuedByCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('ASI updated'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(asisProvider.notifier).add(AsiItem(
        id: id,
        number: numberCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        status: selectedStatus,
        dateIssued: DateTime.now(),
        affectedSheets: sheetsCtrl.text.trim().isNotEmpty ? sheetsCtrl.text.trim() : null,
        issuedBy: issuedByCtrl.text.trim().isNotEmpty ? issuedByCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('ASI created successfully'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- Change Order (Add / Edit) --
Future<void> showChangeOrderDialog(BuildContext context, WidgetRef ref, {ChangeOrder? existing}) async {
  final isEdit = existing != null;
  final numberCtrl = TextEditingController(text: existing?.number ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
  final initiatedByCtrl = TextEditingController(text: existing?.initiatedBy ?? '');
  String selectedStatus = existing?.status ?? 'Pending';
  String? selectedReason = existing?.reason;

  if (!isEdit) {
    numberCtrl.text = ref.read(changeOrdersProvider.notifier).nextNumber();
  }

  const reasons = ['Owner Request', 'Field Condition', 'Design Error', 'Code Requirement', 'Value Engineering'];

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        title: Text(isEdit ? 'Edit Change Order' : 'New Change Order', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: numberCtrl, label: 'CO Number *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: descCtrl, label: 'Description *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: amountCtrl, label: 'Amount (\$) *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: initiatedByCtrl, label: 'Initiated By'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedReason,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Reason',
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
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    ...reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                ),
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
                  items: ['Pending', 'Approved', 'Rejected', 'Void'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
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
      descCtrl.text.trim().isNotEmpty &&
      amountCtrl.text.trim().isNotEmpty) {
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (isEdit) {
      ref.read(changeOrdersProvider.notifier).update(ChangeOrder(
        id: existing.id,
        number: numberCtrl.text.trim(),
        description: descCtrl.text.trim(),
        amount: amount,
        status: selectedStatus,
        dateSubmitted: existing.dateSubmitted,
        dateResolved: (selectedStatus == 'Approved' || selectedStatus == 'Rejected') && existing.dateResolved == null
            ? DateTime.now() : existing.dateResolved,
        initiatedBy: initiatedByCtrl.text.trim().isNotEmpty ? initiatedByCtrl.text.trim() : null,
        reason: selectedReason,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Change order updated'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(changeOrdersProvider.notifier).add(ChangeOrder(
        id: id,
        number: numberCtrl.text.trim(),
        description: descCtrl.text.trim(),
        amount: amount,
        status: selectedStatus,
        dateSubmitted: DateTime.now(),
        initiatedBy: initiatedByCtrl.text.trim().isNotEmpty ? initiatedByCtrl.text.trim() : null,
        reason: selectedReason,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Change order created successfully'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- Submittal (Add / Edit) --
Future<void> showSubmittalDialog(BuildContext context, WidgetRef ref, {SubmittalItem? existing}) async {
  final isEdit = existing != null;
  final numberCtrl = TextEditingController(text: existing?.number ?? '');
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final specCtrl = TextEditingController(text: existing?.specSection ?? '');
  final submittedByCtrl = TextEditingController(text: existing?.submittedBy ?? '');
  final assignedToCtrl = TextEditingController(text: existing?.assignedTo ?? '');
  String selectedStatus = existing?.status ?? 'Pending';

  if (!isEdit) {
    numberCtrl.text = ref.read(submittalsProvider.notifier).nextNumber();
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
        title: Text(isEdit ? 'Edit Submittal' : 'New Submittal', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: numberCtrl, label: 'Submittal Number *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: titleCtrl, label: 'Title *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: specCtrl, label: 'Spec Section *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: submittedByCtrl, label: 'Submitted By'),
                const SizedBox(height: 12),
                _DialogTextField(controller: assignedToCtrl, label: 'Reviewer / Assigned To'),
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
                  items: ['Pending', 'Approved', 'Approved as Noted', 'Revise & Resubmit', 'Rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
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
      titleCtrl.text.trim().isNotEmpty &&
      specCtrl.text.trim().isNotEmpty) {
    if (isEdit) {
      ref.read(submittalsProvider.notifier).update(SubmittalItem(
        id: existing.id,
        number: numberCtrl.text.trim(),
        title: titleCtrl.text.trim(),
        specSection: specCtrl.text.trim(),
        status: selectedStatus,
        dateSubmitted: existing.dateSubmitted,
        dateReturned: selectedStatus != 'Pending' && existing.dateReturned == null ? DateTime.now() : existing.dateReturned,
        submittedBy: submittedByCtrl.text.trim().isNotEmpty ? submittedByCtrl.text.trim() : null,
        assignedTo: assignedToCtrl.text.trim().isNotEmpty ? assignedToCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Submittal updated'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      ref.read(submittalsProvider.notifier).add(SubmittalItem(
        id: id,
        number: numberCtrl.text.trim(),
        title: titleCtrl.text.trim(),
        specSection: specCtrl.text.trim(),
        status: selectedStatus,
        dateSubmitted: DateTime.now(),
        submittedBy: submittedByCtrl.text.trim().isNotEmpty ? submittedByCtrl.text.trim() : null,
        assignedTo: assignedToCtrl.text.trim().isNotEmpty ? assignedToCtrl.text.trim() : null,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Submittal created successfully'),
          backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
      }
    }
  }
}

// -- Contract (Add / Edit) --
Future<void> showContractDialog(BuildContext context, WidgetRef ref, {ContractItem? existing}) async {
  final isEdit = existing != null;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final amountCtrl = TextEditingController(text: existing != null ? existing.amount.toString() : '');
  String selectedType = existing?.type ?? 'Original';
  String selectedStatus = existing?.status ?? 'Pending';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        title: Text(isEdit ? 'Edit Contract' : 'New Contract', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: titleCtrl, label: 'Description *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: amountCtrl, label: 'Amount (\$) *'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: _dropdownDecoration('Type'),
                  items: ['Original', 'Amendment', 'Change Order'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: _dropdownDecoration('Status'),
                  items: ['Executed', 'Pending', 'Draft'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent))),
        ],
      ),
    ),
  );

  if (confirmed == true && titleCtrl.text.trim().isNotEmpty && amountCtrl.text.trim().isNotEmpty) {
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (isEdit) {
      ref.read(contractsProvider.notifier).update(ContractItem(
        id: existing.id, title: titleCtrl.text.trim(), type: selectedType,
        amount: amount, status: selectedStatus, date: existing.date,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Contract updated'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    } else {
      ref.read(contractsProvider.notifier).add(ContractItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(), title: titleCtrl.text.trim(),
        type: selectedType, amount: amount, status: selectedStatus, date: DateTime.now(),
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Contract added'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    }
  }
}

// -- Schedule Phase (Add / Edit) --
Future<void> showSchedulePhaseDialog(BuildContext context, WidgetRef ref, {SchedulePhase? existing}) async {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final progressCtrl = TextEditingController(text: existing != null ? (existing.progress * 100).toInt().toString() : '0');
  String selectedStatus = existing?.status ?? 'Upcoming';
  DateTime startDate = existing?.start ?? DateTime.now();
  DateTime endDate = existing?.end ?? DateTime.now().add(const Duration(days: 30));

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        title: Text(isEdit ? 'Edit Phase' : 'New Phase', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: nameCtrl, label: 'Phase Name *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: progressCtrl, label: 'Progress (0-100) *'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: _dropdownDecoration('Status'),
                  items: ['Complete', 'In Progress', 'Upcoming'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                _DatePickerRow(label: 'Start', date: startDate, onPick: (d) => setDialogState(() => startDate = d)),
                const SizedBox(height: 12),
                _DatePickerRow(label: 'End', date: endDate, onPick: (d) => setDialogState(() => endDate = d)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent))),
        ],
      ),
    ),
  );

  if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
    final progress = (int.tryParse(progressCtrl.text.trim()) ?? 0).clamp(0, 100) / 100.0;
    if (isEdit) {
      ref.read(scheduleProvider.notifier).update(SchedulePhase(
        id: existing.id, name: nameCtrl.text.trim(), start: startDate, end: endDate,
        progress: progress, status: selectedStatus,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Phase updated'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    } else {
      ref.read(scheduleProvider.notifier).add(SchedulePhase(
        id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(),
        start: startDate, end: endDate, progress: progress, status: selectedStatus,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Phase added'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    }
  }
}

// -- Budget Line (Add / Edit) --
Future<void> showBudgetLineDialog(BuildContext context, WidgetRef ref, {BudgetLine? existing}) async {
  final isEdit = existing != null;
  final categoryCtrl = TextEditingController(text: existing?.category ?? '');
  final budgetedCtrl = TextEditingController(text: existing != null ? existing.budgeted.toString() : '');
  final spentCtrl = TextEditingController(text: existing != null ? existing.spent.toString() : '0');
  final committedCtrl = TextEditingController(text: existing != null ? existing.committed.toString() : '0');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Tokens.bgMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: const BorderSide(color: Tokens.glassBorder),
      ),
      title: Text(isEdit ? 'Edit Budget Line' : 'New Budget Line', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(controller: categoryCtrl, label: 'Category *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: budgetedCtrl, label: 'Budgeted (\$) *'),
              const SizedBox(height: 12),
              _DialogTextField(controller: spentCtrl, label: 'Spent (\$)'),
              const SizedBox(height: 12),
              _DialogTextField(controller: committedCtrl, label: 'Committed (\$)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary))),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent))),
      ],
    ),
  );

  if (confirmed == true && categoryCtrl.text.trim().isNotEmpty && budgetedCtrl.text.trim().isNotEmpty) {
    final budgeted = double.tryParse(budgetedCtrl.text.trim()) ?? 0;
    final spent = double.tryParse(spentCtrl.text.trim()) ?? 0;
    final committed = double.tryParse(committedCtrl.text.trim()) ?? 0;
    if (isEdit) {
      ref.read(budgetProvider.notifier).update(BudgetLine(
        id: existing.id, category: categoryCtrl.text.trim(),
        budgeted: budgeted, spent: spent, committed: committed,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Budget line updated'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    } else {
      ref.read(budgetProvider.notifier).add(BudgetLine(
        id: DateTime.now().millisecondsSinceEpoch.toString(), category: categoryCtrl.text.trim(),
        budgeted: budgeted, spent: spent, committed: committed,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Budget line added'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    }
  }
}

// -- Reusable dropdown decoration helper --
InputDecoration _dropdownDecoration(String label) => InputDecoration(
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
);

// -- Date picker row for dialogs --
class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DatePickerRow({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: Tokens.accent, surface: Tokens.bgMid),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Tokens.glassFill,
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(color: Tokens.glassBorder),
        ),
        child: Row(
          children: [
            Text('$label: ', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted)),
            Text('${date.month}/${date.day}/${date.year}', style: AppTheme.body.copyWith(fontSize: 13)),
            const Spacer(),
            const Icon(Icons.calendar_today, size: 14, color: Tokens.textMuted),
          ],
        ),
      ),
    );
  }
}

// -- Drawing Sheet (Add / Edit) --
Future<void> showDrawingSheetDialog(BuildContext context, WidgetRef ref, {DrawingSheet? existing, required String discipline}) async {
  final isEdit = existing != null;
  final sheetNumCtrl = TextEditingController(text: existing?.sheetNumber ?? '');
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final revCtrl = TextEditingController(text: existing != null ? existing.revision.toString() : '0');
  String selectedPhase = existing?.phase ?? 'CD';
  String selectedStatus = existing?.status ?? 'In Progress';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Tokens.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
          side: const BorderSide(color: Tokens.glassBorder),
        ),
        title: Text(isEdit ? 'Edit Drawing Sheet' : 'New Drawing Sheet', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(controller: sheetNumCtrl, label: 'Sheet Number *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: titleCtrl, label: 'Title *'),
                const SizedBox(height: 12),
                _DialogTextField(controller: revCtrl, label: 'Revision #'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPhase,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: _dropdownDecoration('Phase'),
                  items: ['SD', 'DD', 'CD'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPhase = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: Tokens.bgMid,
                  style: AppTheme.body.copyWith(fontSize: 13, color: Tokens.textPrimary),
                  decoration: _dropdownDecoration('Status'),
                  items: ['Current', 'In Progress', 'Review', 'Superseded'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: AppTheme.caption.copyWith(color: Tokens.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(isEdit ? 'Save' : 'Add', style: AppTheme.caption.copyWith(color: Tokens.accent))),
        ],
      ),
    ),
  );

  if (confirmed == true && sheetNumCtrl.text.trim().isNotEmpty && titleCtrl.text.trim().isNotEmpty) {
    final rev = int.tryParse(revCtrl.text.trim()) ?? 0;
    if (isEdit) {
      ref.read(drawingSheetsProvider.notifier).update(DrawingSheet(
        id: existing.id, sheetNumber: sheetNumCtrl.text.trim(), title: titleCtrl.text.trim(),
        discipline: discipline, phase: selectedPhase, revision: rev,
        lastRevised: DateTime.now(), status: selectedStatus,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Drawing sheet updated'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    } else {
      ref.read(drawingSheetsProvider.notifier).add(DrawingSheet(
        id: DateTime.now().millisecondsSinceEpoch.toString(), sheetNumber: sheetNumCtrl.text.trim(),
        title: titleCtrl.text.trim(), discipline: discipline, phase: selectedPhase,
        revision: rev, lastRevised: DateTime.now(), status: selectedStatus,
      ));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Drawing sheet added'), backgroundColor: Tokens.chipGreen, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
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
