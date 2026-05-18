import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../services/finance_service.dart';
import '../../widgets/common/filter_chips.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/common/section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  bool _loading = true;
  bool _hasError = false;
  String _currency = 'JOD';

  double _income = 0;
  double _expenses = 0;

  // Top 5 expense categories for selected month
  List<Map<String, dynamic>> _topCategories = [];

  // 6-month expense trend — oldest first
  List<double> _trend = List.filled(6, 0);
  List<String> _trendLabels = [];

  static const _monthKeys = [
    'month_jan', 'month_feb', 'month_mar', 'month_apr',
    'month_may', 'month_jun', 'month_jul', 'month_aug',
    'month_sep', 'month_oct', 'month_nov', 'month_dec',
  ];

  late List<_MonthOption> _monthOptions;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _buildMonthOptions();
    _load();
  }

  void _buildMonthOptions() {
    final now = DateTime.now();
    _monthOptions = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - i);
      return _MonthOption(month: dt.month, year: dt.year);
    });
  }

  String _monthLabel(_MonthOption o) {
    final abbr = _monthKeys[o.month - 1].tr();
    final now = DateTime.now();
    return o.year == now.year ? abbr : '$abbr ${o.year}';
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _hasError = false; });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final uid = user.id;
      final monthStart = DateTime(_selectedYear, _selectedMonth, 1)
          .toIso8601String()
          .split('T')[0];
      final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 0)
          .toIso8601String()
          .split('T')[0];

      final now = DateTime.now();
      final trendStart = DateTime(now.year, now.month - 5, 1)
          .toIso8601String()
          .split('T')[0];

      final results = await Future.wait<dynamic>([
        FinanceService.fetchMonthlyFinancialSummary(
          year: _selectedYear,
          month: _selectedMonth,
        ).catchError((_) => <String, dynamic>{}),

        Supabase.instance.client
            .from('transactions')
            .select('category, amount')
            .eq('user_id', uid)
            .eq('type', 'expense')
            .gte('transaction_date', monthStart)
            .lte('transaction_date', monthEnd),

        Supabase.instance.client
            .from('transactions')
            .select('amount, transaction_date')
            .eq('user_id', uid)
            .eq('type', 'expense')
            .gte('transaction_date', trendStart)
            .order('transaction_date'),

        Supabase.instance.client
            .from('profiles')
            .select('currency')
            .eq('id', uid)
            .single(),
      ]);

      final monthly = results[0] as Map<String, dynamic>;
      final catRaw = results[1] as List;
      final trendRaw = results[2] as List;
      final profile = results[3] as Map<String, dynamic>;

      // Aggregate category totals
      final catMap = <String, double>{};
      for (final row in catRaw) {
        final cat = (row['category'] as String?) ?? 'other';
        catMap[cat] = (catMap[cat] ?? 0) + (row['amount'] as num).toDouble();
      }
      final sortedCats = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = sortedCats.take(5).map((e) => {
        'category': e.key,
        'amount': e.value,
      }).toList();

      // Aggregate 6-month trend
      final trendMonths = List.generate(6, (i) {
        return DateTime(now.year, now.month - 5 + i);
      });
      final trendData = List.filled(6, 0.0);
      for (final row in trendRaw) {
        final dateStr = row['transaction_date'] as String;
        final date = DateTime.parse(dateStr);
        for (int i = 0; i < trendMonths.length; i++) {
          if (date.year == trendMonths[i].year &&
              date.month == trendMonths[i].month) {
            trendData[i] += (row['amount'] as num).toDouble();
            break;
          }
        }
      }

      final trendLabels = trendMonths
          .map((dt) {
            final full = _monthKeys[dt.month - 1].tr();
            return full.length > 3 ? full.substring(0, 3) : full;
          })
          .toList();

      if (mounted) {
        setState(() {
          _currency = (profile['currency'] as String? ?? 'JOD').toUpperCase();
          _income = (monthly['income'] as num?)?.toDouble() ?? 0;
          _expenses = (monthly['expenses'] as num?)?.toDouble() ?? 0;
          _topCategories = top5;
          _trend = trendData;
          _trendLabels = trendLabels;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ReportsScreen _load error: $e');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'nav_reports'.tr(),
          style: AppTypography.headingMd.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month selector ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
              ),
              child: Row(
                children: _monthOptions.map((opt) {
                  final isSelected = opt.month == _selectedMonth &&
                      opt.year == _selectedYear;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xs),
                    child: AppFilterChip(
                      label: _monthLabel(opt),
                      selected: isSelected,
                      onTap: () {
                        if (!isSelected) {
                          setState(() {
                            _selectedMonth = opt.month;
                            _selectedYear = opt.year;
                          });
                          _load();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: _hasError
                ? _ErrorView(onRetry: _load, isDark: isDark)
                : _loading
                    ? const Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.screenPaddingHorizontal,
                          AppSpacing.md,
                          AppSpacing.screenPaddingHorizontal,
                          0,
                        ),
                        child: DashboardShimmer(),
                      )
                    : _ReportsContent(
                        income: _income,
                        expenses: _expenses,
                        currency: _currency,
                        topCategories: _topCategories,
                        trend: _trend,
                        trendLabels: _trendLabels,
                        isDark: isDark,
                      ),
          ),
        ],
      ),
    );
  }
}

