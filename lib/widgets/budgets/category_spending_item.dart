import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../common/progress_bar.dart';

class CategorySpendingItem extends StatelessWidget {
  const CategorySpendingItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.currency,
  });

  final String category;
  final double amount;
  final double percentage;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: AppProgressBar(
        value: percentage / 100,
        title: category,
        variant: ProgressBarVariant.budget,
        infoEnd:
            '${amount.toStringAsFixed(0)} $currency (${percentage.toStringAsFixed(0)}%)',
      ),
    );
  }
}
