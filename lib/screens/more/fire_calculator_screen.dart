import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/calculator_disclaimer.dart';
import '../../widgets/common/progress_bar.dart';
import '../../widgets/common/shimmer_loader.dart';

double? _yearsToFIRE(
  double target,
  double current,
  double monthlyContrib,
  double annualReturn,
) {
  if (monthlyContrib <= 0 && current >= target) return 0;
  if (monthlyContrib <= 0) return null;
  final r = annualReturn / 100 / 12;
  double balance = current;
  for (int month = 1; month <= 600; month++) {
    balance = balance * (1 + r) + monthlyContrib;
    if (balance >= target) return (month / 12 * 10).roundToDouble() / 10;
  }
  return null;
}

class FIRECalculatorScreen extends StatefulWidget {
  const FIRECalculatorScreen({super.key});
  @override
  State<FIRECalculatorScreen> createState() => _FIRECalculatorScreenState();
}

class _FIRECalculatorScreenState extends State<FIRECalculatorScreen> {
  double _monthlyExpenses = 500;
  double _withdrawalRate = 4;
  double _annualReturn = 7;
  double _monthlyContrib = 200;
  double _currentNetWorth = 0;
  String _currency = 'JOD';
  String _mode = 'full';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait<dynamic>([
        Supabase.instance.client
            .from('investments')
            .select('shares,current_price')
            .eq('user_id', user.id),
        Supabase.instance.client
            .from('savings_goals')
            .select('current_amount')
            .eq('user_id', user.id),
        Supabase.instance.client
            .from('debts')
            .select('remaining_amount')
            .eq('user_id', user.id)
            .eq('is_paid', false),
        Supabase.instance.client
            .from('profiles')
            .select('currency,monthly_income')
            .eq('id', user.id)
            .single(),
      ]);
      final investments = results[0] as List;
      final goals = results[1] as List;
      final debts = results[2] as List;
      final profile = results[3] as Map<String, dynamic>;
      final invValue = investments.fold(
        0.0,
        (a, i) =>
            a +
            (i['shares'] as num).toDouble() *
                (i['current_price'] as num).toDouble(),
      );
      final goalsSaved = goals.fold(
        0.0,
        (a, g) => a + (g['current_amount'] as num).toDouble(),
      );
      final totalDebt = debts.fold(
        0.0,
        (a, d) => a + (d['remaining_amount'] as num).toDouble(),
      );
      final income = (profile['monthly_income'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        setState(() {
          _currentNetWorth =
              (invValue + goalsSaved - totalDebt).clamp(0, double.infinity);
          _currency = profile['currency'] as String? ?? 'JOD';
          if (income > 0) {
            _monthlyExpenses = (income * 0.7).roundToDouble();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(e, context: context, developerMessage: 'FIRE Calc Load');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.background;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    if (_loading) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text('fire_title'.tr(), style: AppTypography.headingMd.copyWith(color: textPrimary)),
          backgroundColor: surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textSecondary),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: DashboardShimmer(),
        ),
      );
    }

    final modeMultiplier = _mode == 'lean' ? 0.7 : _mode == 'fat' ? 1.5 : 1.0;
    final annualExpenses = _monthlyExpenses * 12 * modeMultiplier;
    final fireNumber = annualExpenses / (_withdrawalRate / 100);
    final progress = ((_currentNetWorth / fireNumber) * 100).clamp(0.0, 100.0);
    final years = _yearsToFIRE(
      fireNumber,
      _currentNetWorth,
      _monthlyContrib,
      _annualReturn,
    );
    final progressColor = progress >= 75
        ? AppColors.income
        : progress >= 40
        ? AppColors.warning
        : AppColors.primary;

    String fmt(double n) => NumberFormat('#,##0', 'en').format(n);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'fire_title'.tr(),
          style: AppTypography.headingMd.copyWith(color: textPrimary),
        ),
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const CalculatorDisclaimer(storageKey: 'disclaimer_fire'),

            // Mode toggle
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: Row(
                children: ['lean', 'full', 'fat'].map((m) {
                  final active = _mode == m;
                  final label = m == 'lean'
                      ? 'lean_fire'.tr()
                      : m == 'full'
                      ? 'full_fire'.tr()
                      : 'fat_fire'.tr();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.textInverse : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // FIRE Number Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fire_number_label'.tr(),
                    style: AppTypography.labelSm.copyWith(color: textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        fmt(fireNumber),
                        style: AppTypography.displaySmall.copyWith(color: progressColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currency,
                        style: AppTypography.labelMd.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppProgressBar(
                    value: progress / 100,
                    title: 'fire_progress'.tr(),
                    percentageLabel: '${progress.toStringAsFixed(1)}%',
                    variant: ProgressBarVariant.goal,
                    fillColor: progressColor,
                    trackHeight: 8,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'current_net_worth'.tr(),
                          value: fmt(_currentNetWorth),
                          currency: _currency,
                          color: AppColors.income,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'remaining'.tr(),
                          value: fmt(
                            (fireNumber - _currentNetWorth).clamp(0, double.infinity),
                          ),
                          currency: _currency,
                          color: AppColors.expense,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: years != null && years <= 10
                          ? AppColors.income.withValues(alpha: 0.08)
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: years != null && years <= 10
                            ? AppColors.income.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: years == null
                        ? Text(
                            'fire_increase_contrib'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.expense,
                            ),
                          )
                        : years == 0
                        ? Text(
                            'fire_already_there'.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.headingMd.copyWith(
                              color: AppColors.income,
                            ),
                          )
                        : Column(
                            children: [
                              Text(
                                'fire_time_label'.tr(),
                                style: AppTypography.labelSm.copyWith(color: textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$years ${'fire_years'.tr()}',
                                style: AppTypography.displaySmall.copyWith(
                                  color: years <= 10 ? AppColors.income : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sliders
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings'.tr(),
                    style: AppTypography.headingSm.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _Slider(
                    label: '${'monthly_expenses'.tr()} ($_currency)',
                    value: _monthlyExpenses,
                    min: 100,
                    max: 5000,
                    divisions: 98,
                    onChanged: (v) => setState(() => _monthlyExpenses = v),
                  ),
                  _Slider(
                    label: '${'monthly_contrib'.tr()} ($_currency)',
                    value: _monthlyContrib,
                    min: 0,
                    max: 3000,
                    divisions: 60,
                    onChanged: (v) => setState(() => _monthlyContrib = v),
                  ),
                  _Slider(
                    label: '${'annual_return'.tr()} (%)',
                    value: _annualReturn,
                    min: 1,
                    max: 20,
                    divisions: 38,
                    onChanged: (v) => setState(() => _annualReturn = v),
                  ),
                  _Slider(
                    label: '${'withdrawal_rate'.tr()} (%)',
                    value: _withdrawalRate,
                    min: 2,
                    max: 8,
                    divisions: 12,
                    onChanged: (v) => setState(() => _withdrawalRate = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, currency;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSm.copyWith(color: textSecondary),
                ),
              ),
              Text(
                value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                style: AppTypography.labelMd.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            inactiveColor: border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
