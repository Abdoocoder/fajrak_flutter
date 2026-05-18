import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
import '../common/progress_bar.dart';

class GoalListItem extends StatelessWidget {
  const GoalListItem({
    super.key,
    required this.goal,
    required this.currency,
    required this.onAddAmount,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> goal;
  final String currency;
  final Function(Map<String, dynamic>) onAddAmount;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target = (goal['target_amount'] as num).toDouble();
    final current = (goal['current_amount'] as num).toDouble();
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;
    final isDone = current >= target;

    // income (green) for done or early stages; primary (blue) when nearing target
    final accentColor =
        (!isDone && progress >= 0.7) ? AppColors.primary : AppColors.income;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((goal['icon'] as String?) != null) ...[
                Icon(
                  _getIconData(goal['icon'] as String),
                  size: 22,
                  color: accentColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  goal['name'] ?? '',
                  style: AppTypography.headingSm.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isDone) ...[
                Icon(Icons.check_circle_outline, size: 18, color: accentColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              _ActionButton(
                icon: Icons.edit,
                color: AppColors.primary,
                onTap: () => onEdit(goal),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.close,
                color: AppColors.expense,
                onTap: () => onDelete(goal['id'].toString()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: progress,
            title: '',
            percentageLabel: '${(progress * 100).toStringAsFixed(0)}%',
            variant: ProgressBarVariant.goal,
            fillColor: accentColor,
            infoEnd: isDone
                ? null
                : 'goals_remaining_value'.tr(
                    args: [remaining.toStringAsFixed(0), currency],
                  ),
          ),
          if (!isDone) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'goals_add_saving'.tr(),
              onPressed: () => onAddAmount(goal),
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String? iconString) {
    final codePoint =
        int.tryParse(iconString ?? '') ?? Icons.track_changes.codePoint;
    const icons = [
      Icons.track_changes,
      Icons.directions_car,
      Icons.home,
      Icons.diamond,
      Icons.diamond_outlined,
      Icons.flight,
      Icons.laptop,
      Icons.phone_android,
      Icons.school,
      Icons.workspace_premium,
      Icons.public,
      Icons.cast_for_education,
      Icons.work,
      Icons.fitness_center,
      Icons.favorite,
      Icons.eco,
      Icons.rocket_launch,
      Icons.star,
      Icons.energy_savings_leaf,
      Icons.bar_chart,
      Icons.calendar_today,
      Icons.account_balance_wallet,
      Icons.card_giftcard,
      Icons.shield,
      Icons.bolt,
      Icons.local_fire_department,
      Icons.lightbulb,
      Icons.inventory_2,
      Icons.attach_money,
      Icons.beach_access,
    ];
    for (final icon in icons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.track_changes;
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}
