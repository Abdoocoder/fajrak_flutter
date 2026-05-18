import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';

class BudgetRuleCard extends StatelessWidget {
  const BudgetRuleCard({
    super.key,
    required this.available,
    required this.currency,
    required this.onApply,
  });

  final double available;
  final String currency;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.balance, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'dash_rule_503020'.tr(),
                    style: AppTypography.labelMd.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  label: 'dash_rule_apply'.tr(),
                  variant: AppButtonVariant.small,
                  onPressed: onApply,
                  fullWidth: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _RuleItem(
                    pct: '50%',
                    label: 'dash_rule_necessities'.tr(),
                    amount: (available * 0.5).round().toDouble(),
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RuleItem(
                    pct: '30%',
                    label: 'dash_rule_wants'.tr(),
                    amount: (available * 0.3).round().toDouble(),
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RuleItem(
                    pct: '20%',
                    label: 'dash_rule_savings'.tr(),
                    amount: (available * 0.2).round().toDouble(),
                    color: AppColors.income,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.pct,
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  final String pct;
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            pct,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
          Text(
            amount.toStringAsFixed(0),
            style: AppTypography.labelSm.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
