import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../models/project_models.dart';
import '../state/project_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 20, color: Tokens.textSecondary),
          onPressed: () => _showNotificationPanel(context),
          tooltip: 'Notifications',
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Tokens.chipRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationSheet(),
    );
  }
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityProvider);
    final notifier = ref.read(activityProvider.notifier);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.65,
      decoration: const BoxDecoration(
        color: Tokens.bgMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg)),
        border: Border(
          top: BorderSide(color: Tokens.glassBorder),
          left: BorderSide(color: Tokens.glassBorder),
          right: BorderSide(color: Tokens.glassBorder),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Tokens.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 20, color: Tokens.accent),
                const SizedBox(width: 8),
                Text('ACTIVITY FEED', style: AppTheme.sidebarGroupLabel.copyWith(color: Tokens.accent, letterSpacing: 1.2)),
                const Spacer(),
                TextButton(
                  onPressed: () => notifier.markAllRead(),
                  child: Text('Mark all read', style: AppTheme.caption.copyWith(fontSize: 11, color: Tokens.accent)),
                ),
              ],
            ),
          ),
          const Divider(color: Tokens.glassBorder, height: 1),
          // Activity list
          Expanded(
            child: activities.isEmpty
                ? Center(child: Text('No activity yet', style: AppTheme.caption))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const Divider(color: Tokens.glassBorder, height: 1, indent: 56),
                    itemBuilder: (_, i) {
                      final item = activities[i];
                      return _ActivityTile(
                        item: item,
                        onTap: () => notifier.markRead(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback onTap;
  const _ActivityTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(item.category);
    final color = _categoryColor(item.category);
    final timeAgo = _formatTimeAgo(item.timestamp);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? Colors.transparent : Tokens.accent.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTheme.body.copyWith(
                            fontSize: 12,
                            fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: Tokens.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTheme.caption.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(timeAgo, style: AppTheme.caption.copyWith(fontSize: 10, color: Tokens.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'rfi' => Icons.question_answer_outlined,
    'asi' => Icons.description_outlined,
    'schedule' => Icons.calendar_today_outlined,
    'budget' => Icons.attach_money,
    'document' => Icons.insert_drive_file_outlined,
    'team' => Icons.person_add_outlined,
    'todo' => Icons.check_circle_outline,
    _ => Icons.notifications_outlined,
  };

  Color _categoryColor(String cat) => switch (cat) {
    'rfi' => Tokens.chipBlue,
    'asi' => Tokens.chipYellow,
    'schedule' => Tokens.accent,
    'budget' => Tokens.chipRed,
    'document' => Tokens.chipGreen,
    'team' => const Color(0xFF7986CB),
    'todo' => Tokens.chipGreen,
    _ => Tokens.textSecondary,
  };

  String _formatTimeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${ts.month}/${ts.day}/${ts.year}';
  }
}
