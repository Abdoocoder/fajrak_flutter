import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../utils/error_handler.dart';
import '../../services/analytics_service.dart';

import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/filter_chips.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/investments/portfolio_summary_card.dart';
import '../../widgets/investments/portfolio_chart_card.dart';
import '../../widgets/investments/wealth_simulator_card.dart';
import '../../widgets/investments/investment_list_item.dart';
import '../../widgets/investments/add_investment_dialog.dart';
import '../../widgets/investments/investment_cash_card.dart';
import '../../services/investments_service.dart';
import '../../services/currency_service.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  List<Map<String, dynamic>> _investments = [];
  bool _loading = true;
  bool _saving = false;
  bool _showInUsd = true;
  double _usdToLocalRate = 0.709;
  String _currency = 'JOD';
  double _cashBalance = 0;
  String _cashCurrency = 'USD';
  String _sortBy = 'none';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('Investments');
    _load().then((_) {
      if (mounted) _load(refreshPrices: true);
    });
  }

  Future<void> _load({bool refreshPrices = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait(<Future<dynamic>>[
        Supabase.instance.client
            .from('investments')
            .select('*')
            .eq('user_id', user.id),
        Supabase.instance.client
            .from('profiles')
            .select('currency')
            .eq('id', user.id)
            .single(),
        Supabase.instance.client
            .from('investment_cash')
            .select('*')
            .eq('user_id', user.id),
      ]);
      final data = results[0] as List;
      final profile = results[1] as Map<String, dynamic>;
      final cashData = results[2] as List;

      final loadedCurrency = profile['currency'] as String? ?? 'JOD';
      if (loadedCurrency != 'USD') {
        final rate = await CurrencyService.fetchExchangeRate('USD', loadedCurrency);
        if (rate != null && mounted) _usdToLocalRate = rate;
      } else {
        _usdToLocalRate = 1.0;
      }

      if (mounted) {
        setState(() {
          _currency = loadedCurrency;
          if (cashData.isNotEmpty) {
            _cashBalance = (cashData[0]['balance'] as num).toDouble();
            _cashCurrency = cashData[0]['currency'] as String? ?? 'USD';
          } else {
            _cashBalance = 0;
          }
        });
      }

      var investments = List<Map<String, dynamic>>.from(data);

      if (refreshPrices) {
        await Future.wait(
          List.generate(investments.length, (i) async {
            final symbol = investments[i]['symbol'] as String?;
            if (symbol == null) return;
            final newPrice = await InvestmentsService.fetchPrice(symbol);
            if (newPrice != null) {
              investments[i]['current_price'] = newPrice;
              await Supabase.instance.client
                  .from('investments')
                  .update({'current_price': newPrice})
                  .eq('id', investments[i]['id']);
            }
          }),
        );
      }

      if (mounted) {
        setState(() {
          _investments = investments;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(e, context: context, developerMessage: 'Investments Load');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalValue => _investments.fold(
    0.0,
    (a, i) =>
        a +
        (i['shares'] as num).toDouble() *
            (i['current_price'] as num).toDouble(),
  );

  double get _totalCost => _investments.fold(
    0.0,
    (a, i) =>
        a +
        (i['shares'] as num).toDouble() *
            (i['avg_buy_price'] as num).toDouble(),
  );

  double _invGainPct(Map<String, dynamic> inv) {
    final cost =
        (inv['shares'] as num).toDouble() *
        (inv['avg_buy_price'] as num).toDouble();
    final value =
        (inv['shares'] as num).toDouble() *
        (inv['current_price'] as num).toDouble();
    return cost > 0 ? (value - cost) / cost * 100 : 0.0;
  }

  List<Map<String, dynamic>> get _displayedInvestments {
    var list = List<Map<String, dynamic>>.from(_investments);
    if (_filterType == 'halal') {
      list = list.where((i) => i['is_halal'] == true).toList();
    } else if (_filterType == 'crypto') {
      list = list.where((i) => (i['type'] as String? ?? '').toLowerCase() == 'crypto').toList();
    } else if (_filterType == 'stocks') {
      list = list.where((i) => (i['type'] as String? ?? '').toLowerCase() != 'crypto').toList();
    }
    switch (_sortBy) {
      case 'gain':
        list.sort((a, b) => _invGainPct(b).compareTo(_invGainPct(a)));
      case 'loss':
        list.sort((a, b) => _invGainPct(a).compareTo(_invGainPct(b)));
      case 'value':
        list.sort((a, b) {
          final va = (a['shares'] as num).toDouble() * (a['current_price'] as num).toDouble();
          final vb = (b['shares'] as num).toDouble() * (b['current_price'] as num).toDouble();
          return vb.compareTo(va);
        });
      case 'name':
        list.sort((a, b) => (a['symbol'] as String? ?? '').compareTo(b['symbol'] as String? ?? ''));
    }
    return list;
  }

  Future<void> _deleteInvestment(String id) async {
    await ConfirmDialog.show(
      context: context,
      title: 'inv_delete_title'.tr(),
      message: 'confirm_delete'.tr(),
      danger: true,
      onConfirm: () async {
        if (_saving) return;
        _saving = true;
        setState(() {});
        try {
          await Supabase.instance.client.from('investments').delete().eq('id', id);
          await _load();
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
    );
  }

  void _showAddDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => AddInvestmentDialog(onSaved: () => _load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    final filterKeys = ['all', 'halal', 'crypto', 'stocks'];
    final filterLabels = filterKeys.map((f) => 'inv_filter_$f'.tr()).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'inv_title'.tr(),
          style: AppTypography.headingMd.copyWith(color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _showInUsd = !_showInUsd),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Text(
                _showInUsd ? 'inv_currency_usd'.tr() : _currency,
                style: AppTypography.labelSm.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'inv_refresh'.tr(),
            onPressed: () async {
              setState(() => _loading = true);
              await _load(refreshPrices: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'inv_add'.tr(),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: DashboardShimmer(),
            )
          : RefreshIndicator(
              onRefresh: () => _load(refreshPrices: true),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    PortfolioSummaryCard(
                      totalValue: _totalValue,
                      totalCost: _totalCost,
                      showInUsd: _showInUsd,
                      jodRate: _usdToLocalRate,
                      assetsCount: _investments.length,
                      halalCount: _investments.where((i) => i['is_halal'] == true).length,
                    ),
                    const SizedBox(height: 16),
                    PortfolioChartCard(
                      investments: _investments,
                      totalValue: _totalValue,
                    ),
                    const SizedBox(height: 16),
                    WealthSimulatorCard(currency: _currency),
                    const SizedBox(height: 16),
                    InvestmentCashCard(
                      balance: _cashBalance,
                      currency: _cashCurrency,
                      accountCurrency: _currency,
                      onTransferred: _load,
                    ),
                    if (_investments.isEmpty)
                      EmptyState(
                        icon: Icons.show_chart,
                        title: 'inv_empty'.tr(),
                        subtitle: '',
                        ctaLabel: 'inv_add_first'.tr(),
                        onCta: _showAddDialog,
                      )
                    else ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'inv_portfolio_count'.tr(
                              args: [_investments.length.toString()],
                            ),
                            style: AppTypography.headingSm.copyWith(color: textPrimary),
                          ),
                          PopupMenuButton<String>(
                            initialValue: _sortBy,
                            onSelected: (v) => setState(() => _sortBy = v),
                            color: surface,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _sortBy != 'none'
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sort, size: 14, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'inv_sort_by'.tr(),
                                    style: AppTypography.labelSm.copyWith(color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'none', child: Text('inv_sort_none'.tr(), style: const TextStyle(fontSize: 13))),
                              PopupMenuItem(value: 'gain', child: Text('inv_sort_gain'.tr(), style: const TextStyle(fontSize: 13))),
                              PopupMenuItem(value: 'loss', child: Text('inv_sort_loss'.tr(), style: const TextStyle(fontSize: 13))),
                              PopupMenuItem(value: 'value', child: Text('inv_sort_value'.tr(), style: const TextStyle(fontSize: 13))),
                              PopupMenuItem(value: 'name', child: Text('inv_sort_name'.tr(), style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppFilterChips(
                        options: filterLabels,
                        selected: filterLabels[filterKeys.indexOf(_filterType)],
                        onSelected: (label) {
                          final idx = filterLabels.indexOf(label);
                          if (idx >= 0) setState(() => _filterType = filterKeys[idx]);
                        },
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 10),
                      ..._displayedInvestments.map(
                        (inv) => InvestmentListItem(
                          key: ValueKey(inv['id']),
                          inv: inv,
                          onDelete: _deleteInvestment,
                          onChanged: _load,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mosque, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'inv_halal_tip'.tr(),
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
