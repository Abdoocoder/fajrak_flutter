import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

class PortfolioChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> investments;
  final double totalValue;

  const PortfolioChartCard({
    super.key,
    required this.investments,
    required this.totalValue,
  });

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.income,
    AppColors.warning,
    AppColors.purple,
    AppColors.expense,
  ];

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty || totalValue <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'inv_portfolio_chart'.tr(),
            style: AppTypography.labelMd.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: investments.map((inv) {
                final val =
                    (inv['shares'] as num).toDouble() *
                    (inv['current_price'] as num).toDouble();
                final pct = val / totalValue * 100;
                final color = _colors[investments.indexOf(inv) % _colors.length];
                return Expanded(
                  flex: pct.round() == 0 ? 1 : pct.round(),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border(
                        right: BorderSide(color: surface, width: 2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...investments.map((inv) {
            final val =
                (inv['shares'] as num).toDouble() *
                (inv['current_price'] as num).toDouble();
            final pct = totalValue > 0 ? (val / totalValue * 100) : 0.0;
            final color = _colors[investments.indexOf(inv) % _colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inv['symbol'] ?? '',
                      style: AppTypography.labelMd.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: AppTypography.labelSm.copyWith(color: textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${val.toStringAsFixed(0)}',
                    style: AppTypography.labelMd.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
