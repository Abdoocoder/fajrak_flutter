import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double totalCost;
  final bool showInUsd;
  final double jodRate;
  final int assetsCount;
  final int halalCount;

  const PortfolioSummaryCard({
    super.key,
    required this.totalValue,
    required this.totalCost,
    required this.showInUsd,
    required this.jodRate,
    required this.assetsCount,
    required this.halalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final gain = totalValue - totalCost;
    final gainPct = totalCost > 0 ? (gain / totalCost * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.15),
        ]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'inv_total_value'.tr(),
            style: AppTypography.labelMd.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            showInUsd
                ? '\$${totalValue.toStringAsFixed(2)}'
                : '${(totalValue * jodRate).toStringAsFixed(2)} JOD',
            style: AppTypography.displaySmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gain >= 0 ? Icons.trending_up : Icons.trending_down,
                color: gain >= 0 ? AppColors.income : AppColors.expense,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${gain >= 0 ? '+' : ''}\$${gain.toStringAsFixed(2)} (${gainPct.toStringAsFixed(1)}%)',
                style: AppTypography.labelMd.copyWith(
                  color: gain >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('inv_cost'.tr(), '\$${totalCost.toStringAsFixed(0)}', textSecondary),
              _miniStat('inv_assets'.tr(), '$assetsCount', AppColors.primary),
              _miniStat('inv_halal'.tr(), '$halalCount', AppColors.income),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.headingSm.copyWith(color: color)),
        Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
