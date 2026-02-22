import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/file_drop_target.dart';
import '../services/file_ops_service.dart';

class RenderingsPage extends ConsumerWidget {
  const RenderingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFiles = ref.watch(scannedRenderingsProvider);

    return FileDropTarget(
      destinationRelativePath: r'0 Project Management\Construction Documents\Scanned Drawings',
      child: Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.panorama_outlined, color: Tokens.accent, size: 22),
              const SizedBox(width: 10),
              Text('RENDERINGS', style: AppTheme.heading),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Tokens.textMuted),
                tooltip: 'Refresh',
                onPressed: () => ref.read(scanRefreshProvider.notifier).state++,
              ),
              asyncFiles.whenOrNull(
                data: (files) => Text(
                  '${files.length} files',
                  style: AppTheme.caption,
                ),
              ) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Files with "view" or "render" in name',
            style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted),
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: asyncFiles.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Tokens.accent)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Tokens.chipRed),
                    const SizedBox(height: 12),
                    Text('Error: $err', style: AppTheme.caption),
                  ],
                ),
              ),
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.panorama_outlined, size: 48, color: Tokens.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No renderings found', style: AppTheme.subheading.copyWith(color: Tokens.textMuted)),
                        const SizedBox(height: 4),
                        Text('Place files with "view" or "render" in the Scanned Drawings folder', style: AppTheme.caption),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 550 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: files.length,
                    itemBuilder: (context, i) => _RenderingCard(file: files[i], ref: ref),
                  );
                });
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _RenderingCard extends StatelessWidget {
  final ScannedFile file;
  final WidgetRef ref;
  const _RenderingCard({required this.file, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) => showFileContextMenu(context, ref, details.globalPosition, file.fullPath),
      onDoubleTap: () => FolderScanService.openFile(file.fullPath),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => FolderScanService.openFile(file.fullPath),
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview or placeholder
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg)),
                  child: _buildPreview(),
                ),
              ),
              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(file.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 10)),
                          const Spacer(),
                          Text(_fmtDate(file.modified), style: AppTheme.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (kIsWeb) return _placeholder();

    if (file.isImage) {
      return Image.file(
        File(file.fullPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (file.isPdf) {
      return _PdfThumbnail(filePath: file.fullPath);
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2A3A5C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file.isImage ? Icons.image_outlined : Icons.panorama_outlined,
              size: 36,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              file.extension.toUpperCase().replaceFirst('.', ''),
              style: AppTheme.caption.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// Renders the first page of a PDF file as a thumbnail preview.
class _PdfThumbnail extends StatelessWidget {
  final String filePath;
  const _PdfThumbnail({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.file(
      filePath,
      builder: (context, document) {
        if (document == null) {
          return Container(
            color: const Color(0xFF2A3A5C),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Tokens.accent),
              ),
            ),
          );
        }
        return Container(
          color: Colors.white,
          child: PdfPageView(
            document: document,
            pageNumber: 1,
            maximumDpi: 150,
          ),
        );
      },
    );
  }
}
