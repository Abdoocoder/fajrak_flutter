import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class GoalSummaryCards extends StatelessWidget {
  const GoalSummaryCards({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalSaved,
    required this.currency,
  });

  final int totalGoals;
  final int completedGoals;
  final double totalSaved;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark,
            Icons.track_changes,
            '$totalGoals',
            'goals_count_label'.tr(),
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            isDark,
            Icons.check_circle_outline,
            '$completedGoals',
            'goals_completed_label'.tr(),
            AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            isDark,
            Icons.account_balance_wallet,
            totalSaved.toStringAsFixed(0),
            'goals_saved_label'.tr(),
            AppColors.income,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
