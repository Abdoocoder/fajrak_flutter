import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../services/finance_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/dashboard/balance_card.dart';
import '../../widgets/dashboard/budget_progress_card.dart';
import '../../widgets/transactions/transaction_list_item.dart';
import '../alerts/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _hasError = false;
  double _income = 0, _expenses = 0, _totalBalance = 0;
  String _currency = 'JOD';
  String _name = '';
  List<Map<String, dynamic>> _recentTx = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  int _loadedTransactionVersion = -1;

  // Blue header geometry: status-bar + content (greeting line + date line + padding)
  static const _kHeaderContent = 72.0;
  static const _kOverlap = 18.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    _hasError = false;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final now = DateTime.now();
      final results = await Future.wait<dynamic>([
        Supabase.instance.client
            .from('profiles')
            .select('full_name, currency')
            .eq('id', user.id)
            .single(),
        Supabase.instance.client
            .from('transactions')
            .select(
                'id, type, amount, category, description, transaction_date')
            .eq('user_id', user.id)
            .order('transaction_date', ascending: false)
            .limit(5),
        FinanceService.fetchMonthlyFinancialSummary(
          year: now.year,
          month: now.month,
        ).catchError((_) => <String, dynamic>{}),
        Supabase.instance.client.rpc(
          'get_account_balances',
          params: {'p_user_id': user.id},
        ).catchError((_) => <dynamic>[]),
        Supabase.instance.client
            .from('transactions')
            .select('amount, category')
            .eq('user_id', user.id)
            .eq('type', 'expense')
            .gte(
              'transaction_date',
              '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
            )
            .lt(
              'transaction_date',
              '${DateTime(now.year, now.month + 1, 1).year}-'
              '${DateTime(now.year, now.month + 1, 1).month.toString().padLeft(2, '0')}-01',
            )
            .catchError((_) => <dynamic>[]),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final recent = results[1] as List;
      final monthly = results[2] as Map<String, dynamic>;
      final balancesData = results[3] as List;
      final expensesData = results[4] as List;

      final currency =
          (profile['currency'] as String? ?? 'JOD').toUpperCase();
      final income = (monthly['income'] as num?)?.toDouble() ?? 0.0;
      final expenses = (monthly['expenses'] as num?)?.toDouble() ?? 0.0;
      final totalBalance = balancesData.fold<double>(
        0.0,
        (sum, b) => sum + (b['current_balance'] as num).toDouble(),
      );

      // Aggregate expense transactions by category, take top 2
      final Map<String, double> catMap = {};
      for (final tx in expensesData) {
        final cat = tx['category'] as String? ?? 'أخرى';
        catMap[cat] = (catMap[cat] ?? 0) + (tx['amount'] as num).toDouble();
      }
      final breakdown = catMap.entries
          .map((e) => {'category': e.key, 'amount': e.value})
          .toList()
        ..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
        );

      if (mounted) {
        setState(() {
          _name =
              (profile['full_name'] as String?)?.split(' ').first ?? '';
          _currency = currency;
          _income = income;
          _expenses = expenses;
          _totalBalance = totalBalance;
          _recentTx = recent.cast<Map<String, dynamic>>();
          _categoryBreakdown = breakdown.take(2).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('DashboardScreen _load error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txVersion =
        context.select<AppState, int>((s) => s.transactionVersion);
    if (txVersion != _loadedTransactionVersion) {
      _loadedTransactionVersion = txVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loading) _load();
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + _kHeaderContent;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────
          RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _hasError
                  ? _ErrorView(onRetry: _load, topOffset: headerHeight)
                  : _loading
                      ? Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.screenPaddingHorizontal,
                            headerHeight - _kOverlap,
                            AppSpacing.screenPaddingHorizontal,
                            AppSpacing.xxl,
                          ),
                          child: const DashboardShimmer(),
                        )
                      : _DashboardContent(
                          headerHeight: headerHeight,
                          totalBalance: _totalBalance,
                          income: _income,
                          expenses: _expenses,
                          currency: _currency,
                          recentTx: _recentTx,
                          categoryBreakdown: _categoryBreakdown,
                          onSwitchTab: widget.onSwitchTab,
                        ),
            ),
          ),
          // ── Fixed blue header (renders on top of scroll content) ─
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _DashboardAppBar(name: _name),
          ),
        ],
      ),
    );
  }
}

// ── Blue header ───────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screenPaddingHorizontal,
        top + 12,
        4,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dash_welcome'.tr(args: [name]),
                  style: AppTypography.headingLg.copyWith(
                    color: AppColors.textInverse,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar')
                      .format(DateTime.now()),
                  style: AppTypography.bodySm.copyWith(
                    color: const Color(0x99FFFFFF), // 60% white — clearly secondary
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: AppColors.textInverse,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loaded content ────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.headerHeight,
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.currency,
    required this.recentTx,
    required this.categoryBreakdown,
    required this.onSwitchTab,
  });

  final double headerHeight;
  final double totalBalance;
  final double income;
  final double expenses;
  final String currency;
  final List<Map<String, dynamic>> recentTx;
  final List<Map<String, dynamic>> categoryBreakdown;
  final ValueChanged<int> onSwitchTab;

  static const _kOverlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final displayTx = recentTx.sublist(0, recentTx.length.clamp(0, 3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Push content below header, minus the overlap amount
        SizedBox(height: headerHeight - _kOverlap),

        // BalanceCard — overlaps header's bottom 18dp
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            0,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.md,
          ),
          child: BalanceCard(
            totalBalance: totalBalance,
            income: income,
            expenses: expenses,
            currency: currency,
          ),
        ),

        // BudgetProgressCard
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            0,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
          ),
          child: BudgetProgressCard(
            income: income,
            expenses: expenses,
            currency: currency,
            categoryBreakdown:
                categoryBreakdown.isEmpty ? null : categoryBreakdown,
            onSeeAll: () => onSwitchTab(2),
          ),
        ),

        // Recent transactions header
        SectionHeader(
          title: 'dash_recent'.tr(),
          actionLabel: '${'dash_view_all'.tr()} ←',
          onAction: () => onSwitchTab(1),
        ),

        // Transaction list or empty state
        if (displayTx.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPaddingHorizontal,
              AppSpacing.md,
              AppSpacing.screenPaddingHorizontal,
              0,
            ),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'dash_no_transactions'.tr(),
              subtitle: '',
            ),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPaddingHorizontal,
              0,
              AppSpacing.screenPaddingHorizontal,
              0,
            ),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayTx.length,
                itemExtent: AppSpacing.listItemHeight,
                itemBuilder: (context, i) => TransactionListItem(
                  transaction: displayTx[i],
                  currency: currency,
                  onDelete: (_) {},
                  onTap: (_) => onSwitchTab(1),
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.topOffset});
  final VoidCallback onRetry;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topOffset + AppSpacing.xxl),
        const Icon(
          Icons.error_outline,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'error_generic'.tr(),
          style: AppTypography.headingMd.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'retry'.tr(),
          onPressed: onRetry,
          fullWidth: false,
        ),
      ],
    );
  }
}
