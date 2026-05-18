import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class FinancialAdvisorCard extends StatelessWidget {
  const FinancialAdvisorCard({
    super.key,
    required this.insights,
    required this.getInsightColor,
  });

  final List<Map<String, dynamic>> insights;
  final Color Function(String) getInsightColor;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'dash_financial_advisor'.tr(),
                  style: AppTypography.labelMd.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: insights.map((ins) {
                final color = getInsightColor(ins['type']!);
                return Container(
                  margin:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(ins['icon'] as IconData, size: 16, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ins['text']!,
                          style: AppTypography.labelSm.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
