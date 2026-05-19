import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur; // kept for API compatibility, no longer used
  final double opacity;
  final double borderRadius;
  final Color? borderColor;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool topBorderOnly;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.05,
    this.borderRadius = 20.0,
    this.borderColor,
    this.color,
    this.padding,
    this.topBorderOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final effectiveBorderColor = borderColor ?? border.withValues(alpha: 0.3);

    // BackdropFilter/blur removed — causes vertical-line rendering artifacts
    // on Android. Replaced with a solid semi-transparent surface.
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? surface).withValues(alpha: opacity + 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: topBorderOnly
            ? Border(top: BorderSide(color: effectiveBorderColor, width: 1))
            : Border.all(color: effectiveBorderColor, width: 1),
      ),
      child: child,
    );
  }
}
