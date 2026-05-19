import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../services/currency_service.dart';

class InvestmentCashCard extends StatefulWidget {
  final double balance;
  final String currency;
  final String accountCurrency;
  final VoidCallback onTransferred;

  const InvestmentCashCard({
    super.key,
    required this.balance,
    required this.currency,
    required this.accountCurrency,
    required this.onTransferred,
  });

  @override
  State<InvestmentCashCard> createState() => _InvestmentCashCardState();
}

class _InvestmentCashCardState extends State<InvestmentCashCard> {
  final _amountCtrl = TextEditingController();
  bool _transferring = false;
  double? _exchangeRate;
  bool _loadingRate = false;

  bool get _needsConversion => widget.currency != widget.accountCurrency;

  Future<void> _fetchRate() async {
    if (!_needsConversion) return;
    setState(() => _loadingRate = true);
    final rate = await CurrencyService.fetchExchangeRate(
      widget.currency,
      widget.accountCurrency,
    );
    if (mounted) {
      setState(() {
        _exchangeRate = rate;
        _loadingRate = false;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _showTransferDialog() async {
    _amountCtrl.text = widget.balance.toStringAsFixed(2);
    await _fetchRate();

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            start: 20,
            end: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'inv_cash_transfer_title'.tr(),
                style: AppTypography.headingMd.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '${'inv_cash_available'.tr()}: ${widget.balance.toStringAsFixed(2)} ${widget.currency}',
                style: AppTypography.labelMd.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                onChanged: (_) => setModalState(() {}),
                style: AppTypography.displaySmall.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'inv_cash_transfer_amount_hint'.tr(),
                  hintStyle: AppTypography.bodyMd.copyWith(color: textSecondary),
                  suffix: Text(
                    widget.currency,
                    style: AppTypography.labelMd.copyWith(color: textSecondary),
                  ),
                  filled: true,
                  fillColor: surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_needsConversion) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: _loadingRate
                      ? Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : _exchangeRate == null
                      ? Text(
                          'تعذر جلب سعر الصرف',
                          style: AppTypography.labelSm.copyWith(color: AppColors.expense),
                        )
                      : () {
                          final enteredAmount = double.tryParse(_amountCtrl.text) ?? 0;
                          final converted = enteredAmount * _exchangeRate!;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('سعر الصرف', style: AppTypography.labelSm.copyWith(color: textSecondary)),
                                  Text(
                                    '1 ${widget.currency} = ${_exchangeRate!.toStringAsFixed(4)} ${widget.accountCurrency}',
                                    style: AppTypography.labelSm.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ستستلم', style: AppTypography.labelSm.copyWith(color: textSecondary)),
                                  Text(
                                    '${converted.toStringAsFixed(2)} ${widget.accountCurrency}',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.income,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }(),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _transferring
                      ? null
                      : () => _doTransfer(ctx, setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _transferring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : Text(
                          'inv_cash_transfer_confirm'.tr(),
                          style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doTransfer(BuildContext ctx, StateSetter setModalState) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    if (amount > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('inv_cash_transfer_exceeds'.tr())),
      );
      return;
    }

    setModalState(() => _transferring = true);
    final user = Supabase.instance.client.auth.currentUser!;

    try {
      final convertedAmount = _needsConversion && _exchangeRate != null
          ? amount * _exchangeRate!
          : amount;

      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'type': 'income',
        'category': 'استثمار',
        'amount': convertedAmount,
        'description':
            'تحويل من المحفظة الاستثمارية ($amount ${widget.currency}${_needsConversion && _exchangeRate != null ? ' ← ${convertedAmount.toStringAsFixed(2)} ${widget.accountCurrency}' : ''})',
        'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      });

      await Supabase.instance.client.rpc(
        'upsert_investment_cash',
        params: {
          'p_user_id': user.id,
          'p_currency': widget.currency,
          'p_amount': -amount,
        },
      );

      if (ctx.mounted) Navigator.pop(ctx);
      widget.onTransferred();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('inv_cash_transfer_success'.tr()),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      setModalState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final hasBalance = widget.balance > 0;

    return Container(
      margin: EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasBalance ? AppColors.income.withValues(alpha: 0.3) : border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'inv_cash_title'.tr(),
                style: AppTypography.headingSm.copyWith(color: textPrimary),
              ),
              const Spacer(),
              if (hasBalance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    widget.currency,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasBalance)
            Text(
              'inv_cash_empty'.tr(),
              style: AppTypography.bodySm.copyWith(color: textSecondary),
            )
          else ...[
            Text(
              '\$${widget.balance.toStringAsFixed(2)}',
              style: AppTypography.displaySmall.copyWith(color: AppColors.income),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showTransferDialog,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  'inv_cash_transfer_btn'.tr(),
                  style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
