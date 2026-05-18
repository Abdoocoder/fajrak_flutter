# Phase 3 Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current 15-widget dashboard with the Header Overlap layout — blue header, BalanceCard with count-up animation, simplified BudgetProgressCard, and recent transactions. Remove all gamification widgets and DashboardLayoutProvider.

**Architecture:** A `Stack`-based Scaffold body with a `Positioned` blue header that renders on top of a `SingleChildScrollView`. The BalanceCard uses a negative-top-margin trick (pushing content up by `headerHeight - 18dp`) so it visually overlaps the header's bottom edge. All state lives in `_DashboardScreenState`; widget files are kept small and stateless.

**Tech Stack:** Flutter 3.x, Provider, Supabase, easy_localization, intl (DateFormat), shimmer

---

## File Map

| File | Action |
|---|---|
| `lib/widgets/common/shimmer_loader.dart` | Modify: remove `SingleChildScrollView` from `DashboardShimmer` |
| `lib/widgets/common/progress_bar.dart` | Modify: add optional `fillColor` param |
| `assets/i18n/ar.json` | Modify: add 3 keys |
| `assets/i18n/en.json` | Modify: add 3 keys |
| `lib/widgets/dashboard/balance_card.dart` | Create |
| `lib/widgets/dashboard/budget_progress_card.dart` | Rewrite |
| `lib/screens/main_screen.dart` | Modify: `_screens` → getter passing `_switchTab` |
| `lib/screens/dashboard/dashboard_screen.dart` | Full rewrite |
| `lib/main.dart` | Modify: remove `DashboardLayoutProvider` from providers |
| `lib/widgets/dashboard/dashboard_header.dart` | Delete |
| `lib/widgets/dashboard/gamification_card.dart` | Delete |
| `lib/widgets/dashboard/challenges_card.dart` | Delete |
| `lib/widgets/dashboard/wealth_simulator_card.dart` | Delete |
| `lib/widgets/dashboard/dashboard_health_score.dart` | Delete |
| `lib/widgets/dashboard/dashboard_stage_card.dart` | Delete |
| `lib/widgets/dashboard/badges_grid.dart` | Delete |
| `lib/widgets/dashboard/dashboard_customizer_sheet.dart` | Delete |
| `lib/widgets/dashboard/dashboard_quick_add.dart` | Delete |
| `lib/widgets/dashboard/dashboard_stats.dart` | Delete |
| `lib/widgets/dashboard/net_worth_card.dart` | Delete |
| `lib/widgets/dashboard/month_summary_card.dart` | Delete |
| `lib/widgets/dashboard/charts_card.dart` | Delete |
| `lib/widgets/dashboard/quick_links_card.dart` | Delete |
| `lib/providers/dashboard_layout_provider.dart` | Delete |

---

### Task 1: Prep — shimmer fix, progress bar fillColor, translation keys

**Files:**
- Modify: `lib/widgets/common/shimmer_loader.dart:99-142`
- Modify: `lib/widgets/common/progress_bar.dart:9-37`
- Modify: `assets/i18n/ar.json`
- Modify: `assets/i18n/en.json`

- [ ] **Step 1: Remove `SingleChildScrollView` from `DashboardShimmer`**

`DashboardShimmer` currently wraps its content in a `SingleChildScrollView`. This causes nested-scroll issues when used inside `DashboardScreen`'s own scroll view. Replace the entire `DashboardShimmer.build()` with a plain `Column`:

```dart
/// Shimmer matching the Dashboard layout: balance card + budget card + 3 tiles.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(
          width: double.infinity,
          height: 120,
          radius: AppRadius.lg,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        ),
        _ShimmerBox(
          width: double.infinity,
          height: 96,
          radius: AppRadius.lg,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        ),
        _ShimmerBox(
          width: 160,
          height: 16,
          radius: AppRadius.xs,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        const TransactionTileShimmer(),
        const TransactionTileShimmer(),
        const TransactionTileShimmer(),
      ],
    );
  }
}
```

- [ ] **Step 2: Add optional `fillColor` to `AppProgressBar`**

Open `lib/widgets/common/progress_bar.dart`. Add `this.fillColor` parameter and use it in `_fillColor`:

