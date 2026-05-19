import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../utils/error_handler.dart';
import '../../services/currency_service.dart';
import '../common/progress_bar.dart';

class DebtListItem extends StatefulWidget {
  final Map<String, dynamic> debt;
  final String currency;
  final List<Color> priorityColors;
  final List<String> priorityLabels;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final Function(String debtId, double newRemaining, bool isPaid) onPaymentDone;
  final Function(String) onCelebration;

  const DebtListItem({
    super.key,
    required this.debt,
    required this.currency,
    required this.priorityColors,
    required this.priorityLabels,
    required this.onEdit,
    required this.onDelete,
    required this.onPaymentDone,
    required this.onCelebration,
  });

  @override
  State<DebtListItem> createState() => _DebtListItemState();
}

class _DebtListItemState extends State<DebtListItem> {
  bool _isPaying = false;
  bool _payingSaving = false;
  final _paymentCtrl = TextEditingController();

  String _paymentCurrency = '';
  double _paymentExchangeRate = 1.0;

  @override
  void initState() {
    super.initState();
    _paymentCurrency = widget.currency;
  }

  Future<void> _updatePaymentRate() async {
    if (_paymentCurrency == widget.currency) {
      if (mounted) setState(() => _paymentExchangeRate = 1.0);
      return;
    }
    final rate = await CurrencyService.fetchExchangeRate(
      _paymentCurrency,
      widget.currency,
    );
    if (mounted) setState(() => _paymentExchangeRate = rate ?? 1.0);
  }

