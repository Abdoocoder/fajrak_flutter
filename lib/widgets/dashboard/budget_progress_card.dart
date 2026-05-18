import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/progress_bar.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.currency,
    this.onSeeAll,
  });

  final double income;
  final double expenses;
  final String currency;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    if (income == 0) {
      return AppCard(
        variant: AppCardVariant.tight,
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 24,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'dash_monthly_budget'.tr(),
              style: AppTypography.headingSm.copyWith(color: labelColor),
            ),
          ],
        ),
      );
    }

    final fraction = (expenses / income).clamp(0.0, 1.0);
    final remaining = income - expenses;
    final pct = (fraction * 100).round();
    final expFmt = expenses % 1 == 0
        ? expenses.toStringAsFixed(0)
        : expenses.toStringAsFixed(2);
    final incFmt = income % 1 == 0
        ? income.toStringAsFixed(0)
        : income.toStringAsFixed(2);
    final remFmt = remaining.abs() % 1 == 0
        ? remaining.abs().toStringAsFixed(0)
        : remaining.abs().toStringAsFixed(2);

    // Colour: <0.7 → budget gradient; 0.7–0.9 → warning amber; ≥0.9 → expense red
    ProgressBarVariant variant;
    Color? overrideColor;
    Color spentColor;
    if (fraction >= 0.9) {
      variant = ProgressBarVariant.overspent;
      spentColor = AppColors.expense;
    } else if (fraction >= 0.7) {
      variant = ProgressBarVariant.overspent;
      overrideColor = AppColors.warning;
      spentColor = AppColors.warning;
    } else {
      variant = ProgressBarVariant.budget;
      spentColor = AppColors.primary;
    }

    return AppCard(
      variant: AppCardVariant.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dash_monthly_budget'.tr(),
                style: AppTypography.headingSm.copyWith(color: labelColor),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '${'dash_view_all'.tr()} ←',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                expFmt,
                style: AppTypography.headingMd.copyWith(
                  color: spentColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ' / $incFmt $currency',
                style: AppTypography.bodySm.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: fraction,
            title: '',
            variant: variant,
            fillColor: overrideColor,
            trackHeight: 10,
            percentageLabel: '$pct%',
            infoEnd: remaining >= 0
                ? '$remFmt $currency ${'goals_remaining'.tr()}'
                : null,
          ),
        ],
      ),
    );
  }
}
