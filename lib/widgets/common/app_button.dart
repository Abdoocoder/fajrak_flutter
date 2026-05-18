import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, accent, danger, small }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
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

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  _ButtonConfig get _config {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonConfig(
          bg: AppColors.primary,
          fg: AppColors.textInverse,
          border: Colors.transparent,
          height: AppSpacing.buttonHeight,
          radius: AppRadius.md,
          style: AppTypography.headingMd.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
          spinnerColor: AppColors.textInverse,
        );
      case AppButtonVariant.secondary:
        return _ButtonConfig(
          bg: Colors.transparent,
          fg: AppColors.primary,
          border: AppColors.primary,
          borderWidth: 1.5,
          height: AppSpacing.buttonHeight,
          radius: AppRadius.md,
          style: AppTypography.headingMd.copyWith(color: AppColors.primary),
          spinnerColor: AppColors.primary,
        );
      case AppButtonVariant.ghost:
        return _ButtonConfig(
          bg: Colors.transparent,
          fg: AppColors.textPrimary,
          border: Colors.transparent,
          height: 40,
          radius: AppRadius.md,
          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          spinnerColor: AppColors.primary,
        );
      case AppButtonVariant.accent:
        return _ButtonConfig(
          bg: AppColors.accent,
          fg: const Color(0xFF7A5800),
          border: Colors.transparent,
          height: 48,
          radius: AppRadius.full,
          style: AppTypography.labelLg.copyWith(
            color: const Color(0xFF7A5800),
            fontWeight: FontWeight.w600,
          ),
          spinnerColor: const Color(0xFF7A5800),
        );
      case AppButtonVariant.danger:
        return _ButtonConfig(
          bg: Colors.transparent,
          fg: AppColors.expense,
          border: AppColors.expense,
          borderWidth: 1.5,
          height: AppSpacing.buttonHeight,
          radius: AppRadius.md,
          style: AppTypography.headingMd.copyWith(color: AppColors.expense),
          spinnerColor: AppColors.expense,
        );
      case AppButtonVariant.small:
        return _ButtonConfig(
          bg: AppColors.primary,
          fg: AppColors.textInverse,
          border: Colors.transparent,
          height: 32,
          radius: AppRadius.sm,
          style: AppTypography.labelSm.copyWith(color: AppColors.textInverse),
          spinnerColor: AppColors.textInverse,
          horizontalPadding: 12,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null && !widget.isLoading) ...[
          widget.icon!,
          const SizedBox(width: AppSpacing.xs),
        ],
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(cfg.spinnerColor),
            ),
          )
        else
          ImageFiltered(
            imageFilter: widget.isLoading && !disableAnimations
                ? ImageFilter.blur(sigmaX: 2, sigmaY: 2)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Opacity(
              opacity: widget.isLoading ? 0.7 : 1.0,
              child: Text(widget.label, style: cfg.style),
            ),
          ),
      ],
    );

    Widget button = AnimatedOpacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: disableAnimations ? 1.0 : _scale.value,
            child: child,
          ),
          child: Container(
            height: cfg.height,
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: cfg.horizontalPadding ?? AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: cfg.bg,
              borderRadius: BorderRadius.circular(cfg.radius),
              border: cfg.border == Colors.transparent
                  ? null
                  : Border.all(color: cfg.border, width: cfg.borderWidth),
            ),
            child: content,
          ),
        ),
      ),
    );

    return button;
  }
}

class _ButtonConfig {
  final Color bg;
  final Color fg;
  final Color border;
  final double borderWidth;
  final double height;
  final double radius;
  final TextStyle style;
  final Color spinnerColor;
  final double? horizontalPadding;

  const _ButtonConfig({
    required this.bg,
    required this.fg,
    required this.border,
    required this.height,
    required this.radius,
    required this.style,
    required this.spinnerColor,
    this.borderWidth = 1.0,
    this.horizontalPadding,
  });
}
