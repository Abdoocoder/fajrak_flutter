import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/progress_ring.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.currency,
    this.categoryBreakdown,
    this.onSeeAll,
  });

  final double income;
  final double expenses;
  final String currency;
  /// Top-2 expense categories: [{'category': 'طعام', 'amount': 150.0}, ...]
  final List<Map<String, dynamic>>? categoryBreakdown;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final dividerColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    // Empty state — no income data yet
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
    final pct = (fraction * 100).round();

    // Ring fill: gradient (null) / warning / overspent
    Color? ringFillColor;
    if (fraction >= 0.9) {
      ringFillColor = AppColors.expense;
    } else if (fraction >= 0.7) {
      ringFillColor = AppColors.warning;
    }

    return AppCard(
      variant: AppCardVariant.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
          const SizedBox(height: AppSpacing.md),

          // ProgressRing — centered hero
          // Expense arc: orange/red based on threshold
          // Remaining arc: income green — shows leftover at a glance
          Center(
            child: ProgressRing(
              value: fraction,
              label: '$pct%',
              subLabel: 'budget_used'.tr(),
              fillColor: ringFillColor,
              remainingColor: AppColors.income.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Income row
          _StatRow(
            isIncome: true,
            label: 'trans_income'.tr(),
            amount: income,
            currency: currency,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: AppSpacing.xs),

          // Expense row
          _StatRow(
            isIncome: false,
            label: 'trans_expense'.tr(),
            amount: expenses,
            currency: currency,
            isDark: isDark,
          ),

          // Category breakdown — top 2 expense categories
          if (categoryBreakdown != null && categoryBreakdown!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: AppSpacing.sm),
            ...categoryBreakdown!.take(2).map(
              (c) => _CategoryRow(
                category: c['category'] as String,
                amount: (c['amount'] as num).toDouble(),
                totalExpenses: expenses,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.totalExpenses,
    required this.currency,
    required this.isDark,
  });

  final String category;
  final double amount;
  final double totalExpenses;
  final String currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final trackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final pct =
        totalExpenses > 0 ? (amount / totalExpenses).clamp(0.0, 1.0) : 0.0;
    final n = amount.abs();
    final formatted =
        n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category,
                style: AppTypography.labelSm.copyWith(color: labelColor),
              ),
              const Spacer(),
              Text(
                '$formatted $currency',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: trackColor),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      color: AppColors.expense.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.isIncome,
    required this.label,
    required this.amount,
    required this.currency,
    required this.isDark,
  });

  final bool isIncome;
  final String label;
  final double amount;
  final String currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final n = amount.abs();
    final formatted =
        n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            size: 11,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(color: labelColor),
        ),
        const Spacer(),
        Text(
          '$formatted $currency',
          style: AppTypography.headingSm.copyWith(
            color: color,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
