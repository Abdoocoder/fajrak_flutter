import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../utils/error_handler.dart';
import '../../services/analytics_service.dart';

import '../../widgets/common/app_button.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/debts/debt_celebration_dialog.dart';
import '../../widgets/debts/debt_summary_section.dart';
import '../../widgets/debts/paid_debt_item.dart';
import '../../widgets/debts/debt_list_item.dart';
import '../../widgets/debts/add_debt_dialog.dart';

const _priorityColors = [
  AppColors.expense,
  AppColors.warning,
  AppColors.primary,
  AppColors.textSecondary,
  AppColors.borderLight,
];

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _receivableDebts = [];
  List<Map<String, dynamic>> _paidDebts = [];
  List<Map<String, dynamic>> _debtAlerts = [];
  bool _loading = true;
  bool _saving = false;
  bool _showPaid = false;
  bool _showOwed = true;
  bool _showReceivable = true;
  String _currency = 'JOD';
  double _totalPaidAmount = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('Debts');
    _load();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final sb = Supabase.instance.client;

      final results = await Future.wait([
        sb.from('profiles').select('currency').eq('id', user.id).maybeSingle(),
        sb
            .from('debts')
            .select('*')
            .eq('user_id', user.id)
            .eq('is_paid', false)
            .order('priority'),
        sb
            .from('debts')
            .select('*')
            .eq('user_id', user.id)
            .eq('is_paid', true)
            .order('updated_at', ascending: false),
        sb
            .from('alerts')
            .select('*')
            .eq('user_id', user.id)
            .eq('is_read', false)
            .eq('is_active', true)
            .or('title.ilike.%قسط%,title.ilike.%دين%,title.ilike.%سداد%')
            .order('created_at', ascending: false)
            .limit(5),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final active = results[1] as List;
      final paid = results[2] as List;
      final alerts = results[3] as List;

      final currency = profile?['currency'] as String? ?? 'JOD';
      final paidTotal = paid.fold(
        0.0,
        (a, d) => a + (d['original_amount'] as num).toDouble(),
      );
      final allActive = List<Map<String, dynamic>>.from(active);

      if (mounted) {
        setState(() {
          _currency = currency;
          _debts = allActive
              .where((d) => (d['debt_type'] ?? 'owed') == 'owed')
              .toList();
          _receivableDebts = allActive
              .where((d) => d['debt_type'] == 'receivable')
              .toList();
          _paidDebts = List<Map<String, dynamic>>.from(paid);
          _totalPaidAmount = paidTotal;
          _debtAlerts = List<Map<String, dynamic>>.from(alerts);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handle(
          e,
          context: context,
          developerMessage: 'Debts Load',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDebtPaymentDone(String debtId, double newRemaining, bool isPaid) {
    setState(() {
      if (isPaid) {
        final debt = _debts.firstWhere(
          (d) => d['id'] == debtId,
          orElse: () => {},
        );
        if (debt.isNotEmpty) {
          _debts.removeWhere((d) => d['id'] == debtId);
          _paidDebts.insert(0, {
            ...debt,
            'is_paid': true,
            'remaining_amount': 0,
          });
          _totalPaidAmount += (debt['original_amount'] as num).toDouble();
        }
      } else {
        final idx = _debts.indexWhere((d) => d['id'] == debtId);
        if (idx != -1) {
          _debts[idx] = {..._debts[idx], 'remaining_amount': newRemaining};
        }
      }
    });
    Future.delayed(const Duration(seconds: 2), _load);
  }

  Future<void> _dismissAlert(String id) async {
    if (_saving) return;
    _saving = true;
    setState(() {});
    try {
      await Supabase.instance.client
          .from('alerts')
          .update({'is_read': true})
          .eq('id', id);
      if (mounted) {
        setState(() => _debtAlerts.removeWhere((a) => a['id'] == id));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCelebration(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DebtCelebrationDialog(name: name),
    );
  }

  Future<void> _deleteDebt(String id) async {
    await ConfirmDialog.show(
      context: context,
      title: 'debts_delete_title'.tr(),
      message: 'confirm_delete'.tr(),
      danger: true,
      onConfirm: () async {
        if (_saving) return;
        _saving = true;
        setState(() {});
        try {
          await Supabase.instance.client.from('debts').delete().eq('id', id);
          await _load();
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
    );
  }

  Future<void> _receiveDebt(Map<String, dynamic> debt) async {
    await ConfirmDialog.show(
      context: context,
      title: 'debts_receive_btn'.tr(),
      message:
          '${'debts_tab_receivable'.tr()}: ${debt['name']}\n${(debt['remaining_amount'] as num).toStringAsFixed(0)} $_currency',
      danger: false,
      onConfirm: () async {
        if (_saving) return;
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;
        _saving = true;
        setState(() {});
        try {
          await Supabase.instance.client
              .from('debts')
              .update({'is_paid': true})
              .eq('id', debt['id']);
          await Supabase.instance.client.from('transactions').insert({
            'user_id': user.id,
            'type': 'income',
            'amount': debt['remaining_amount'],
            'category': 'دين مستلم',
            'description': 'استلام دين: ${debt['name']}',
            'transaction_date': DateTime.now().toIso8601String().split('T')[0],
          });
          if (mounted) {
            _showCelebration(debt['name']);
            await _load();
          }
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
    );
  }

  void _showAddDialog({Map<String, dynamic>? existing, List<String>? labels}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultLabels = [
      'priority_very_high'.tr(),
      'priority_high'.tr(),
      'priority_medium'.tr(),
      'priority_low'.tr(),
      'priority_deferred'.tr(),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => AddDebtDialog(
        existing: existing,
        onSaved: _load,
        priorityColors: _priorityColors,
        priorityLabels: labels ?? defaultLabels,
        baseCurrency: _currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final priorityLabels = [
      'priority_very_high'.tr(),
      'priority_high'.tr(),
      'priority_medium'.tr(),
      'priority_low'.tr(),
      'priority_deferred'.tr(),
    ];

    final totalRemaining = _debts.fold(
      0.0,
      (a, d) => a + (d['remaining_amount'] as num).toDouble(),
    );
    final totalOriginal = _debts.fold(
      0.0,
      (a, d) => a + (d['original_amount'] as num).toDouble(),
    );
    final totalMonthly = _debts.fold(
      0.0,
      (a, d) => a + (d['monthly_payment'] as num).toDouble(),
    );
    final totalReceivable = _receivableDebts.fold(
      0.0,
      (a, d) => a + (d['remaining_amount'] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'debts_title'.tr(),
          style: AppTypography.headingMd.copyWith(color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'debts_add'.tr(),
            onPressed: () => _showAddDialog(labels: priorityLabels),
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: DashboardShimmer(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    DebtSummarySection(
                      totalRemaining: totalRemaining,
                      totalOriginal: totalOriginal,
                      totalMonthly: totalMonthly,
                      currency: _currency,
                      lifeTimePaid: _totalPaidAmount,
                      paidCount: _paidDebts.length,
                    ),

                    // ── تنبيهات الديون ──
                    if (_debtAlerts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._debtAlerts.map((alert) {
                        final type = alert['type'] as String? ?? 'info';
                        final isAchievement = type == 'achievement';
                        final isWarning = type == 'warning';
                        final color = isAchievement
                            ? AppColors.primary
                            : isWarning
                            ? AppColors.warning
                            : AppColors.income;
                        return Dismissible(
                          key: ValueKey(alert['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              _dismissAlert(alert['id'] as String),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.expense,
                              size: 20,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isAchievement
                                      ? '🎉'
                                      : isWarning
                                      ? '💳'
                                      : 'ℹ️',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert['title'] ?? '',
                                        style: AppTypography.labelSm.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if ((alert['message'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          alert['message'],
                                          style: AppTypography.labelSm.copyWith(
                                            color: textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _dismissAlert(alert['id'] as String),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: color.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),

                    // ── ديون عليّ ──
                    if (_debts.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showOwed = !_showOwed),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.expense.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 16,
                                color: AppColors.expense,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'debts_tab_owed'.tr(),
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!_showOwed)
                                Text(
                                  '${totalRemaining.toStringAsFixed(0)} $_currency',
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_debts.length}',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _showOwed
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.expense,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showOwed) ...[
                        const SizedBox(height: 8),
                        ..._debts.map(
                          (d) => DebtListItem(
                            key: ValueKey(d['id']),
                            debt: d,
                            currency: _currency,
                            priorityColors: _priorityColors,
                            priorityLabels: priorityLabels,
                            onEdit: (debt) => _showAddDialog(
                              existing: debt,
                              labels: priorityLabels,
                            ),
                            onDelete: _deleteDebt,
                            onPaymentDone: _onDebtPaymentDone,
                            onCelebration: _showCelebration,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // ── ديون لي ──
                    if (_receivableDebts.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showReceivable = !_showReceivable),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'debts_tab_receivable'.tr(),
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!_showReceivable)
                                Text(
                                  '${totalReceivable.toStringAsFixed(0)} $_currency',
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_receivableDebts.length}',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _showReceivable
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showReceivable) ...[
                        const SizedBox(height: 8),
                        ..._receivableDebts.map(
                          (d) => _ReceivableDebtCard(
                            key: ValueKey(d['id']),
                            debt: d,
                            currency: _currency,
                            onEdit: () => _showAddDialog(
                              existing: d,
                              labels: priorityLabels,
                            ),
                            onDelete: () => _deleteDebt(d['id']),
                            onReceive: () => _receiveDebt(d),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    if (_debts.isEmpty && _receivableDebts.isEmpty)
                      EmptyState(
                        icon: Icons.celebration_outlined,
                        title: 'debts_no_active'.tr(),
                        subtitle: '',
                      ),
                    const SizedBox(height: 16),

                    if (_paidDebts.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showPaid = !_showPaid),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'debts_show_paid'.tr(),
                                  style: AppTypography.bodyMd.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${_paidDebts.length}',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _showPaid
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showPaid) ...[
                        const SizedBox(height: 8),
                        ..._paidDebts.map(
                          (d) => PaidDebtItem(
                            key: ValueKey(d['id']),
                            debt: d,
                            currency: _currency,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ReceivableDebtCard extends StatelessWidget {
  final Map<String, dynamic> debt;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReceive;

  const _ReceivableDebtCard({
    super.key,
    required this.debt,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final amount = (debt['remaining_amount'] as num).toStringAsFixed(0);
    final dueDate = debt['due_date'] as String?;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: AppColors.primary, size: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  debt['name'] ?? '',
                  style: AppTypography.headingSm.copyWith(color: textPrimary),
                ),
              ),
              Text(
                '$amount $currency',
                style: AppTypography.headingSm.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (debt['notes'] != null &&
              (debt['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              debt['notes'],
              style: AppTypography.bodySm.copyWith(color: textSecondary),
            ),
          ],
          if (dueDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  "${'debts_due_date'.tr()}: $dueDate",
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'debts_receive_btn'.tr(),
                  variant: AppButtonVariant.secondary,
                  onPressed: onReceive,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.expense,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
