import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(Tokens.radiusLg);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: Tokens.glassBlur, sigmaY: Tokens.glassBlur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Tokens.glassFill,
            borderRadius: radius,
            border: Border.all(color: Tokens.glassBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(Tokens.spaceMd),
          child: child,
        ),
      ),
    );
  }
}
