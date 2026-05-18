import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.margin,
  });

  final double width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final highlightColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for a single 68px TransactionTile.
class TransactionTileShimmer extends StatelessWidget {
  const TransactionTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.listItemHeight,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.screenPaddingHorizontal,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Category circle
            const _ShimmerBox(width: 40, height: 40, radius: AppRadius.full),
            const SizedBox(width: AppSpacing.sm),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _ShimmerBox(width: double.infinity, height: 14, radius: AppRadius.xs),
                  SizedBox(height: 6),
                  _ShimmerBox(width: 100, height: 10, radius: AppRadius.xs),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Amount
            const _ShimmerBox(width: 64, height: 16, radius: AppRadius.xs),
          ],
        ),
      ),
    );
  }
}

/// 6-tile shimmer for the Transactions list screen.
class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const TransactionTileShimmer()),
    );
  }
}

/// Shimmer matching the Dashboard layout: balance card + budget card + 3 tiles.
/// Caller is responsible for scrolling — this widget returns a plain Column.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerBox(
          width: double.infinity,
          height: 120,
          radius: AppRadius.lg,
          margin: EdgeInsets.only(bottom: AppSpacing.lg),
        ),
        const _ShimmerBox(
          width: double.infinity,
          height: 96,
          radius: AppRadius.lg,
          margin: EdgeInsets.only(bottom: AppSpacing.lg),
        ),
        const _ShimmerBox(
          width: 160,
          height: 16,
          radius: AppRadius.xs,
          margin: EdgeInsets.only(bottom: AppSpacing.md),
        ),
        ...List.generate(3, (_) => const TransactionTileShimmer()),
      ],
    );
  }
}
