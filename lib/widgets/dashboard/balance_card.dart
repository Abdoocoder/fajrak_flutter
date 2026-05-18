import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_card.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.net,
    required this.income,
    required this.expenses,
    required this.currency,
  });

  final double net;
  final double income;
  final double expenses;
  final String currency;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _curve = Cubic(0.25, 1, 0.5, 1); // easeOutQuart

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.net).animate(
      CurvedAnimation(parent: _controller, curve: _curve),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.net != widget.net) {
      _animation = Tween<double>(begin: 0, end: widget.net).animate(
        CurvedAnimation(parent: _controller, curve: _curve),
      );
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final n = v.abs();
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = widget.net < 0;
    final amountColor = isNegative ? AppColors.expense : AppColors.primary;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return AppCard(
      borderColor: isNegative ? AppColors.expense : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dash_balance_label'.tr(),
            style: AppTypography.labelSm.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Count-up amount
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (isNegative) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      _fmt(_animation.value),
                      style: AppTypography.displayLarge.copyWith(
                        color: amountColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.currency,
                    style: AppTypography.headingMd.copyWith(color: labelColor),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: AppSpacing.md),
          // Income / expense row
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  isIncome: true,
                  label: 'trans_income'.tr(),
                  amount: widget.income,
                  currency: widget.currency,
                ),
              ),
              Container(width: 1, height: 36, color: dividerColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatColumn(
                  isIncome: false,
                  label: 'trans_expense'.tr(),
                  amount: widget.expenses,
                  currency: widget.currency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.isIncome,
    required this.label,
    required this.amount,
    required this.currency,
  });

  final bool isIncome;
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final n = amount.abs();
    final formatted =
        n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(color: labelColor),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$formatted $currency',
          style: AppTypography.currency.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
