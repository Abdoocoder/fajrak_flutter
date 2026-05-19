import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'settings_accordion.dart';

class PreferencesSection extends StatefulWidget {
  const PreferencesSection({super.key});

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final appState = context.watch<AppState>();

    return SettingsAccordion(
      icon: Icons.settings,
      title: 'settings_preferences'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings_language'.tr(),
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLangOption(null, 'settings_lang_system', appState, isDark),
              const SizedBox(width: 8),
              _buildLangOption('ar', 'settings_lang_ar', appState, isDark),
              const SizedBox(width: 8),
              _buildLangOption('en', 'settings_lang_en', appState, isDark),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'settings_theme'.tr(),
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildThemeOption(ThemeMode.system, 'settings_theme_system', appState, isDark),
              const SizedBox(width: 8),
              _buildThemeOption(ThemeMode.light, 'settings_theme_light', appState, isDark),
              const SizedBox(width: 8),
              _buildThemeOption(ThemeMode.dark, 'settings_theme_dark', appState, isDark),
            ],
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              'settings_notifications'.tr(),
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: textSecondary),
            onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildLangOption(String? code, String labelKey, AppState appState, bool isDark) {
    final isSelected = appState.languageCode == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeLang(context, code),
        child: _buildToggle(selected: isSelected, label: labelKey.tr(), isDark: isDark),
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String labelKey, AppState appState, bool isDark) {
    final isSelected = appState.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTheme(context, mode),
        child: _buildToggle(selected: isSelected, label: labelKey.tr(), isDark: isDark),
      ),
    );
  }

  Widget _buildToggle({
    required bool selected,
    required String label,
    required bool isDark,
  }) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : border,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.primary : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _changeLang(BuildContext context, String? langCode) async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    await appState.setLanguageCode(langCode);
    if (!mounted) return;

    if (langCode == null) {
      // ignore: use_build_context_synchronously
      await context.deleteSaveLocale();
    } else {
      // ignore: use_build_context_synchronously
      await context.setLocale(Locale(langCode));
    }

    // ignore: use_build_context_synchronously
    messenger.showSnackBar(
      SnackBar(
        content: Text('toast_settings_saved'.tr(), style: const TextStyle()),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changeTheme(BuildContext context, ThemeMode mode) async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    await appState.setTheme(mode);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    messenger.showSnackBar(
      SnackBar(
        content: Text('toast_settings_saved'.tr(), style: const TextStyle()),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