```dart
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    required this.title,
    this.variant = ProgressBarVariant.budget,
    this.percentageLabel,
    this.infoStart,
    this.infoEnd,
    this.fillColor,            // ← NEW
  });

  final double value;
  final String title;
  final ProgressBarVariant variant;
  final String? percentageLabel;
  final String? infoStart;
  final String? infoEnd;
  final Color? fillColor;     // ← NEW

  Color _fillColor(bool isDark) {
    if (fillColor != null) return fillColor!;   // ← NEW: caller override
    switch (variant) {
      case ProgressBarVariant.goal:
        return AppColors.income;
      case ProgressBarVariant.overspent:
        return AppColors.expense;
      case ProgressBarVariant.budget:
        return AppColors.primary;
    }
  }
  // rest of build() unchanged
```

- [ ] **Step 3: Add translation keys to ar.json**

Open `assets/i18n/ar.json`. After the `"dash_no_transactions"` line, add:

```json
  "dash_balance_label": "رصيدك هذا الشهر",
  "dash_monthly_budget": "الميزانية الشهرية",
  "retry": "إعادة المحاولة",
```

- [ ] **Step 4: Add translation keys to en.json**

Open `assets/i18n/en.json`. After the `"dash_no_transactions"` line, add:

```json
  "dash_balance_label": "Your balance this month",
  "dash_monthly_budget": "Monthly Budget",
  "retry": "Retry",
```

