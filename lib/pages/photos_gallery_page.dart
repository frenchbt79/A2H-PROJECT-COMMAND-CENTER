import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_file.dart';
import '../services/folder_scan_service.dart';
import '../state/folder_scan_providers.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/file_drop_target.dart';
import '../services/file_ops_service.dart';

class PhotosGalleryPage extends ConsumerWidget {
  const PhotosGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFiles = ref.watch(scannedPhotosProvider);

    return FileDropTarget(
      destinationRelativePath: r'0 Project Management\Photos',
      child: Padding(
        padding: const EdgeInsets.all(Tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF4FC3F7), size: 22),
                const SizedBox(width: 10),
                Text('PHOTOS', style: AppTheme.heading),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18,
                      color: Tokens.textMuted),
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.read(scanRefreshProvider.notifier).state++,
                ),
                asyncFiles.whenOrNull(
                  data: (files) {
                    final imageCount =
                        files.where((f) => f.isImage).length;
                    return _CountChip(count: imageCount);
                  },
                ) ??
                    const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              r'0 Project Management\Photos',
              style: AppTheme.caption
                  .copyWith(fontSize: 10, color: Tokens.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Tokens.spaceLg),
            Expanded(
              child: asyncFiles.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: Tokens.accent)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 40, color: Tokens.chipRed),
                      const SizedBox(height: 12),
                      Text('Error scanning folder',
                          style: AppTheme.subheading),
                      const SizedBox(height: 4),
                      Text('$err',
                          style: AppTheme.caption,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                data: (files) {
                  final images =
                      files.where((f) => f.isImage).toList();
                  if (images.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 48,
                              color: Tokens.textMuted
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No photos found',
                              style: AppTheme.subheading
                                  .copyWith(color: Tokens.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                              'Place image files in the Photos folder to see them here',
                              style: AppTheme.caption),
                        ],
                      ),
                    );
                  }
                  return LayoutBuilder(builder: (context, constraints) {
                    final crossCount = constraints.maxWidth > 1100
                        ? 5
                        : constraints.maxWidth > 800
                            ? 4
                            : constraints.maxWidth > 550
                                ? 3
                                : 2;
                    return GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, i) =>
                          RepaintBoundary(
                            child: _PhotoCard(file: images[i], ref: ref),
                          ),
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

class _PhotoCard extends StatelessWidget {
  final ScannedFile file;
  final WidgetRef ref;
  const _PhotoCard({required this.file, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) =>
          showFileContextMenu(context, ref, details.globalPosition, file.fullPath, openLabel: 'Open Photo'),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => FolderScanService.openFile(file.fullPath),
          borderRadius: BorderRadius.circular(Tokens.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Tokens.radiusLg)),
                  child: _buildThumbnail(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style:
                          AppTheme.body.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${file.sizeLabel}  ·  ${_fmtDate(file.modified)}',
                      style: AppTheme.caption
                          .copyWith(fontSize: 9, color: Tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (!kIsWeb) {
      return Image.file(
        File(file.fullPath),
        fit: BoxFit.cover,
        cacheWidth: 400,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
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
            Icon(Icons.image_outlined,
                size: 36, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text(
              file.extension.toUpperCase().replaceFirst('.', ''),
              style: AppTheme.caption.copyWith(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        border:
            Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: AppTheme.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4FC3F7))),
          const SizedBox(width: 4),
          Text('photos',
              style: AppTheme.caption
                  .copyWith(fontSize: 10, color: const Color(0xFF4FC3F7))),
        ],
      ),
    );
  }
}