  @override
  void dispose() {
    _paymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _makePayment() async {
    if (_payingSaving) return;
    final amount = double.tryParse(_paymentCtrl.text);
    if (amount == null || amount <= 0) return;
    _payingSaving = true;
    setState(() {});

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final amountInBaseCurrency = _paymentCurrency == widget.currency
          ? amount
          : (amount * _paymentExchangeRate);

      final currentRemaining = (widget.debt['remaining_amount'] as num)
          .toDouble();
      final newRemaining = (currentRemaining - amountInBaseCurrency).clamp(
        0.0,
        double.infinity,
      );
      final today = DateTime.now().toIso8601String().split('T')[0];
      final sb = Supabase.instance.client;

      await Future.wait([
        sb
            .from('debts')
            .update({
              'remaining_amount': newRemaining,
              'remaining_amount_foreign':
                  _paymentCurrency == widget.debt['currency']
                  ? ((widget.debt['remaining_amount_foreign'] as num?)
                                ?.toDouble() ??
                            currentRemaining) -
                        amount
                  : null,
              'is_paid': newRemaining == 0,
            })
            .eq('id', widget.debt['id']),
        sb.from('debt_payments').insert({
          'debt_id': widget.debt['id'],
          'user_id': user.id,
          'amount': amountInBaseCurrency,
          'original_amount': amount,
          'original_currency': _paymentCurrency,
          'exchange_rate': _paymentExchangeRate,
          'payment_date': DateTime.now().toIso8601String(),
        }),
        sb.from('transactions').insert({
          'user_id': user.id,
          'type': 'expense',
          'amount': amountInBaseCurrency,
          'original_amount': amount,
          'original_currency': _paymentCurrency,
          'exchange_rate': _paymentExchangeRate,
          'category': 'debts_title'.tr(),
          'description': '${'debts_paid'.tr()}: ${widget.debt['name']}',
          'transaction_date': today,
        }),
      ]);

      _paymentCtrl.clear();
      setState(() {
        _payingSaving = false;
        _isPaying = false;
      });

      if (newRemaining == 0) {
        widget.onCelebration(widget.debt['name'] as String);
      }
      widget.onPaymentDone(
        widget.debt['id'] as String,
        newRemaining,
        newRemaining == 0,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _payingSaving = false);
        ErrorHandler.handle(
          e,
          context: context,
          developerMessage: 'Debt Payment',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    final original = (widget.debt['original_amount'] as num).toDouble();
    final remaining = (widget.debt['remaining_amount'] as num).toDouble();
    final pct = original > 0 ? ((original - remaining) / original * 100) : 0.0;
    final priorityIndex = ((widget.debt['priority'] as int?) ?? 3) - 1;
    final prioColor = widget.priorityColors[priorityIndex.clamp(0, 4)];

    final paymentDay = widget.debt['payment_day'] as int?;
    final dueDate = widget.debt['due_date'] as String?;
    final autoDeduct = widget.debt['auto_deduct'] == true;
    final now = DateTime.now();
    final dueDateParsed = dueDate != null ? DateTime.tryParse(dueDate) : null;
    final isOverdue = dueDateParsed != null && dueDateParsed.isBefore(now);
    int? daysUntil;
    if (paymentDay != null) {
      final today = now.day;
      daysUntil = today <= paymentDay
          ? paymentDay - today
          : DateTime(
              now.year,
              now.month + 1,
              paymentDay,
            ).difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: prioColor),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: prioColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: prioColor,
                            boxShadow: [
                              BoxShadow(
                                color: prioColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.debt['name'] ?? '',
                            style: AppTypography.bodyMd.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.debt['notes'] != null &&
                              (widget.debt['notes'] as String).isNotEmpty)
                            Text(
                              widget.debt['notes'],
                              style: AppTypography.bodySm.copyWith(
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (autoDeduct || isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                children: [
                                  if (autoDeduct)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '⚡ تلقائي',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (isOverdue)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '🔴 متأخر',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.expense,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${remaining.toStringAsFixed(0)} ${widget.currency}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => widget.onEdit(widget.debt),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          widget.onDelete(widget.debt['id'].toString()),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.expense,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppProgressBar(
                  value: (pct / 100).clamp(0.0, 1.0),
                  title: '',
                  percentageLabel: '${pct.toStringAsFixed(0)}%',
                  variant: ProgressBarVariant.goal,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'debts_paid_pct'.tr(args: [pct.toStringAsFixed(0)]),
                      style: AppTypography.labelSm.copyWith(color: textSecondary),
                    ),
                    Row(
                      children: [
                        if ((widget.debt['monthly_payment'] as num).toDouble() > 0)
                          Text(
                            '${(widget.debt['monthly_payment'] as num).toStringAsFixed(0)}${'debts_per_month'.tr()}',
                            style: AppTypography.labelSm.copyWith(color: textSecondary),
                          ),
                        if (widget.debt['payment_day'] != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'debts_day_label'.tr(
                                args: [widget.debt['payment_day'].toString()],
                              ),
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (daysUntil != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: daysUntil == 0
                                    ? AppColors.warning.withValues(alpha: 0.15)
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                daysUntil == 0
                                    ? '🔔 اليوم!'
                                    : 'بعد $daysUntil يوم',
                                style: AppTypography.labelSm.copyWith(
                                  color: daysUntil == 0
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (widget.debt['due_date'] != null) ...[
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 10,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (widget.debt['due_date'] as String).substring(
                                  0,
                                  10,
                                ),
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Payment row
                if (_isPaying)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _paymentCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'trans_amount'.tr(),
                                hintStyle: TextStyle(color: textSecondary),
                                filled: true,
                                fillColor: surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _paymentCurrency,
                                dropdownColor: surface,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                items:
                                    [
                                          'JOD',
                                          'USD',
                                          'SAR',
                                          'AED',
                                          'EGP',
                                          'TRY',
                                          'EUR',
                                        ]
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _paymentCurrency = v);
                                    _updatePaymentRate();
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _payingSaving ? null : _makePayment,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.income,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _payingSaving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textInverse,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check,
                                      color: AppColors.textInverse,
                                      size: 14,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPaying = false;
                                _paymentCtrl.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                color: textSecondary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_paymentCurrency != widget.currency)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'Rate: ${_paymentExchangeRate.toStringAsFixed(4)} | ≈ ${((double.tryParse(_paymentCtrl.text) ?? 0) * _paymentExchangeRate).toStringAsFixed(2)} ${widget.currency}',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textTertiary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPaying = true;
                          _paymentCtrl.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.income.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'debts_add_payment_btn'.tr(),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.income,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
