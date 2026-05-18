import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.income,
    required this.totalDebtPayments,
    required this.available,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.currency,
  });

  final double income;
  final double totalDebtPayments;
  final double available;
  final double totalBudgeted;
  final double totalSpent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dash_summary_month'.tr(),
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            label: 'dash_income'.tr(),
            value: '+${income.toStringAsFixed(0)} $currency',
            valueColor: AppColors.income,
            isDark: isDark,
          ),
          if (totalDebtPayments > 0)
            _SummaryRow(
              label: 'dash_debts_payment'.tr(),
              value: '-${totalDebtPayments.toStringAsFixed(0)} $currency',
              valueColor: AppColors.expense,
              isDark: isDark,
            ),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dash_available_spending'.tr(),
                style: AppTypography.headingSm.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${available.toStringAsFixed(0)} $currency',
                style: AppTypography.headingMd.copyWith(
                  color: available >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          if (totalBudgeted > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            AppProgressBar(
              value: totalBudgeted > 0
                  ? (totalSpent / totalBudgeted).clamp(0.0, 1.0)
                  : 0,
              title: 'dash_spent_from_categories'.tr(),
              variant: totalSpent > totalBudgeted
                  ? ProgressBarVariant.overspent
                  : ProgressBarVariant.budget,
              infoEnd:
                  '${totalSpent.toStringAsFixed(0)} / ${totalBudgeted.toStringAsFixed(0)} $currency',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMd.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