- [ ] **Step 5: Verify the app still compiles**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter analyze lib/widgets/common/shimmer_loader.dart lib/widgets/common/progress_bar.dart 2>&1 | tail -5
```

Expected: no errors (warnings about unused params are OK).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/common/shimmer_loader.dart lib/widgets/common/progress_bar.dart assets/i18n/ar.json assets/i18n/en.json
git commit -m "$(cat <<'EOF'
refactor: prep shimmer, progressbar, i18n for Phase 3 dashboard

- DashboardShimmer: remove SingleChildScrollView wrapper (caller handles scroll)
- AppProgressBar: add optional fillColor override for warning states
- i18n: add dash_balance_label, dash_monthly_budget, retry keys

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Create `BalanceCard`

**Files:**
- Create: `lib/widgets/dashboard/balance_card.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_card.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.net,
    required this.income,
    required this.expenses,
    required this.currency,
  });

  final double net;
  final double income;
  final double expenses;
  final String currency;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _curve = Cubic(0.25, 1, 0.5, 1); // easeOutQuart

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.net).animate(
      CurvedAnimation(parent: _controller, curve: _curve),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.net != widget.net) {
      _animation = Tween<double>(begin: 0, end: widget.net).animate(
        CurvedAnimation(parent: _controller, curve: _curve),
      );
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final n = v.abs();
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = widget.net < 0;
    final amountColor = isNegative ? AppColors.expense : AppColors.primary;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return AppCard(
      borderColor: isNegative ? AppColors.expense : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'dash_balance_label'.tr(),
            style: AppTypography.labelSm.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Amount with count-up
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (isNegative) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      _fmt(_animation.value),
                      style: AppTypography.displayLarge.copyWith(
                        color: amountColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.currency,
                    style: AppTypography.headingMd.copyWith(color: labelColor),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: dividerColor),
          const SizedBox(height: AppSpacing.md),
          // Income / expense row
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  isIncome: true,
                  label: 'trans_income'.tr(),
                  amount: widget.income,
                  currency: widget.currency,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: dividerColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatColumn(
                  isIncome: false,
                  label: 'trans_expense'.tr(),
                  amount: widget.expenses,
                  currency: widget.currency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.isIncome,
    required this.label,
    required this.amount,
    required this.currency,
  });

  final bool isIncome;
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final n = amount.abs();
    final formatted =
        n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(color: labelColor),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$formatted $currency',
          style: AppTypography.currency.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze for errors**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter analyze lib/widgets/dashboard/balance_card.dart 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/dashboard/balance_card.dart
git commit -m "$(cat <<'EOF'
feat: add BalanceCard with count-up animation

600ms easeOutQuart count-up, negative-net red border + warning icon,
income/expense stat row, dark mode aware, respects disableAnimations.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Rewrite `BudgetProgressCard`

**Files:**
- Modify: `lib/widgets/dashboard/budget_progress_card.dart`

- [ ] **Step 1: Replace the entire file**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/progress_bar.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.currency,
    this.onSeeAll,
  });

  final double income;
  final double expenses;
  final String currency;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    if (income == 0) {
      return AppCard(
        variant: AppCardVariant.tight,
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 24,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'dash_monthly_budget'.tr(),
              style: AppTypography.headingSm.copyWith(color: labelColor),
            ),
          ],
        ),
      );
    }

    final fraction = (expenses / income).clamp(0.0, 1.0);
    final remaining = income - expenses;
    final remainingFmt = remaining.abs() % 1 == 0
        ? remaining.abs().toStringAsFixed(0)
        : remaining.abs().toStringAsFixed(2);

    // Colour logic: < 0.7 → budget gradient; 0.7–0.9 → warning; ≥ 0.9 → expense red
    ProgressBarVariant variant;
    Color? overrideColor;
    if (fraction >= 0.9) {
      variant = ProgressBarVariant.overspent;
    } else if (fraction >= 0.7) {
      variant = ProgressBarVariant.overspent;
      overrideColor = AppColors.warning;
    } else {
      variant = ProgressBarVariant.budget;
    }

    return AppCard(
      variant: AppCardVariant.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dash_monthly_budget'.tr(),
                style: AppTypography.headingSm.copyWith(color: labelColor),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '${'dash_view_all'.tr()} ←',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          AppProgressBar(
            value: fraction,
            title: '',
            variant: variant,
            fillColor: overrideColor,
            infoEnd: remaining >= 0
                ? '$remainingFmt $currency ${'goals_remaining'.tr()}'
                : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter analyze lib/widgets/dashboard/budget_progress_card.dart 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/dashboard/budget_progress_card.dart
git commit -m "$(cat <<'EOF'
refactor: simplify BudgetProgressCard for Phase 3 dashboard

Single progress bar showing monthly expenses vs income. Warning colour
(AppColors.warning) at 70–90%, expense red at ≥90%. Uses AppCard tight
variant, AppProgressBar with new fillColor override.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire `onSwitchTab` + rewrite `DashboardScreen`

**Files:**
- Modify: `lib/screens/main_screen.dart:26-31`
- Modify: `lib/screens/dashboard/dashboard_screen.dart` (full rewrite)

- [ ] **Step 1: Change `_screens` in `MainScreen` from `static const` to a getter**

Open `lib/screens/main_screen.dart`. Replace:

```dart
  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    MoreScreen(),
  ];
```

With:

```dart
  List<Widget> get _screens => [
    DashboardScreen(onSwitchTab: _switchTab),
    const TransactionsScreen(),
    const ReportsScreen(),
    const MoreScreen(),
  ];
```

- [ ] **Step 2: Rewrite `DashboardScreen`**

Replace the entire contents of `lib/screens/dashboard/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _hasError = false;
  double _income = 0, _expenses = 0, _net = 0;
  String _currency = 'JOD';
  String _name = '';
  List<Map<String, dynamic>> _recentTx = [];
  int _loadedTransactionVersion = -1;

  // Header geometry: status-bar height + content (greeting + date + padding)
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
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final recent = results[1] as List;
      final monthly = results[2] as Map<String, dynamic>;

      final currency =
          (profile['currency'] as String? ?? 'JOD').toUpperCase();
      final income = (monthly['income'] as num?)?.toDouble() ?? 0.0;
      final expenses = (monthly['expenses'] as num?)?.toDouble() ?? 0.0;
      final net =
          (monthly['net'] as num?)?.toDouble() ?? (income - expenses);

      if (mounted) {
        setState(() {
          _name =
              (profile['full_name'] as String?)?.split(' ').first ?? '';
          _currency = currency;
          _income = income;
          _expenses = expenses;
          _net = net;
          _recentTx = recent.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('DashboardScreen _load error: $e');
      if (mounted) setState(() {
        _loading = false;
        _hasError = true;
      });
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

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + _kHeaderContent;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundDark
              : AppColors.background,
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
                      : _Content(
                          headerHeight: headerHeight,
                          net: _net,
                          income: _income,
                          expenses: _expenses,
                          currency: _currency,
                          recentTx: _recentTx,
                          onSwitchTab: widget.onSwitchTab,
                        ),
            ),
          ),
          // ── Fixed blue header (renders on top) ─────────────────
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

// ── Header ────────────────────────────────────────────────────────────

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
                  style: AppTypography.headingMd.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar')
                      .format(DateTime.now()),
                  style: AppTypography.bodySm.copyWith(
                    color: const Color(0xB3FFFFFF), // 70% white
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
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
        ],
      ),
    );
  }
}

// ── Main content (loaded state) ───────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({
    required this.headerHeight,
    required this.net,
    required this.income,
    required this.expenses,
    required this.currency,
    required this.recentTx,
    required this.onSwitchTab,
  });

  final double headerHeight;
  final double net;
  final double income;
  final double expenses;
  final String currency;
  final List<Map<String, dynamic>> recentTx;
  final ValueChanged<int> onSwitchTab;

  static const _kOverlap = 18.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTx = recentTx.sublist(0, recentTx.length.clamp(0, 3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Space: push content below header, minus overlap
        SizedBox(height: headerHeight - _kOverlap),

        // BalanceCard — overlaps header by 18dp
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            0,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.md,
          ),
          child: BalanceCard(
            net: net,
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
            onSeeAll: () => onSwitchTab(2),
          ),
        ),

        // Recent transactions section header
        SectionHeader(
          title: 'dash_recent'.tr(),
          actionLabel: '${'dash_view_all'.tr()} ←',
          onAction: () => onSwitchTab(1),
        ),

        // Recent transactions list (or empty state)
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
```

- [ ] **Step 3: Analyze both files**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter analyze lib/screens/main_screen.dart lib/screens/dashboard/dashboard_screen.dart 2>&1 | tail -15
```

Expected: no errors. Fix any type errors or missing imports before proceeding.

- [ ] **Step 4: Hot-restart and verify visually**

Start the app (`flutter run -d chrome` or your device) and confirm:
- Blue header shows greeting + date
- BalanceCard overlaps the header's bottom edge
- Count-up animation plays
- BudgetProgressCard renders below BalanceCard
- Recent transactions (or empty state) show
- "الكل ←" on Recent → navigates to Transactions tab (index 1)
- "الكل ←" on Budget → navigates to Reports tab (index 2)
- Pull-to-refresh works
- Dark mode: header blue, amounts visible, borders correct

- [ ] **Step 5: Commit**

```bash
git add lib/screens/main_screen.dart lib/screens/dashboard/dashboard_screen.dart
git commit -m "$(cat <<'EOF'
feat: Phase 3 dashboard — Header Overlap layout

Stack-based layout with blue header Positioned on top. BalanceCard
overlaps header by 18dp via SizedBox(height = headerH - 18) spacing.
BudgetProgressCard, recent transactions (3 items), empty state.
Removes DashboardLayoutProvider, GlassPanel, all gamification widgets.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Cleanup — delete obsolete files, remove provider from main

**Files:**
- Modify: `lib/main.dart:119-123`
- Delete: 13 widget files + 1 provider file

- [ ] **Step 1: Remove `DashboardLayoutProvider` from `main.dart`**

Open `lib/main.dart`. Find and remove the `ChangeNotifierProvider` line for `DashboardLayoutProvider`:

Old:
```dart
        providers: [
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider(create: (_) => DashboardLayoutProvider()),
        ],
```

New:
```dart
        providers: [
          ChangeNotifierProvider.value(value: appState),
        ],
```

Also remove the import at the top of `main.dart` for `DashboardLayoutProvider` (look for a line like `import 'providers/dashboard_layout_provider.dart';`).

- [ ] **Step 2: Delete obsolete widget files**

```bash
cd /home/abdullah/Projects/fajrak_flutter
rm lib/widgets/dashboard/dashboard_header.dart
rm lib/widgets/dashboard/gamification_card.dart
rm lib/widgets/dashboard/challenges_card.dart
rm lib/widgets/dashboard/wealth_simulator_card.dart
rm lib/widgets/dashboard/dashboard_health_score.dart
rm lib/widgets/dashboard/dashboard_stage_card.dart
rm lib/widgets/dashboard/badges_grid.dart
rm lib/widgets/dashboard/dashboard_customizer_sheet.dart
rm lib/widgets/dashboard/dashboard_quick_add.dart
rm lib/widgets/dashboard/dashboard_stats.dart
rm lib/widgets/dashboard/net_worth_card.dart
rm lib/widgets/dashboard/month_summary_card.dart
rm lib/widgets/dashboard/charts_card.dart
rm lib/widgets/dashboard/quick_links_card.dart
rm lib/providers/dashboard_layout_provider.dart
```

- [ ] **Step 3: Verify no remaining references**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter analyze lib/ 2>&1 | grep -i "error\|undefined" | head -20
```

Expected: zero errors. If any remaining import references a deleted file, open the referencing file and remove the import.

- [ ] **Step 4: Full build check**

```bash
cd /home/abdullah/Projects/fajrak_flutter && flutter build web --no-pub 2>&1 | tail -10
```

Expected: `Built build/web` with no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git rm lib/widgets/dashboard/dashboard_header.dart \
       lib/widgets/dashboard/gamification_card.dart \
       lib/widgets/dashboard/challenges_card.dart \
       lib/widgets/dashboard/wealth_simulator_card.dart \
       lib/widgets/dashboard/dashboard_health_score.dart \
       lib/widgets/dashboard/dashboard_stage_card.dart \
       lib/widgets/dashboard/badges_grid.dart \
       lib/widgets/dashboard/dashboard_customizer_sheet.dart \
       lib/widgets/dashboard/dashboard_quick_add.dart \
       lib/widgets/dashboard/dashboard_stats.dart \
       lib/widgets/dashboard/net_worth_card.dart \
       lib/widgets/dashboard/month_summary_card.dart \
       lib/widgets/dashboard/charts_card.dart \
       lib/widgets/dashboard/quick_links_card.dart \
       lib/providers/dashboard_layout_provider.dart
git commit -m "$(cat <<'EOF'
chore: delete obsolete dashboard widgets and DashboardLayoutProvider

Removes 14 files replaced by the Phase 3 Header Overlap dashboard:
gamification, challenges, wealth simulator, health score, stage card,
badges, customizer sheet, quick add, stats, net worth, month summary,
charts, quick links, and the layout provider.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Header Overlap: Stack + Positioned `_DashboardAppBar`, content pushed by `headerHeight - 18`
- ✅ BalanceCard: count-up 600ms `Cubic(0.25,1,0.5,1)`, negative state (red border + ⚠), income/expense row
- ✅ BudgetProgressCard: `AppProgressBar` with warning/overspent color logic, "See all" → tab 2
- ✅ Recent transactions: `SectionHeader` + 3 tiles in `AppCard`, "See all" → tab 1
- ✅ Remove gamification: 14 files deleted
- ✅ Remove `DashboardLayoutProvider`: deleted + removed from `main.dart` providers
- ✅ `disableAnimations` respected in `BalanceCard`
- ✅ Dark mode: `isDark` checks in `BalanceCard`, `BudgetProgressCard`, `_DashboardAppBar` uses `AppColors.primary` (same in both modes)
- ✅ Translation keys: `dash_balance_label`, `dash_monthly_budget`, `retry` added in Task 1
- ✅ `EdgeInsetsDirectional` throughout — no left/right
- ✅ Text on primary AppBar uses `AppColors.textInverse`
- ✅ Shimmer: `DashboardShimmer` shown with correct top offset during loading
- ✅ Error state: `_ErrorView` with icon + `error_generic`.tr() + `AppButton` retry

**Placeholder scan:** None found.

**Type consistency:**
- `BalanceCard` props: `net`, `income`, `expenses`, `currency` — all `double`/`String`
- `BudgetProgressCard` props: `income`, `expenses`, `currency`, `onSeeAll` — consistent
- `onSwitchTab: ValueChanged<int>` — matches `_switchTab` signature in `MainScreen`
- `DashboardShimmer` returns `Column` (no scroll wrapper) — consistent with caller's `Padding` wrapper
