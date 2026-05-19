import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class AlertActions extends StatelessWidget {
  final int unreadCount;
  final bool hasAlerts;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;

  const AlertActions({
    super.key,
    required this.unreadCount,
    required this.hasAlerts,
    required this.onMarkAllRead,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (unreadCount > 0)
          TextButton(
            onPressed: onMarkAllRead,
            child: Text(
              'alerts_mark_all_read'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        if (hasAlerts)
          TextButton(
            onPressed: onDeleteAll,
            child: Text(
              'alerts_delete_all'.tr(),
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}
