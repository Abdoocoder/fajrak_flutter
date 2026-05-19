import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../common/shimmer_loader.dart';

class InvestmentTxHistoryModal extends StatefulWidget {
  final String invId;
  final String symbol;

  const InvestmentTxHistoryModal({
    super.key,
    required this.invId,
    required this.symbol,
  });

  @override
  State<InvestmentTxHistoryModal> createState() =>
      _InvestmentTxHistoryModalState();
}

class _InvestmentTxHistoryModalState extends State<InvestmentTxHistoryModal> {
  List<Map<String, dynamic>> _txHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await Supabase.instance.client
        .from('investment_transactions')
        .select('*')
        .eq('investment_id', widget.invId)
        .order('transaction_date', ascending: false);

    if (mounted) {
      setState(() {
        _txHistory = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: DashboardShimmer(),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'inv_tx_history_symbol'.tr(args: [widget.symbol]),
            style: AppTypography.headingMd.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 20),
          if (_txHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'inv_empty'.tr(),
                  style: AppTypography.bodyMd.copyWith(color: textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _txHistory.length,
                itemBuilder: (ctx, i) {
                  final tx = _txHistory[i];
                  final isBuy = tx['type'] == 'buy';
                  final color = isBuy ? AppColors.income : AppColors.expense;
                  final shares = (tx['shares'] as num).toDouble();
                  final price = (tx['price'] as num).toDouble();
                  final comm = (tx['commission'] as num?)?.toDouble() ?? 0;
                  return Container(
                    margin: EdgeInsetsDirectional.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              isBuy ? Icons.trending_up : Icons.trending_down,
                              size: 16,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${isBuy ? "inv_buy".tr() : "inv_sell".tr()} ${shares.toStringAsFixed(4)} ${"inv_unit".tr()}',
                                style: AppTypography.labelMd.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${tx['transaction_date']} • ${"inv_price".tr()} \$${price.toStringAsFixed(2)}',
                                style: AppTypography.labelSm.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isBuy ? "-" : "+"}\$${(shares * price).toStringAsFixed(0)}',
                              style: AppTypography.labelMd.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (comm > 0)
                              Text(
                                'inv_commission'.tr(args: [comm.toStringAsFixed(2)]),
                                style: AppTypography.labelSm.copyWith(color: textSecondary),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
