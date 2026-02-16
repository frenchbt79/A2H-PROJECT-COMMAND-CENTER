import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class SidebarItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  const SidebarItem({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Tokens.sidebarActive
                : _hovering
                    ? Tokens.glassFill
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Tokens.radiusSm),
          ),
          child: Row(
            children: [
              // Left accent bar for active
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: widget.isActive ? Tokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive ? Tokens.accent : Tokens.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTheme.body.copyWith(
                    fontSize: 13,
                    color: widget.isActive ? Tokens.textPrimary : Tokens.textSecondary,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
