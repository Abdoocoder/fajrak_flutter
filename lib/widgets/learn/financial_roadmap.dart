import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class FinancialRoadmap extends StatelessWidget {
  final String currentStage;

  const FinancialRoadmap({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final stages = [
      {'id': 'awareness', 'icon': Icons.spa, 'title': 'roadmap_awareness'.tr()},
      {'id': 'debt', 'icon': Icons.credit_card, 'title': 'roadmap_debt'.tr()},
      {'id': 'emergency', 'icon': Icons.shield, 'title': 'roadmap_emergency'.tr()},
      {'id': 'investing', 'icon': Icons.show_chart, 'title': 'roadmap_investing'.tr()},
      {'id': 'wealth', 'icon': Icons.workspace_premium, 'title': 'roadmap_wealth'.tr()},
    ];

    int currentIndex = stages.indexWhere((s) => s['id'] == currentStage);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 40,
            right: 40,
            top: 25,
            child: Container(height: 2, color: border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final s = stages[index];
              final bool isPast = index < currentIndex;
              final bool isCurrent = index == currentIndex;
              final Color color = isCurrent
                  ? AppColors.primary
                  : (isPast ? AppColors.income : textSecondary);

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrent ? color.withValues(alpha: 0.1) : surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(s['icon'] as IconData, size: 20, color: color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['title'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
