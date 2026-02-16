import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/project_providers.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesProvider);
    final totalSize = files.fold(0, (s, f) => s + f.sizeBytes);

    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROJECT FILES', style: AppTheme.heading),
              const Spacer(),
              Text('${files.length} files  •  ${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: SizedBox.shrink()),
                        Expanded(flex: 4, child: Text('NAME', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 2, child: Text('CATEGORY', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 1, child: Text('SIZE', style: AppTheme.sidebarGroupLabel)),
                        Expanded(flex: 2, child: Text('MODIFIED', style: AppTheme.sidebarGroupLabel)),
                      ],
                    ),
                  ),
                  const Divider(color: Tokens.glassBorder, height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: files.length,
                      separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1),
                      itemBuilder: (context, i) {
                        final f = files[i];
                        final isPdf = f.name.endsWith('.pdf');
                        final isImage = f.name.endsWith('.png') || f.name.endsWith('.jpg');
                        final icon = isPdf ? Icons.picture_as_pdf : isImage ? Icons.image_outlined : Icons.description_outlined;
                        final iconColor = isPdf ? Tokens.chipRed : isImage ? Tokens.chipBlue : Tokens.textSecondary;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(width: 30, child: Icon(icon, size: 18, color: iconColor)),
                              Expanded(flex: 4, child: Text(f.name, style: AppTheme.body.copyWith(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              Expanded(flex: 2, child: Text(f.category, style: AppTheme.caption.copyWith(fontSize: 11))),
                              Expanded(flex: 1, child: Text(f.sizeLabel, style: AppTheme.caption.copyWith(fontSize: 11))),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _fmtDate(f.modified),
                                  style: AppTheme.caption.copyWith(fontSize: 11),
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
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
