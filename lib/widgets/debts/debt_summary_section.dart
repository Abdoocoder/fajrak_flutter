import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class DebtSummarySection extends StatelessWidget {
  final double totalRemaining;
  final double totalOriginal;
  final double totalMonthly;
  final String currency;
  final double lifeTimePaid;
  final int paidCount;

  const DebtSummarySection({
    super.key,
    required this.totalRemaining,
    required this.totalOriginal,
    required this.totalMonthly,
    required this.currency,
    required this.lifeTimePaid,
    required this.paidCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final paidPct = totalOriginal > 0
        ? ((totalOriginal - totalRemaining) / totalOriginal * 100)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'debts_total_remaining'.tr(),
                '${totalRemaining.toStringAsFixed(0)} $currency',
                AppColors.expense,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'debts_paid'.tr(),
                '${paidPct.toStringAsFixed(0)}%',
                AppColors.income,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'debts_monthly_total'.tr(),
                '${totalMonthly.toStringAsFixed(0)} $currency',
                AppColors.warning,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (lifeTimePaid > 0)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsetsDirectional.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 28, color: AppColors.income),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'debts_total_paid_life'.tr(),
                      style: AppTypography.labelSm.copyWith(color: textSecondary),
                    ),
                    Text(
                      '${lifeTimePaid.toStringAsFixed(0)} $currency',
                      style: AppTypography.headingMd.copyWith(color: AppColors.income),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'debts_paid_count'.tr(),
                      style: AppTypography.labelSm.copyWith(color: textSecondary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$paidCount ',
                          style: AppTypography.headingSm.copyWith(color: AppColors.income),
                        ),
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.income,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsetsDirectional.only(bottom: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'debts_overall_progress'.tr(),
                    style: AppTypography.labelSm.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${paidPct.toStringAsFixed(1)}%',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppProgressBar(
                value: (paidPct / 100).clamp(0.0, 1.0),
                title: '',
                percentageLabel: '${paidPct.toStringAsFixed(0)}%',
                variant: ProgressBarVariant.goal,
                infoStart: 'debts_paid_amount'.tr(
                  args: [(totalOriginal - totalRemaining).toStringAsFixed(0), currency],
                ),
                infoEnd: 'debts_original_amount_label'.tr(
                  args: [totalOriginal.toStringAsFixed(0), currency],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
