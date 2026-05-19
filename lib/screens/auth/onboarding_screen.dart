import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../services/analytics_service.dart';
import '../../services/currency_service.dart';
import '../../utils/detect_currency.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/currency_picker_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _incomeController = TextEditingController();
  int _salaryDay = 25;
  String _currency = 'JOD';
  bool _loading = false;
  DetectionResult? _detected;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('Onboarding');
    final result = DetectCurrency.detect();
    _currency = result.currency;
    _detected = result;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final income = double.tryParse(_incomeController.text) ?? 0;

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'monthly_income': income,
        'salary_day': _salaryDay,
        'currency': _currency,
        'onboarding_done': true,
      });

      if (income > 0) {
        await Supabase.instance.client.from('transactions').insert({
          'user_id': user.id,
          'type': 'income',
          'amount': income,
          'category': 'cat_salary'.tr(),
          'description': 'onboarding_income_desc'.tr(),
          'transaction_date': DateTime.now().toIso8601String().split('T')[0],
        });
      }

      AnalyticsService.logEvent('onboarding_complete', {
        'income': income,
        'currency': _currency,
        'salary_day': _salaryDay,
      });

      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(e, context: context, developerMessage: 'Onboarding Save');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.background;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildDot(index, isDark)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _slideIntro(isDark),
                  _slideIncome(isDark),
                  _slideSalaryDay(isDark),
                  _slideSummary(isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textInverse,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.textInverse,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 3
                                  ? 'onboarding_start'.tr()
                                  : 'continue'.tr(),
                              style: AppTypography.labelLg.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  if (_currentStep > 0 && !_loading)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(
                        'back'.tr(),
                        style: AppTypography.labelMd.copyWith(color: textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentStep == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentStep == index ? AppColors.primary : border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _slideIntro(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            'onboarding_welcome_title'.tr(),
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'onboarding_welcome_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(color: textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _slideIncome(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return _slideBase(
      isDark: isDark,
      icon: Icons.account_balance_wallet_outlined,
      title: 'settings_income'.tr(),
      subtitle: 'onboarding_income_subtitle'.tr(),
      child: TextFormField(
        controller: _incomeController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: AppTypography.displaySmall.copyWith(color: textPrimary),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: AppTypography.displaySmall.copyWith(color: textSecondary),
          suffixText: _currency,
          suffixStyle: AppTypography.bodyLg.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _slideSalaryDay(bool isDark) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return _slideBase(
      isDark: isDark,
      icon: Icons.calendar_today_outlined,
      title: 'onboarding_payday_title'.tr(),
      subtitle: 'onboarding_payday_subtitle'.tr(),
      child: Column(
        children: [
          Text(
            'onboarding_day_value'.tr(args: [_salaryDay.toString()]),
            style: AppTypography.displaySmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: border,
              thumbColor: AppColors.textInverse,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _salaryDay.toDouble(),
              min: 1,
              max: 28,
              divisions: 27,
              onChanged: (v) => setState(() => _salaryDay = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slideSummary(bool isDark) {
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final info = CurrencyService.findByCode(_currency);
    return _slideBase(
      isDark: isDark,
      icon: Icons.public,
      title: 'settings_currency'.tr(),
      subtitle: 'onboarding_currency_subtitle'.tr(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  info?['flag'] as String? ?? '🌐',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info?['labelAr'] as String? ?? _currency,
                        style: AppTypography.labelMd.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _currency,
                        style: AppTypography.labelSm.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await showCurrencyPickerSheet(
                      context: context,
                      selectedCode: _currency,
                      onSelected: (code) => setState(() => _currency = code),
                    );
                  },
                  child: Text(
                    'تغيير',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_detected?.confidence == 'high' &&
              _detected!.countryName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '📍 اكتشفنا أنك في ${_detected!.countryName}',
              style: AppTypography.labelSm.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _slideBase({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.headingLg.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
