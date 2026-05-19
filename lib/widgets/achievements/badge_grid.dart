import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BadgeGrid extends StatelessWidget {
  final List<String> earnedBadges;
  final Map<String, dynamic> badgeInfo;

  const BadgeGrid({
    super.key,
    required this.earnedBadges,
    required this.badgeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            'gamif_badges_title'.tr(
              namedArgs: {
                'earned': earnedBadges.length.toString(),
                'total': badgeInfo.length.toString(),
              },
            ),
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badgeInfo.entries.map((entry) {
            final key = entry.key;
            final info = entry.value;
            final earned = earnedBadges.contains(key);
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - 32 - 20) / 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: earned ? AppColors.primary.withValues(alpha: 0.1) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: earned ? AppColors.primary.withValues(alpha: 0.4) : border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      info.$1 as IconData,
                      size: 28,
                      color: earned ? AppColors.primary : border,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.$2,
                      style: TextStyle(
                        color: earned ? textPrimary : textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    Text(
                      info.$3,
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
