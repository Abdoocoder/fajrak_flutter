import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PaidDebtItem extends StatelessWidget {
  final Map<String, dynamic> debt;
  final String currency;

  const PaidDebtItem({super.key, required this.debt, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 24, color: AppColors.income),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt['name'] ?? '',
                  style: AppTypography.bodyMd.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (debt['updated_at'] != null)
                  Text(
                    debt['updated_at'].toString().substring(0, 10),
                    style: AppTypography.labelSm.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${(debt['original_amount'] as num).toStringAsFixed(0)} $currency',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.income,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
