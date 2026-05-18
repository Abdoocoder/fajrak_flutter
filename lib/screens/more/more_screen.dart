import 'package:easy_localization/easy_localization.dart';
import '../../utils/error_handler.dart';
import '../../services/analytics_service.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import '../debts/debts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../goals/goals_screen.dart';
import '../investments/investments_screen.dart';
import '../learn/learn_screen.dart';
import '../alerts/alerts_screen.dart';
import '../settings/settings_screen.dart';
import '../help/help_screen.dart';
import 'fire_calculator_screen.dart';
import 'zakat_calculator_screen.dart';

import '../../widgets/more/more_menu_item.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('More');
    _load();
  }

  void _load() async {
    if (!mounted) return;
    try {
      // No explicit Supabase calls in this screen's initial load
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(e, context: context, developerMessage: 'More Load');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPaddingHorizontal,
          AppSpacing.md,
          AppSpacing.screenPaddingHorizontal,
          AppSpacing.xl,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
            child: Text(
              'nav_more'.tr(),
              style: AppTypography.headingLg.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          MoreMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'nav_debts'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebtsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.pie_chart_outline,
            title: 'nav_budgets'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.track_changes,
            title: 'nav_goals'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.trending_up,
            title: 'nav_investments'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvestmentsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.local_fire_department_outlined,
            title: 'fire_title'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FIRECalculatorScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.cruelty_free_outlined,
            title: 'zakat_title'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.menu_book_outlined,
            title: 'nav_learn'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearnScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.notifications_none,
            title: 'nav_alerts'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.settings_outlined,
            title: 'nav_settings'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.help_outline,
            title: 'nav_help'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
