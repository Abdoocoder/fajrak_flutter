import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum ProgressBarVariant { budget, goal, overspent }

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    required this.title,
    this.variant = ProgressBarVariant.budget,
    this.percentageLabel,
    this.infoStart,
    this.infoEnd,
    this.fillColor,
  });

  /// 0.0 → 1.0
  final double value;
  final String title;
  final ProgressBarVariant variant;
  final String? percentageLabel;
  final String? infoStart;
  final String? infoEnd;
  /// Optional override — skips variant colour logic when set.
  final Color? fillColor;

  Color _fillColor(bool isDark) {
    if (fillColor != null) return fillColor!;
    switch (variant) {
      case ProgressBarVariant.goal:
        return AppColors.income;
      case ProgressBarVariant.overspent:
        return AppColors.expense;
      case ProgressBarVariant.budget:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = value.clamp(0.0, 1.0);
    final pct = percentageLabel ?? '${(clamped * 100).round()}%';

    final trackColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final fillColor = _fillColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.labelMd.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: fillColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                pct,
                style: AppTypography.labelSm.copyWith(color: fillColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Track
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: trackColor),
                FractionallySizedBox(
                  widthFactor: clamped,
                  child: variant == ProgressBarVariant.budget
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                          ),
                        )
                      : Container(color: fillColor),
                ),
              ],
            ),
          ),
        ),
        // Info row
        if (infoStart != null || infoEnd != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (infoStart != null)
                Text(
                  infoStart!,
                  style: AppTypography.bodySm.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              if (infoEnd != null)
                Text(
                  infoEnd!,
                  style: AppTypography.bodySm.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
