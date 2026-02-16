import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTheme.heading),
          const SizedBox(height: Tokens.spaceLg),
          Expanded(
            child: Center(
              child: GlassCard(
                padding: const EdgeInsets.all(Tokens.spaceXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 48,
                      color: Tokens.textMuted,
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    Text(
                      title,
                      style: AppTheme.subheading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                    Text(
                      'This section is under development.',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
