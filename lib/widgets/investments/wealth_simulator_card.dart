import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

class WealthSimulatorCard extends StatefulWidget {
  final String currency;

  const WealthSimulatorCard({super.key, required this.currency});

  @override
  State<WealthSimulatorCard> createState() => _WealthSimulatorCardState();
}

class _WealthSimulatorCardState extends State<WealthSimulatorCard> {
  bool _showSimulator = false;
  double _monthly = 100;
  int _years = 10;
  double _rate = 7;

  double _calcFV(double monthly, int years, double rate) {
    if (rate == 0) return monthly * years * 12;
    final r = rate / 100 / 12;
    final n = years * 12;
    return monthly * (((1 + r) * ((1 + r) * n - 1)) / r);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final fv = _calcFV(_monthly, _years, _rate);
    final totalInvested = _monthly * _years * 12;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSimulator = !_showSimulator),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.rocket_launch, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'wealthSimulator'.tr(),
                    style: AppTypography.bodyMd.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  _showSimulator ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_showSimulator) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _slider(
                  'monthlyInvestment'.tr(),
                  '${_monthly.toStringAsFixed(0)} ${widget.currency}',
                  _monthly,
                  10,
                  1000,
                  (v) => setState(() => _monthly = v),
                ),
                _slider(
                  'duration'.tr(),
                  '${_years.toInt()} ${'year'.tr()}',
                  _years.toDouble(),
                  1,
                  30,
                  (v) => setState(() => _years = v.toInt()),
                ),
                _slider(
                  'annualReturn'.tr(),
                  '${_rate.toStringAsFixed(0)}%',
                  _rate,
                  1,
                  20,
                  (v) => setState(() => _rate = v),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'inv_sim_after_years'.tr(args: [_years.toString()]),
                        style: AppTypography.labelSm.copyWith(color: textSecondary),
                      ),
                      Text(
                        '${fv.toStringAsFixed(0)} ${widget.currency}',
                        style: AppTypography.displayMedium.copyWith(color: AppColors.accent),
                      ),
                      Text(
                        '${'youInvested'.tr()}: ${totalInvested.toStringAsFixed(0)} ${widget.currency} | ${'inv_profit'.tr()}: ${(fv - totalInvested).toStringAsFixed(0)} ${widget.currency}',
                        style: AppTypography.labelSm.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _slider(
    String label,
    String value,
    double v,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelSm.copyWith(color: textSecondary)),
            Text(value, style: AppTypography.labelSm.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            )),
          ],
        ),
        Slider(
          value: v,
          min: min,
          max: max,
          activeColor: AppColors.accent,
          inactiveColor: border,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
