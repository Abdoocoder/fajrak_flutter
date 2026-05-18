import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/filter_chips.dart';

class TransactionFilters extends StatelessWidget {
  const TransactionFilters({
    super.key,
    required this.currentFilter,
    required this.currentSearch,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onShowDatePicker,
    required this.filterMonth,
    required this.filterYear,
    required this.onMonthYearChanged,
  });

  final String currentFilter;
  final String currentSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onShowDatePicker;
  final int filterMonth;
  final int filterYear;
  final void Function(int month, int year) onMonthYearChanged;

  static const _monthKeys = [
    'month_jan', 'month_feb', 'month_mar', 'month_apr',
    'month_may', 'month_jun', 'month_jul', 'month_aug',
    'month_sep', 'month_oct', 'month_nov', 'month_dec',
  ];

  void _goPrev() {
    if (filterMonth == 1) {
      onMonthYearChanged(12, filterYear - 1);
    } else {
      onMonthYearChanged(filterMonth - 1, filterYear);
    }
  }

  void _goNext() {
    final now = DateTime.now();
    if (filterMonth == now.month && filterYear == now.year) return;
    if (filterMonth == 12) {
      onMonthYearChanged(1, filterYear + 1);
    } else {
      onMonthYearChanged(filterMonth + 1, filterYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth =
        filterMonth == now.month && filterYear == now.year;
    final monthLabel = '${_monthKeys[filterMonth - 1].tr()} $filterYear';

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textTertiary =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;
    final hintColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;
    final inputFill =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month navigator ──────────────────────────────────────────
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.sm,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              _MonthNavButton(
                icon: Icons.chevron_right,
                onTap: _goPrev,
                isDark: isDark,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onShowDatePicker,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: AppTypography.headingSm.copyWith(
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              _MonthNavButton(
                icon: Icons.chevron_left,
                onTap: isCurrentMonth ? null : _goNext,
                isDark: isDark,
                disabled: isCurrentMonth,
              ),
            ],
          ),
        ),

        // ── Search field ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: AppTypography.bodyMd.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'search_hint'.tr(),
              hintStyle: AppTypography.bodyMd.copyWith(color: hintColor),
              prefixIcon: Icon(
                Icons.search_outlined,
                size: 20,
                color: textTertiary,
              ),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── Type filter chips ────────────────────────────────────────
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.xs,
          ),
          child: AppFilterChips(
            options: [
              'trans_all'.tr(),
              'trans_income'.tr(),
              'trans_expense'.tr(),
            ],
            selected: _filterLabel(currentFilter),
            onSelected: (label) {
              if (label == 'trans_income'.tr()) {
                onFilterChanged('income');
              } else if (label == 'trans_expense'.tr()) {
                onFilterChanged('expense');
              } else {
                onFilterChanged('all');
              }
            },
          ),
        ),
      ],
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'income':
        return 'trans_income'.tr();
      case 'expense':
        return 'trans_expense'.tr();
      default:
        return 'trans_all'.tr();
    }
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? (isDark
            ? AppColors.textSecondaryDark
            : AppColors.textTertiary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
