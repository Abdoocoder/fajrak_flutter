import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../common/progress_bar.dart';

class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({
    super.key,
    required this.totalSaved,
    required this.totalTarget,
    required this.currency,
  });

  final double totalSaved;
  final double totalTarget;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: AppProgressBar(
        value: progress,
        title: 'goals_overall_progress'.tr(),
        variant: ProgressBarVariant.goal,
        infoEnd:
            '${totalSaved.toStringAsFixed(0)} / ${totalTarget.toStringAsFixed(0)} $currency',
      ),
    );
  }
}
