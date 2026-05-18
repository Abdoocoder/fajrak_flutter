import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/confirm_dialog.dart';

/// Category metadata: tint background + emoji for the icon circle.
class _CategoryMeta {
  const _CategoryMeta(this.tint, this.emoji);
  final Color tint;
  final String emoji;

  static _CategoryMeta of(String? category, bool isIncome) {
    if (isIncome) return const _CategoryMeta(AppColors.tintIncome, '💰');
    switch ((category ?? '').toLowerCase()) {
      case 'food':
      case 'طعام':
        return const _CategoryMeta(AppColors.tintFood, '🍽️');
      case 'transport':
      case 'مواصلات':
        return const _CategoryMeta(AppColors.tintTransport, '🚗');
      case 'shopping':
      case 'تسوق':
        return const _CategoryMeta(AppColors.tintShopping, '🛍️');
      case 'health':
      case 'صحة':
        return const _CategoryMeta(AppColors.tintHealth, '💊');
      case 'education':
      case 'تعليم':
        return const _CategoryMeta(AppColors.tintEducation, '📚');
      case 'bills':
      case 'فواتير':
        return const _CategoryMeta(AppColors.tintBills, '🏠');
      case 'investment':
      case 'استثمار':
        return const _CategoryMeta(AppColors.tintInvest, '📈');
      default:
        return const _CategoryMeta(AppColors.tintOther, '💳');
    }
  }
}

/// A fixed-height 68px transaction tile.
/// Use inside ListView.builder with itemExtent: AppSpacing.listItemHeight.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currency,
    required this.onDelete,
    required this.onTap,
    this.syncStatus,
    // Emil stagger: index-based delay, only first 6 on first load
    this.staggerIndex,
  });

  final Map<String, dynamic> transaction;
  final String currency;
  final Function(String) onDelete;
  final Function(Map<String, dynamic>) onTap;
  final String? syncStatus;
  final int? staggerIndex;

  // ignore: unused_element
  Widget? _buildSyncIcon() {
    switch (syncStatus) {
      case 'pending_create':
      case 'pending_update':
        return Tooltip(
          message: 'قيد المزامنة',
          child: Icon(Icons.cloud_upload_outlined, size: 12, color: AppColors.warning),
        );
      case 'pending_delete':
        return Tooltip(
          message: 'حذف قيد المزامنة',
          child: Icon(Icons.delete_outline, size: 12, color: AppColors.expense),
        );
      case 'failed':
        return Tooltip(
          message: 'فشلت المزامنة',
          child: Icon(Icons.error_outline, size: 12, color: AppColors.expense),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction['type'] == 'income';
    final amount = (transaction['amount'] as num).toDouble();
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final category = transaction['category'] as String?;
    final description = transaction['description'] ?? category ?? '';
    final date = transaction['transaction_date'] ?? '';
    final meta = _CategoryMeta.of(category, isIncome);
    final syncIcon = _buildSyncIcon();

    Widget tile = SizedBox(
      height: AppSpacing.listItemHeight,
      child: Dismissible(
        key: Key(transaction['id'].toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          bool confirm = false;
          await ConfirmDialog.show(
            context: context,
            title: 'trans_delete_title'.tr(),
            message: 'confirm_delete'.tr(),
            danger: true,
            onConfirm: () => confirm = true,
          );
          return confirm;
        },
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.screenPaddingHorizontal),
          color: AppColors.expense,
          child: const Icon(Icons.delete_outline, color: AppColors.textInverse, size: 20),
        ),
        onDismissed: (_) => onDelete(transaction['id'].toString()),
        child: InkWell(
          onTap: () => onTap(transaction),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Category icon circle — 40px full-radius
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: meta.tint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    meta.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        description,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$date · ${category ?? ''}',
                        style: AppTypography.bodySm.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (syncIcon != null) ...[
                          syncIcon,
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${isIncome ? '+' : '-'}${amount.toStringAsFixed(0)} $currency',
                          style: AppTypography.currency.copyWith(color: amountColor),
                        ),
                      ],
                    ),
                    if (transaction['original_currency'] != null &&
                        transaction['original_currency'] != currency)
                      Text(
                        '${(transaction['original_amount'] as num).toDouble().toStringAsFixed(0)} ${transaction['original_currency']}',
                        style: AppTypography.bodySm.copyWith(
                          color: amountColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Emil stagger on first load — first 6 tiles only, 40ms per tile
    if (staggerIndex != null && staggerIndex! < 6) {
      tile = _StaggeredTile(index: staggerIndex!, child: tile);
    }

    return tile;
  }
}

class _StaggeredTile extends StatefulWidget {
  const _StaggeredTile({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredTile> createState() => _StaggeredTileState();
}

class _StaggeredTileState extends State<_StaggeredTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: _easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: _easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) {
        if (MediaQuery.of(context).disableAnimations) {
          _controller.value = 1.0;
        } else {
          _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
