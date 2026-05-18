import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'nav_item_widget.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItemWidget(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'nav_home'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 1,
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz,
                label: 'nav_transactions'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 2,
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'nav_reports'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 3,
                icon: Icons.menu_outlined,
                selectedIcon: Icons.menu,
                label: 'nav_more'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
