import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../state/nav_state.dart';
import 'sidebar_item.dart';

class SidebarGroupWidget extends StatelessWidget {
  final SidebarGroup group;
  final bool isExpanded;
  final NavRoute selectedRoute;
  final VoidCallback onToggle;
  final void Function(NavRoute) onSelectItem;

  const SidebarGroupWidget({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.selectedRoute,
    required this.onToggle,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header (always visible)
        GestureDetector(
          onTap: onToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label,
                      style: AppTheme.sidebarGroupLabel,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: Tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Collapsible items
        AnimatedCrossFade(
          firstChild: Column(
            children: group.items
                .map((route) => SidebarItem(
                      label: route.label,
                      isActive: route == selectedRoute,
                      onTap: () => onSelectItem(route),
                    ))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