class _MonthOption {
  const _MonthOption({required this.month, required this.year});
  final int month;
  final int year;
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.isDark});
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'error_generic'.tr(),
            style: AppTypography.headingMd.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'retry'.tr(),
                style:
                    AppTypography.labelMd.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.income,
    required this.expenses,
    required this.currency,
    required this.topCategories,
    required this.trend,
    required this.trendLabels,
    required this.isDark,
  });

  final double income;
  final double expenses;
  final String currency;
  final List<Map<String, dynamic>> topCategories;
  final List<double> trend;
  final List<String> trendLabels;
  final bool isDark;

  String _fmt(double v) {
    final n = v.abs();
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final net = income - expenses;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceBg = isDark ? AppColors.surfaceDark : AppColors.surface;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.md,
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 3-column stat row ──────────────────────────────────────
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'trans_total_income'.tr(),
                    value: _fmt(income),
                    currency: currency,
                    color: AppColors.income,
                  ),
                ),
                Container(width: 1, height: 36, color: dividerColor),
                Expanded(
                  child: _StatColumn(
                    label: 'trans_total_expenses'.tr(),
                    value: _fmt(expenses),
                    currency: currency,
                    color: AppColors.expense,
                  ),
                ),
                Container(width: 1, height: 36, color: dividerColor),
                Expanded(
                  child: _StatColumn(
                    label: 'trans_total_net'.tr(),
                    value: '${net >= 0 ? '+' : '−'}${_fmt(net)}',
                    currency: currency,
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── 6-month trend bar chart ────────────────────────────────
          Text(
            'reports_trend'.tr(),
            style: AppTypography.headingSm.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: _TrendChart(
              trend: trend,
              labels: trendLabels,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Top categories ─────────────────────────────────────────
          if (topCategories.isNotEmpty) ...[
            SectionHeader(title: 'reports_top_categories'.tr()),
            ...topCategories.map((cat) {
              final total = topCategories.fold<double>(
                  0, (s, c) => s + (c['amount'] as double));
              return _CategoryRow(
                category: cat['category'] as String,
                amount: cat['amount'] as double,
                fraction: total > 0
                    ? ((cat['amount'] as double) / total).clamp(0.0, 1.0)
                    : 0,
                currency: currency,
                isDark: isDark,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  final String label;
  final String value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(color: labelColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          '$value $currency',
          style: AppTypography.headingSm.copyWith(
            color: color,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.trend,
    required this.labels,
    required this.isDark,
  });

  final List<double> trend;
  final List<String> labels;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxY = trend.isEmpty
        ? 100.0
        : trend.reduce((a, b) => a > b ? a : b) * 1.25;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY <= 0 ? 100 : maxY,
        barGroups: List.generate(trend.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: trend[i],
                color: AppColors.primary,
                width: 28,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ],
          );
        }),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: AppTypography.labelSm.copyWith(color: labelColor),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.currency,
    required this.isDark,
  });

  final String category;
  final double amount;
  final double fraction;
  final String currency;
  final bool isDark;

  static String _emoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
      case 'طعام':
        return '🍽️';
      case 'transport':
      case 'مواصلات':
        return '🚗';
      case 'shopping':
      case 'تسوق':
        return '🛍️';
      case 'health':
      case 'صحة':
        return '💊';
      case 'education':
      case 'تعليم':
        return '📚';
      case 'bills':
      case 'فواتير':
        return '🏠';
      case 'investment':
      case 'استثمار':
        return '📈';
      default:
        return '💳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final trackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final n = amount.abs();
    final fmt = n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsetsDirectional.only(
          top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emoji(category), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  category,
                  style: AppTypography.bodyMd.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$fmt $currency',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.expense,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: trackColor),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: AppColors.expense),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
