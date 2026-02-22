import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

/// Toggle state for the Quick Add panel visibility.
final quickAddVisibleProvider = StateProvider<bool>((ref) => false);

/// Quick Add button that lives in the top bar next to search.
class QuickAddButton extends ConsumerWidget {
  const QuickAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(quickAddVisibleProvider);
    return InkWell(
      onTap: () => ref.read(quickAddVisibleProvider.notifier).state = !isOpen,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isOpen
              ? Tokens.accent.withValues(alpha: 0.2)
              : Tokens.glassFill,
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          border: Border.all(
            color: isOpen ? Tokens.accent : Tokens.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen ? Icons.close : Icons.add_circle_outline,
              size: 16,
              color: isOpen ? Tokens.accent : Tokens.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'Quick Add',
              style: AppTheme.caption.copyWith(
                fontSize: 11,
                color: isOpen ? Tokens.accent : Tokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The expandable Quick Add panel that slides down below the top bar.
class QuickAddPanel extends ConsumerStatefulWidget {
  const QuickAddPanel({super.key});

  @override
  ConsumerState<QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends ConsumerState<QuickAddPanel> {
  final _textController = TextEditingController();
  String _selectedTarget = 'Auto-detect';
  bool _isDragging = false;
  final _droppedFiles = <String>[];

  static const _targets = [
    'Auto-detect',
    'Project Info',
    'To-Do',
    'Team Member',
    'Schedule',
    'Budget',
    'Contract',
    'RFI',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Detect which target category the text best fits.
  String _autoDetect(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('todo') || lower.contains('to-do') || lower.contains('task') ||
        lower.contains('action item') || lower.contains('need to') || lower.contains('remind')) {
      return 'To-Do';
    }
    if (lower.contains('schedule') || lower.contains('deadline') || lower.contains('milestone') ||
        lower.contains('phase') || lower.contains('due date')) {
      return 'Schedule';
    }
    if (lower.contains('budget') || lower.contains('\$') || lower.contains('cost') ||
        lower.contains('fee') || lower.contains('amount') || lower.contains('invoice')) {
      return 'Budget';
    }
    if (lower.contains('contract') || lower.contains('agreement') || lower.contains('amendment') ||
        lower.contains('scope') || lower.contains('proposal')) {
      return 'Contract';
    }
    if (lower.contains('rfi') || lower.contains('request for information') ||
        lower.contains('question') || lower.contains('clarification')) {
      return 'RFI';
    }
    if (lower.contains('@') || lower.contains('email') || lower.contains('phone') ||
        lower.contains('team') || lower.contains('contact')) {
      return 'Team Member';
    }
    return 'Project Info';
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty && _droppedFiles.isEmpty) return;

    final target = _selectedTarget == 'Auto-detect' ? _autoDetect(text) : _selectedTarget;

    switch (target) {
      case 'To-Do':
        ref.read(todosProvider.notifier).add(text);
        _showSuccess('Added to To-Do list');
      case 'Team Member':
        // Parse name from text
        ref.read(projectInfoProvider.notifier).upsertByLabel(
          'Contacts', 'Team Note', text, source: 'manual', confidence: 1.0,
        );
        _showSuccess('Added to Project Info > Contacts');
      case 'Schedule':
        ref.read(projectInfoProvider.notifier).upsertByLabel(
          'General', 'Schedule Note', text, source: 'manual', confidence: 1.0,
        );
        _showSuccess('Added schedule note to Project Info');
      case 'Budget':
        ref.read(projectInfoProvider.notifier).upsertByLabel(
          'General', 'Budget Note', text, source: 'manual', confidence: 1.0,
        );
        _showSuccess('Added budget note to Project Info');
      case 'Contract':
        ref.read(projectInfoProvider.notifier).upsertByLabel(
          'General', 'Contract Note', text, source: 'manual', confidence: 1.0,
        );
        _showSuccess('Added contract note to Project Info');
      case 'RFI':
        final number = ref.read(rfisProvider.notifier).nextNumber();
        ref.read(rfisProvider.notifier).add(RfiItem(
          id: 'rfi_${DateTime.now().millisecondsSinceEpoch}',
          number: number,
          subject: text,
          status: 'Open',
          dateOpened: DateTime.now(),
        ));
        _showSuccess('Created $number');
      default:
        // Project Info — try to parse key:value format
        if (text.contains(':')) {
          final parts = text.split(':');
          final label = parts.first.trim();
          final value = parts.sublist(1).join(':').trim();
          ref.read(projectInfoProvider.notifier).upsertByLabel(
            'General', label, value, source: 'manual', confidence: 1.0,
          );
          _showSuccess('Added "$label" to Project Info');
        } else {
          ref.read(projectInfoProvider.notifier).upsertByLabel(
            'General', 'Note', text, source: 'manual', confidence: 1.0,
          );
          _showSuccess('Added note to Project Info');
        }
    }

    // Handle dropped files — copy to appropriate project folder
    for (final path in _droppedFiles) {
      final fileName = path.split(RegExp(r'[/\\]')).last;
      ref.read(projectInfoProvider.notifier).upsertByLabel(
        'General', 'Attached File', fileName, source: 'manual', confidence: 1.0,
      );
    }

    _textController.clear();
    setState(() => _droppedFiles.clear());
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Tokens.chipGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() {
          _isDragging = false;
          for (final file in details.files) {
            _droppedFiles.add(file.path);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isDragging
              ? Tokens.accent.withValues(alpha: 0.08)
              : Tokens.bgMid.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: _isDragging ? Tokens.accent : Tokens.glassBorder,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            // Target selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Tokens.glassFill,
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
                border: Border.all(color: Tokens.glassBorder),
              ),
              child: DropdownButton<String>(
                value: _selectedTarget,
                dropdownColor: Tokens.bgMid,
                isDense: true,
                underline: const SizedBox.shrink(),
                style: AppTheme.body.copyWith(fontSize: 11),
                icon: const Icon(Icons.arrow_drop_down, size: 16, color: Tokens.textMuted),
                items: _targets.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: AppTheme.body.copyWith(fontSize: 11)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedTarget = v ?? 'Auto-detect'),
              ),
            ),
            const SizedBox(width: 10),
            // Text input
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _textController,
                  style: AppTheme.body.copyWith(fontSize: 12),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: _isDragging
                        ? 'Drop files here...'
                        : 'Type info, paste email content, or drag files here...',
                    hintStyle: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: _isDragging ? Tokens.accent : Tokens.textMuted,
                    ),
                    filled: true,
                    fillColor: Tokens.glassFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      borderSide: BorderSide(
                        color: _isDragging ? Tokens.accent : Tokens.glassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      borderSide: BorderSide(
                        color: _isDragging ? Tokens.accent : Tokens.glassBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusSm),
                      borderSide: const BorderSide(color: Tokens.accent),
                    ),
                    suffixIcon: _droppedFiles.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Tokens.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${_droppedFiles.length} file${_droppedFiles.length == 1 ? '' : 's'}',
                                    style: AppTheme.caption.copyWith(fontSize: 9, color: Tokens.accent),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() => _droppedFiles.clear()),
                                  child: const Icon(Icons.close, size: 14, color: Tokens.textMuted),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Submit button
            InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Tokens.accent,
                  borderRadius: BorderRadius.circular(Tokens.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send, size: 14, color: Tokens.bgDark),
                    const SizedBox(width: 4),
                    Text('Add', style: AppTheme.body.copyWith(
                      fontSize: 11, fontWeight: FontWeight.w600, color: Tokens.bgDark,
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
