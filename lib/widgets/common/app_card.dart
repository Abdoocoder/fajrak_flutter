import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppCardVariant { standard, tight, lesson }

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.onTap,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: _easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLesson = widget.variant == AppCardVariant.lesson;

    final bg = widget.backgroundColor ??
        (isLesson
            ? AppColors.lessonBackground
            : isDark
                ? AppColors.surfaceDark
                : AppColors.surface);

    final border = widget.borderColor ??
        (isLesson
            ? Colors.transparent
            : isDark
                ? AppColors.borderDark
                : AppColors.borderLight);

    final defaultPadding = widget.variant == AppCardVariant.tight
        ? const EdgeInsetsDirectional.all(AppSpacing.cardPaddingTight)
        : const EdgeInsetsDirectional.all(AppSpacing.cardPadding);

    Widget card = Container(
      margin: widget.margin,
      padding: widget.padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.circularLg,
        border: Border.all(color: border),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: card,
      ),
    );
  }
}
