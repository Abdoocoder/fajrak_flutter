import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = selected
        ? AppColors.primary
        : isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant;

    final textColor = selected
        ? AppColors.textInverse
        : isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary;

    final borderColor = selected
        ? Colors.transparent
        : isDark
            ? AppColors.borderDark
            : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(color: textColor),
        ),
      ),
    );
  }
}

/// A horizontally scrollable row of filter chips.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ??
          const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
      child: Row(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: AppFilterChip(
              label: opt,
              selected: opt == selected,
              onTap: () => onSelected(opt),
            ),
          );
        }).toList(),
      ),
    );
  }
}
