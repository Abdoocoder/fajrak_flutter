import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_accordion.dart';

class AssetsForm extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final double netWorth;
  final double cashBalance;
  final double savings;
  final double investments;
  final double totalDebt;
  final String currency;

  const AssetsForm({
    super.key,
    required this.initialProfile,
    required this.netWorth,
    required this.cashBalance,
    required this.savings,
    required this.investments,
    required this.totalDebt,
    required this.currency,
  });

  @override
  State<AssetsForm> createState() => _AssetsFormState();
}

class _AssetsFormState extends State<AssetsForm> {
  late TextEditingController _realEstateCtrl;
  late TextEditingController _vehiclesCtrl;
  late TextEditingController _jewelryCtrl;
  late TextEditingController _otherAssetsCtrl;

  bool _savingAssets = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile ?? {};
    _realEstateCtrl = TextEditingController(
      text: p['asset_real_estate']?.toString() ?? '',
    );
    _vehiclesCtrl = TextEditingController(
      text: p['asset_vehicles']?.toString() ?? '',
    );
    _jewelryCtrl = TextEditingController(
      text: p['asset_jewelry']?.toString() ?? '',
    );
    _otherAssetsCtrl = TextEditingController(
      text: p['asset_other']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _realEstateCtrl.dispose();
    _vehiclesCtrl.dispose();
    _jewelryCtrl.dispose();
    _otherAssetsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAssets() async {
    if (_savingAssets) return;
    _savingAssets = true;
    setState(() {});
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'asset_real_estate': double.tryParse(_realEstateCtrl.text) ?? 0,
        'asset_vehicles': double.tryParse(_vehiclesCtrl.text) ?? 0,
        'asset_jewelry': double.tryParse(_jewelryCtrl.text) ?? 0,
        'asset_other': double.tryParse(_otherAssetsCtrl.text) ?? 0,
        'assets_updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('toast_saved'.tr(), style: const TextStyle()),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAssets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    final totalDynamicAssets =
        (double.tryParse(_realEstateCtrl.text) ?? 0) +
        (double.tryParse(_vehiclesCtrl.text) ?? 0) +
        (double.tryParse(_jewelryCtrl.text) ?? 0) +
        (double.tryParse(_otherAssetsCtrl.text) ?? 0);
    final displayedNetWorth =
        widget.cashBalance +
        widget.savings +
        widget.investments +
        totalDynamicAssets -
        widget.totalDebt;

    return SettingsAccordion(
      icon: Icons.diamond_outlined,
      title: 'settings_assets_title'.tr(),
      badge: 'settings_net_worth'.tr(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  'settings_your_net_worth'.tr(),
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${displayedNetWorth.toStringAsFixed(0)} ${widget.currency}',
                  style: TextStyle(
                    color: displayedNetWorth >= 0 ? AppColors.income : AppColors.expense,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _netWorthStat('health_tracking'.tr(), widget.cashBalance, AppColors.primary, textSecondary),
                    _netWorthStat('health_savings'.tr(), widget.savings, AppColors.purple, textSecondary),
                    _netWorthStat('health_investing'.tr(), widget.investments, AppColors.income, textSecondary),
                    _netWorthStat('health_debt'.tr(), -widget.totalDebt, AppColors.expense, textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _assetField(
                  _realEstateCtrl,
                  'settings_assets_realestate'.tr(),
                  isDark: isDark, surface: surface, border: border,
                  textPrimary: textPrimary, textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _assetField(
                  _vehiclesCtrl,
                  'settings_assets_vehicles'.tr(),
                  isDark: isDark, surface: surface, border: border,
                  textPrimary: textPrimary, textSecondary: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _assetField(
                  _jewelryCtrl,
                  'settings_assets_jewelry'.tr(),
                  isDark: isDark, surface: surface, border: border,
                  textPrimary: textPrimary, textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _assetField(
                  _otherAssetsCtrl,
                  'settings_assets_other'.tr(),
                  isDark: isDark, surface: surface, border: border,
                  textPrimary: textPrimary, textSecondary: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingAssets ? null : _saveAssets,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: AppColors.textInverse,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _savingAssets
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : Text(
                      'save'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netWorthStat(String label, double value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
        ),
        Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _assetField(
    TextEditingController ctrl,
    String label, {
    required bool isDark,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSecondary, fontSize: 12),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
