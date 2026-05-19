import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class TransactionSummary extends StatelessWidget {
  const TransactionSummary({
    super.key,
    required this.income,
    required this.expenses,
    required this.currency,
    this.debtPayments = 0,
  });

  final double income;
  final double expenses;
  final double debtPayments;
  final String currency;

  String _fmt(double v) {
    final n = v.abs();
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = income - expenses;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'trans_total_income'.tr(),
              value: _fmt(income),
              currency: currency,
              color: AppColors.income,
              isDark: isDark,
            ),
          ),
          Container(width: 1, height: 36, color: dividerColor),
          Expanded(
            child: _Stat(
              label: 'trans_total_expenses'.tr(),
              value: _fmt(expenses),
              currency: currency,
              color: AppColors.expense,
              isDark: isDark,
            ),
          ),
          Container(width: 1, height: 36, color: dividerColor),
          Expanded(
            child: _Stat(
              label: 'trans_total_net'.tr(),
              value: _fmt(net),
              currency: currency,
              color: net >= 0 ? AppColors.income : AppColors.expense,
              prefix: net > 0 ? '+' : (net < 0 ? '−' : ''),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    required this.isDark,
    this.prefix = '',
  });

  final String label;
  final String value;
  final String currency;
  final Color color;
  final bool isDark;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(color: labelColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '$prefix$value',
          style: AppTypography.headingSm.copyWith(
            color: color,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
