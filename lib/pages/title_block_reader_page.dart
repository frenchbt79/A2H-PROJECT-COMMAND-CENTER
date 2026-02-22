import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/ai_service.dart';
import '../services/ai_title_block_reader.dart';
import '../state/ai_providers.dart';
import '../state/folder_scan_providers.dart';

class TitleBlockReaderPage extends ConsumerStatefulWidget {
  const TitleBlockReaderPage({super.key});
  @override
  ConsumerState<TitleBlockReaderPage> createState() => _TitleBlockReaderPageState();
}

class _TitleBlockReaderPageState extends ConsumerState<TitleBlockReaderPage> {
  List<TitleBlockResult> _results = [];
  bool _scanning = false;
  int _completed = 0;
  int _total = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(aiHasKeyProvider);
    final enabled = ref.watch(aiEnabledProvider);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.document_scanner_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('AI TITLE BLOCK READER', style: AppTheme.heading),
              const Spacer(),
              if (_scanning)
                Text('$_completed / $_total', style: AppTheme.body.copyWith(
                  color: Tokens.accent, fontSize: 13)),
              const SizedBox(width: 12),
              _buildScanButton(hasKey, enabled),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Reads title blocks from drawing PDFs using AI vision. '
            'Extracts sheet numbers, project info, revisions, and validates against filenames.',
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: Tokens.spaceLg),

          // Status / No key warning
          if (!hasKey)
            _buildWarningCard(
              icon: Icons.key_off,
              title: 'No API Key',
              message: 'Go to Settings → AI Integration and add your Anthropic API key to use this feature.',
            )
          else if (!enabled)
            _buildWarningCard(
              icon: Icons.block,
              title: 'AI Disabled',
              message: 'AI features are turned off. Enable them in Settings → AI Integration.',
            )
          else if (_error != null)
            _buildWarningCard(
              icon: Icons.error_outline,
              title: 'Error',
              message: _error!,
              isError: true,
            ),

          // Progress bar
          if (_scanning) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _total > 0 ? _completed / _total : null,
                backgroundColor: Tokens.bgDark,
                valueColor: const AlwaysStoppedAnimation(Tokens.accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSummaryBar(),
            const SizedBox(height: 12),
            Expanded(child: _buildResultsList()),
          ] else if (!_scanning && hasKey && enabled)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined, size: 48, color: Tokens.textMuted.withAlpha(80)),
                    const SizedBox(height: 12),
                    Text('Click "Scan Drawings" to analyze title blocks',
                        style: AppTheme.caption.copyWith(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Scans PDF files from the current project\'s drawing folders',
                        style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanButton(bool hasKey, bool enabled) {
    return Material(
      color: hasKey && enabled && !_scanning ? Tokens.accent : Tokens.textMuted,
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      child: InkWell(
        onTap: hasKey && enabled && !_scanning ? _startScan : null,
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_scanning ? Icons.hourglass_top : Icons.play_arrow,
                  size: 16, color: Tokens.bgDark),
              const SizedBox(width: 6),
              Text(
                _scanning ? 'Scanning...' : 'Scan Drawings',
                style: AppTheme.body.copyWith(
                  fontSize: 12, color: Tokens.bgDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard({
    required IconData icon,
    required String title,
    required String message,
    bool isError = false,
  }) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, size: 24, color: isError ? Tokens.chipRed : Tokens.chipYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body.copyWith(
                    fontSize: 13, color: isError ? Tokens.chipRed : Tokens.chipYellow)),
                Text(message, style: AppTheme.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final total = _results.length;
    final success = _results.where((r) => r.isSuccess).length;
    final errors = _results.where((r) => r.isError).length;
    final mismatches = _results
        .where((r) => r.isSuccess)
        .where((r) {
          final fn = r.path.split(Platform.pathSeparator).last;
          return r.data!.validateFilename(fn.replaceAll('.pdf', '').replaceAll('.PDF', '')) != null;
        }).length;

    return Row(
      children: [
        _SummaryChip(label: '$total scanned', color: Tokens.textSecondary),
        const SizedBox(width: 8),
        _SummaryChip(label: '$success extracted', color: Tokens.chipGreen),
        if (mismatches > 0) ...[
          const SizedBox(width: 8),
          _SummaryChip(label: '$mismatches mismatches', color: Tokens.chipYellow),
        ],
        if (errors > 0) ...[
          const SizedBox(width: 8),
          _SummaryChip(label: '$errors failed', color: Tokens.chipRed),
        ],
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = _results[i];
        final fn = r.path.split(Platform.pathSeparator).last;

        if (r.isError) {
          return GlassCard(
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: Tokens.chipRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fn, style: AppTheme.body.copyWith(fontSize: 12)),
                      Text(r.error!, style: AppTheme.caption.copyWith(
                          fontSize: 10, color: Tokens.chipRed)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final d = r.data!;
        final filenameMismatch = d.validateFilename(
            fn.replaceAll('.pdf', '').replaceAll('.PDF', ''));

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: sheet number + title + confidence
              Row(
                children: [
                  // Discipline badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _disciplineColor(d.discipline).withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _disciplineColor(d.discipline).withAlpha(80)),
                    ),
                    child: Text(
                      d.sheetNumber ?? '???',
                      style: AppTheme.body.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: _disciplineColor(d.discipline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.sheetTitle ?? fn,
                      style: AppTheme.body.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Confidence indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _confidenceColor(d.confidence).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(d.confidence * 100).toInt()}%',
                      style: AppTheme.caption.copyWith(
                        fontSize: 10, color: _confidenceColor(d.confidence)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Detail rows
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (d.projectNumber != null)
                    _DetailChip(label: 'Project', value: d.projectNumber!),
                  if (d.discipline != null)
                    _DetailChip(label: 'Discipline', value: d.discipline!),
                  if (d.revisionNumber != null)
                    _DetailChip(label: 'Rev', value: d.revisionNumber!),
                  if (d.revisionDate != null)
                    _DetailChip(label: 'Rev Date',
                        value: '${d.revisionDate!.month}/${d.revisionDate!.day}/${d.revisionDate!.year}'),
                  if (d.drawnBy != null)
                    _DetailChip(label: 'Drawn', value: d.drawnBy!),
                  if (d.checkedBy != null)
                    _DetailChip(label: 'Checked', value: d.checkedBy!),
                  if (d.scale != null)
                    _DetailChip(label: 'Scale', value: d.scale!),
                  if (d.phase != null)
                    _DetailChip(label: 'Phase', value: d.phase!),
                  if (d.sealPresent)
                    _DetailChip(label: 'Seal', value: '✓', color: Tokens.chipGreen),
                ],
              ),

              // Filename mismatch warning
              if (filenameMismatch != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Tokens.chipYellow.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Tokens.chipYellow.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 14, color: Tokens.chipYellow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(filenameMismatch,
                          style: AppTheme.caption.copyWith(
                              fontSize: 10, color: Tokens.chipYellow)),
                      ),
                    ],
                  ),
                ),
              ],

              // Source file
              const SizedBox(height: 6),
              Text(fn, style: AppTheme.caption.copyWith(
                  fontSize: 9, color: Tokens.textMuted)),
            ],
          ),
        );
      },
    );
  }

  // ── Scan Logic ──────────────────────────────────────

  Future<void> _startScan() async {
    final projectPath = ref.read(projectPathProvider);
    if (projectPath.isEmpty) {
      setState(() => _error = 'No project path set. Add a project first.');
      return;
    }

    // Find all PDFs in discipline drawing folders
    final pdfPaths = <String>[];
    final dir = Directory(projectPath);
    if (!await dir.exists()) {
      setState(() => _error = 'Project folder not found: $projectPath');
      return;
    }

    // Walk the project folder looking for PDFs (max 2 levels deep)
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
        // Skip huge files and non-drawing PDFs
        final stat = await entity.stat();
        if (stat.size > 25 * 1024 * 1024) continue; // >25MB skip
        if (stat.size < 10 * 1024) continue; // <10KB skip (too small for drawing)

        final name = entity.path.split(Platform.pathSeparator).last.toUpperCase();
        // Only process files that look like drawings (sheet-number pattern)
        if (_looksLikeDrawing(name)) {
          pdfPaths.add(entity.path);
        }
      }
    }

    if (pdfPaths.isEmpty) {
      setState(() => _error = 'No drawing PDFs found in project folder.');
      return;
    }

    // Limit to first 20 for cost/time control
    final toScan = pdfPaths.take(20).toList();

    setState(() {
      _scanning = true;
      _error = null;
      _results = [];
      _completed = 0;
      _total = toScan.length;
    });

    final ai = ref.read(aiServiceProvider);
    final reader = TitleBlockReader(ai);

    final results = await reader.readMultiple(
      toScan,
      onProgress: (completed, total) {
        if (mounted) setState(() => _completed = completed);
      },
    );

    if (mounted) {
      setState(() {
        _scanning = false;
        _results = results;
      });
    }
  }

  /// Quick heuristic: does this filename look like a construction drawing?
  bool _looksLikeDrawing(String name) {
    // Match patterns like A1.01, S2.03, M1.01, G0.01, etc.
    final drawingPattern = RegExp(
      r'^[GACSMLPEF][EDIPRK]?\d',
      caseSensitive: false,
    );
    return drawingPattern.hasMatch(name);
  }

  Color _disciplineColor(String? discipline) {
    switch (discipline?.toLowerCase()) {
      case 'general': return Tokens.textSecondary;
      case 'architectural': return Tokens.accent;
      case 'structural': return Tokens.chipGreen;
      case 'civil': return Tokens.chipBlue;
      case 'landscape': return const Color(0xFF81C784);
      case 'mechanical': return Tokens.chipOrange;
      case 'electrical': return Tokens.chipYellow;
      case 'plumbing': return Tokens.chipIndigo;
      case 'fire protection': return Tokens.chipRed;
      default: return Tokens.textMuted;
    }
  }

  Color _confidenceColor(double conf) {
    if (conf >= 0.9) return Tokens.chipGreen;
    if (conf >= 0.7) return Tokens.chipYellow;
    return Tokens.chipRed;
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label, style: AppTheme.caption.copyWith(fontSize: 11, color: color)),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DetailChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
        Text(value, style: AppTheme.body.copyWith(fontSize: 11, color: color ?? Tokens.textPrimary)),
      ],
    );
  }
}
