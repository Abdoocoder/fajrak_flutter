import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.subLabel,
    this.fillColor,
    this.size = 120,
    this.strokeWidth = 10,
  });

  /// 0.0 – 1.0. Clamped internally.
  final double value;

  /// Center text — e.g. "68%"
  final String label;

  /// Optional sub-label below center — e.g. "مستخدمة / Used"
  final String? subLabel;

  /// Override fill color. null → primary→accent gradient.
  final Color? fillColor;

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              value: value.clamp(0.0, 1.0),
              trackColor: trackColor,
              fillColor: fillColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.displaySmall.copyWith(
                  color: textPrimary,
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  subLabel!,
                  style: AppTypography.labelSm.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.trackColor,
    this.fillColor,
    required this.strokeWidth,
  });

  final double value;
  final Color trackColor;
  final Color? fillColor;
  final double strokeWidth;

  static const _startAngle = -math.pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track — full circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (value <= 0) return;

    final sweepAngle = value * 2 * math.pi;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (fillColor != null) {
      fillPaint.color = fillColor!;
    } else {
      fillPaint.shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + sweepAngle,
        colors: const [AppColors.primary, AppColors.accent],
      ).createShader(rect);
    }

    canvas.drawArc(rect, _startAngle, sweepAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}
