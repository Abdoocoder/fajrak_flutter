import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class AlertFilterTabs extends StatelessWidget {
  final String currentFilter;
  final int totalCount;
  final int unreadCount;
  final Function(String) onFilterChanged;

  const AlertFilterTabs({
    super.key,
    required this.currentFilter,
    required this.totalCount,
    required this.unreadCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    Widget tab(String key, String label) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () => onFilterChanged(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: currentFilter == key ? AppColors.primary : surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: currentFilter == key ? AppColors.primary : border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: currentFilter == key
                  ? AppColors.textInverse
                  : textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tab('all', '${'alerts_filter_all'.tr()} ($totalCount)'),
          tab('unread', '${'alerts_filter_unread'.tr()} ($unreadCount)'),
          tab('warning', 'alerts_filter_warning'.tr()),
          tab('achievement', 'alerts_filter_achievement'.tr()),
          tab('motivation', 'alerts_filter_motivation'.tr()),
        ],
      ),
    );
  }
}
