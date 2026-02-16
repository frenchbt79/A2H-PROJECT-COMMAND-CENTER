import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';
import '../models/project_models.dart';

/// Serves 5 routes: Client Provided, Photos, Schematic Design,
/// Design Development, and Construction Documents.
class DocumentRegistryPage extends ConsumerWidget {
  final String title;
  final String? filterPhase; // 'SD', 'DD', 'CD'
  final String? filterSource; // 'Client'
  final bool photosMode;

  const DocumentRegistryPage({
    super.key,
    required this.title,
    this.filterPhase,
    this.filterSource,
    this.photosMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDocs = ref.watch(phaseDocumentsProvider);
    final docs = _filter(allDocs);
    final totalSize = docs.fold(0, (s, d) => s + d.sizeBytes);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Icon(
                photosMode ? Icons.photo_library_outlined : Icons.folder_outlined,
                color: Tokens.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title.toUpperCase(), style: AppTheme.heading, overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${docs.length} ${photosMode ? "photos" : "documents"}  •  ${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          // ── Body ──────────────────────────────────────────
          Expanded(
            child: photosMode ? _buildPhotoGrid(docs) : _buildDocTable(docs),
          ),
        ],
      ),
    );
  }

  List<PhaseDocument> _filter(List<PhaseDocument> all) {
    if (photosMode) {
      return all.where((d) => d.docType == 'Submittal' && _isImage(d.name)).toList();
    }
    if (filterSource != null) {
      return all.where((d) => d.source == filterSource).toList();
    }
    if (filterPhase != null) {
      return all.where((d) => d.phase == filterPhase).toList();
    }
    return all;
  }

  static bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  // ═════════════════════════════════════════════════════════
  // Photo Grid
  // ═════════════════════════════════════════════════════════
  Widget _buildPhotoGrid(List<PhaseDocument> docs) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 3
              : 2;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final doc = docs[i];
          return GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Tokens.bgMid,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg)),
                    ),
                    child: Center(
                      child: Icon(Icons.image_outlined, size: 40, color: Tokens.textMuted),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.sizeLabel}  •  ${_fmtDate(doc.modified)}',
                        style: AppTheme.caption.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ═════════════════════════════════════════════════════════
  // Document Table
  // ═════════════════════════════════════════════════════════
  Widget _buildDocTable(List<PhaseDocument> docs) {
    return GlassCard(
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(width: 30),
                Expanded(flex: 4, child: Text('NAME', style: AppTheme.sidebarGroupLabel)),
                Expanded(flex: 2, child: Text('TYPE', style: AppTheme.sidebarGroupLabel)),
                Expanded(flex: 2, child: Text('SOURCE', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 50, child: Text('REV', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 70, child: Text('SIZE', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 90, child: Text('MODIFIED', style: AppTheme.sidebarGroupLabel)),
                SizedBox(width: 80, child: Text('STATUS', style: AppTheme.sidebarGroupLabel)),
              ],
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 4),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
              itemBuilder: (context, i) {
                final d = docs[i];
                final icon = _iconForDocType(d.docType);
                final iconColor = _colorForDocType(d.docType);
                final statusColor = _statusColor(d.status);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Icon(icon, size: 18, color: iconColor)),
                      Expanded(
                        flex: 4,
                        child: Text(d.name, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(d.docType, style: AppTheme.caption.copyWith(fontSize: 11)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(d.source, style: AppTheme.caption.copyWith(fontSize: 11)),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          d.revision > 0 ? 'Rev ${d.revision}' : '—',
                          style: AppTheme.caption.copyWith(fontSize: 11),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(d.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 11)),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(_fmtDate(d.modified), style: AppTheme.caption.copyWith(fontSize: 10)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(Tokens.radiusSm),
                          ),
                          child: Text(
                            d.status,
                            style: AppTheme.caption.copyWith(fontSize: 10, color: statusColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForDocType(String type) {
    return switch (type) {
      'Drawing' => Icons.architecture,
      'Specification' => Icons.description_outlined,
      'Report' => Icons.article_outlined,
      'Submittal' => Icons.upload_file_outlined,
      'Correspondence' => Icons.mail_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  static Color _colorForDocType(String type) {
    return switch (type) {
      'Drawing' => Tokens.accent,
      'Specification' => Tokens.chipBlue,
      'Report' => Tokens.chipGreen,
      'Submittal' => Tokens.chipYellow,
      'Correspondence' => Tokens.textSecondary,
      _ => Tokens.textMuted,
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'Current' => Tokens.chipGreen,
      'Under Review' => Tokens.chipYellow,
      'Draft' => Tokens.chipBlue,
      'Superseded' => Tokens.chipRed,
      _ => Tokens.textSecondary,
    };
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
