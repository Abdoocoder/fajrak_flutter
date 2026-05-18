import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class BudgetListItem extends StatelessWidget {
  const BudgetListItem({
    super.key,
    required this.budget,
    required this.spent,
    required this.currency,
    required this.localizedCategories,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> budget;
  final double spent;
  final String currency;
  final List<Map<String, dynamic>> localizedCategories;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = localizedCategories.firstWhere(
      (c) => c['key'] == budget['category'],
      orElse: () => {'key': budget['category'], 'icon': Icons.edit_note},
    );
    final limit = (budget['monthly_limit'] as num).toDouble();
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final over = spent > limit;
    final warn = !over && pct > 0.8;
    final remaining = (limit - spent).clamp(0.0, double.infinity);

    final statusColor = over
        ? AppColors.expense
        : warn
            ? AppColors.warning
            : AppColors.income;

    final borderColor = over
        ? AppColors.expense.withValues(alpha: 0.3)
        : warn
            ? AppColors.warning.withValues(alpha: 0.2)
            : isDark
                ? AppColors.borderDark
                : AppColors.borderLight;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Icon(
                    cat['icon'] as IconData,
                    size: 22,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['category'] as String,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $currency'
                      '${over ? ' ⚠ تجاوزت!' : warn ? ' ◼ اقتربت' : ''}',
                      style: AppTypography.bodySm.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                icon: Icons.edit,
                color: AppColors.primary,
                onTap: () => onEdit(budget),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.close,
                color: AppColors.expense,
                onTap: () => onDelete(budget['id'].toString()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: pct,
            title: '',
            percentageLabel: '${(pct * 100).round()}%',
            variant: over
                ? ProgressBarVariant.overspent
                : ProgressBarVariant.budget,
            fillColor: over
                ? AppColors.expense
                : warn
                    ? AppColors.warning
                    : null,
            infoStart: 'budget_remaining_label'.tr(),
            infoEnd:
                '${remaining.toStringAsFixed(0)} $currency — ${'budget_limit_label'.tr(namedArgs: {'amount': limit.toStringAsFixed(0), 'currency': currency})}',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}
