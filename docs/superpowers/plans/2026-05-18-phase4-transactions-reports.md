# Phase 4 — Transactions Polish + Reports Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the Transactions screen with the design system (AppColors tokens, shimmer, itemExtent) and build the Reports screen from scratch (month selector, stat row, bar chart, top categories).

**Architecture:** Transactions screen is already functionally complete — only token/widget alignment needed, no logic changes. Reports screen is a fresh `StatefulWidget` with a selected-month state that drives 3 parallel Supabase queries; all sections re-render reactively on month change.

**Tech Stack:** Flutter 3.x, Supabase, fl_chart ^1.1.0, easy_localization, AppColors/AppTypography/AppSpacing tokens, AppFilterChip, AppTextField (styled), TransactionShimmer, AppButton

---

## File Map

| File | Action |
|---|---|
| `lib/widgets/transactions/transaction_filters.dart` | Rewrite — remove `colorScheme`, use AppColors tokens, AppFilterChip, styled search |
| `lib/screens/transactions/transactions_screen.dart` | Modify — AppBar tokens, shimmer, itemExtent, error state, remove colorScheme from call |
| `lib/screens/reports/reports_screen.dart` | Rewrite — full Reports screen with all 4 sections |

---

## Task 1: Rewrite TransactionFilters (design token alignment)

**Files:**
- Modify: `lib/widgets/transactions/transaction_filters.dart`

The current widget uses `colorScheme` (old system) everywhere. Replace with `AppColors` tokens directly. Replace `TextFormField` search with a styled `TextField`. Replace custom `_filterChip` with `AppFilterChip` from the design system.

- [ ] **Step 1: Replace the entire file content**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/filter_chips.dart';

class TransactionFilters extends StatelessWidget {
  const TransactionFilters({
    super.key,
    required this.currentFilter,
    required this.currentSearch,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onShowDatePicker,
    required this.filterMonth,
    required this.filterYear,
    required this.onMonthYearChanged,
  });

  final String currentFilter;
  final String currentSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onShowDatePicker;
  final int filterMonth;
  final int filterYear;
  final void Function(int month, int year) onMonthYearChanged;

  static const _monthKeys = [
    'month_jan', 'month_feb', 'month_mar', 'month_apr',
    'month_may', 'month_jun', 'month_jul', 'month_aug',
    'month_sep', 'month_oct', 'month_nov', 'month_dec',
  ];

  void _goPrev() {
    if (filterMonth == 1) {
      onMonthYearChanged(12, filterYear - 1);
    } else {
      onMonthYearChanged(filterMonth - 1, filterYear);
    }
  }

  void _goNext() {
    final now = DateTime.now();
    if (filterMonth == now.month && filterYear == now.year) return;
    if (filterMonth == 12) {
      onMonthYearChanged(1, filterYear + 1);
    } else {
      onMonthYearChanged(filterMonth + 1, filterYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth =
        filterMonth == now.month && filterYear == now.year;
    final monthLabel = '${_monthKeys[filterMonth - 1].tr()} $filterYear';

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textTertiary =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;
    final hintColor = isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;
    final inputFill =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month navigator ──────────────────────────────────────────
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.sm,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              _MonthNavButton(
                icon: Icons.chevron_right,
                onTap: _goPrev,
                isDark: isDark,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onShowDatePicker,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: AppTypography.headingSm.copyWith(
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              _MonthNavButton(
                icon: Icons.chevron_left,
                onTap: isCurrentMonth ? null : _goNext,
                isDark: isDark,
                disabled: isCurrentMonth,
              ),
            ],
          ),
        ),

        // ── Search field ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.xs,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: AppTypography.bodyMd.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'search_hint'.tr(),
              hintStyle:
                  AppTypography.bodyMd.copyWith(color: hintColor),
              prefixIcon: Icon(
                Icons.search_outlined,
                size: 20,
                color: textTertiary,
              ),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── Type filter chips ────────────────────────────────────────
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.xs,
          ),
          child: AppFilterChips(
            options: [
              'trans_all'.tr(),
              'trans_income'.tr(),
              'trans_expense'.tr(),
            ],
            selected: _filterLabel(currentFilter),
            onSelected: (label) {
              if (label == 'trans_income'.tr()) {
                onFilterChanged('income');
              } else if (label == 'trans_expense'.tr()) {
                onFilterChanged('expense');
              } else {
                onFilterChanged('all');
              }
            },
          ),
        ),
      ],
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'income':
        return 'trans_income'.tr();
      case 'expense':
        return 'trans_expense'.tr();
      default:
        return 'trans_all'.tr();
    }
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? (isDark
            ? AppColors.textSecondaryDark
            : AppColors.textTertiary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze for errors**

```bash
flutter analyze lib/widgets/transactions/transaction_filters.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/transactions/transaction_filters.dart
git commit -m "refactor: align TransactionFilters with design system — AppColors tokens, AppFilterChip"
```

---

## Task 2: Polish TransactionsScreen shell

**Files:**
- Modify: `lib/screens/transactions/transactions_screen.dart`

Changes:
1. AppBar — surface bg, textPrimary title, textTertiary icon colors
2. Remove `colorScheme` prop from `TransactionFilters` call
3. Replace `ListSkeleton` with `TransactionShimmer`
4. Add `itemExtent: AppSpacing.listItemHeight` to `ListView.builder`
5. Remove `CircularProgressIndicator` load-more (silent load — no indicator)
6. Fix error state — AppColors + `AppButton`

- [ ] **Step 1: Fix the AppBar — replace colorScheme references**

Find this block in `build()`:

```dart
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'trans_title'.tr(),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'trans_count'.tr(args: [filtered.length.toString()]),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
```

Replace with:

```dart
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'trans_title'.tr(),
              style: AppTypography.headingMd.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              'trans_count'.tr(args: [filtered.length.toString()]),
              style: AppTypography.bodySm.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
```

- [ ] **Step 2: Fix AppBar action icon colors**

Find all `color: colorScheme.onSurfaceVariant` and `color: colorScheme.primary` inside the `actions:` list and replace:

```dart
// Before:
icon: Icon(Icons.cloud_upload_outlined),
color: Colors.orange[600],
// (leave the orange sync badge as-is — it's intentional)

// For all other icons — replace colorScheme.onSurfaceVariant with:
color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,

// For colorScheme.primary:
color: AppColors.primary,
```

Add `isDark` local variable at the top of `build()`:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

- [ ] **Step 3: Remove `colorScheme` prop from TransactionFilters call**

Find:
```dart
          TransactionFilters(
            currentFilter: _filter,
            currentSearch: _search,
            onSearchChanged: (v) {
              setState(() => _search = v.toLowerCase());
            },
            onFilterChanged: (v) {
              setState(() {
                _filter = v;
                _transactions = [];
                _loading = true;
              });
              _load(reset: true);
            },
            onShowDatePicker: _showMonthYearPicker,
            colorScheme: colorScheme,
            filterMonth: _filterMonth ?? DateTime.now().month,
            filterYear: _filterYear ?? DateTime.now().year,
            onMonthYearChanged: (m, y) {
              setState(() {
                _filterMonth = m;
                _filterYear = y;
              });
              _load(reset: true);
            },
          ),
```

Replace with (remove `colorScheme:` line):

```dart
          TransactionFilters(
            currentFilter: _filter,
            currentSearch: _search,
            onSearchChanged: (v) {
              setState(() => _search = v.toLowerCase());
            },
            onFilterChanged: (v) {
              setState(() {
                _filter = v;
                _transactions = [];
                _loading = true;
              });
              _load(reset: true);
            },
            onShowDatePicker: _showMonthYearPicker,
            filterMonth: _filterMonth ?? DateTime.now().month,
            filterYear: _filterYear ?? DateTime.now().year,
            onMonthYearChanged: (m, y) {
              setState(() {
                _filterMonth = m;
                _filterYear = y;
              });
              _load(reset: true);
            },
          ),
```

- [ ] **Step 4: Replace ListSkeleton with TransactionShimmer**

Find the import:
```dart
import '../../widgets/common/skeleton_loader.dart';
```
Replace with:
```dart
import '../../widgets/common/shimmer_loader.dart';
```

Find:
```dart
                : _loading && _transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ListSkeleton(count: 8),
                  )
```

Replace with:
```dart
                : _loading && _transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                    child: TransactionShimmer(count: 8),
                  )
```

- [ ] **Step 5: Add `itemExtent` to ListView.builder + remove CircularProgressIndicator load-more**

Find:
```dart
                : RefreshIndicator(
                    onRefresh: _triggerSync,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount:
                          filtered.length + (_hasMore && _loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }
                        final tx = filtered[index];
                        return TransactionListItem(
                          key: ValueKey(tx['id']),
                          transaction: tx,
                          currency: _currency,
                          onDelete: _delete,
                          onTap: (t) => _showAddDialog(existing: t),
                          syncStatus: _syncStatuses[tx['id']],
                        );
                      },
                    ),
                  ),
```

Replace with:

```dart
                : RefreshIndicator(
                    onRefresh: _triggerSync,
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0, 8, 0, 100),
                      itemExtent: AppSpacing.listItemHeight,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return TransactionListItem(
                          key: ValueKey(tx['id']),
                          transaction: tx,
                          currency: _currency,
                          onDelete: _delete,
                          onTap: (t) => _showAddDialog(existing: t),
                          syncStatus: _syncStatuses[tx['id']],
                          staggerIndex: index < 6 ? index : null,
                        );
                      },
                    ),
                  ),
```

- [ ] **Step 6: Fix error state — AppColors + AppButton**

Add import at the top:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/app_button.dart';
```

Find the error state block:
```dart
            : _hasError && _transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 56,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'error_load_failed'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'error_check_connection'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _load(reset: true),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              'btn_retry'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
```

Replace with:

```dart
            : _hasError && _transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(
                          AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'error_load_failed'.tr(),
                            style: AppTypography.headingMd.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'error_check_connection'.tr(),
                            style: AppTypography.bodySm.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'retry'.tr(),
                            onPressed: () => _load(reset: true),
                            fullWidth: false,
                          ),
                        ],
                      ),
                    ),
                  )
```

- [ ] **Step 7: Also fix the empty state to use AppColors**

Find:
```dart
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'trans_empty'.tr(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  )
```

Replace with:

```dart
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 48,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'trans_empty'.tr(),
                          style: AppTypography.headingMd.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
```

- [ ] **Step 8: Remove unused imports**

Remove these if they appear unused after the above edits:
```dart
// Remove if no other use:
// import '../../widgets/common/skeleton_loader.dart';
// The `final theme = Theme.of(context)` and `final colorScheme = theme.colorScheme;`
// lines can be removed if colorScheme is no longer used anywhere else.
```

Check with:
```bash
flutter analyze lib/screens/transactions/transactions_screen.dart
```

Fix any remaining `colorScheme` references by replacing with their AppColors equivalents.

- [ ] **Step 9: Analyze both changed files**

```bash
flutter analyze lib/screens/transactions/transactions_screen.dart lib/widgets/transactions/transaction_filters.dart
```

Expected: no errors.

- [ ] **Step 10: Commit**

```bash
git add lib/screens/transactions/transactions_screen.dart
git commit -m "refactor: align TransactionsScreen with design system — AppColors, shimmer, itemExtent"
```

---

## Task 3: Build ReportsScreen — data + month selector + stat row

**Files:**
- Rewrite: `lib/screens/reports/reports_screen.dart`

The Reports screen is stateful. `_selectedMonth` and `_selectedYear` drive all data. On change, 3 parallel Supabase queries run: monthly summary, category breakdown, 6-month trend.

- [ ] **Step 1: Write the full ReportsScreen**

Replace the entire file with:

```dart
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

  // Monthly stats
  double _income = 0;
  double _expenses = 0;

  // Category breakdown — top 5 expense categories for selected month
  // [{category: 'طعام', amount: 120.0}, ...]
  List<Map<String, dynamic>> _topCategories = [];

  // 6-month trend — list of 6 doubles (expenses), oldest first
  List<double> _trend = List.filled(6, 0);
  // Month labels for trend bars (abbreviated), oldest first
  List<String> _trendLabels = [];

  static const _monthKeys = [
    'month_jan', 'month_feb', 'month_mar', 'month_apr',
    'month_may', 'month_jun', 'month_jul', 'month_aug',
    'month_sep', 'month_oct', 'month_nov', 'month_dec',
  ];

  // The 12 month options shown as filter chips, newest first
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
    // Show year only if not current year
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

      // 6-month trend: fetch last 6 months of expense transactions
      final now = DateTime.now();
      final trendStart = DateTime(now.year, now.month - 5, 1)
          .toIso8601String()
          .split('T')[0];

      final results = await Future.wait<dynamic>([
        // 1. Monthly summary (income + expenses)
        FinanceService.fetchMonthlyFinancialSummary(
          year: _selectedYear,
          month: _selectedMonth,
        ).catchError((_) => <String, dynamic>{}),

        // 2. Category breakdown for selected month (expenses only)
        Supabase.instance.client
            .from('transactions')
            .select('category, amount')
            .eq('user_id', uid)
            .eq('type', 'expense')
            .gte('transaction_date', monthStart)
            .lte('transaction_date', monthEnd),

        // 3. 6-month trend (all expense transactions)
        Supabase.instance.client
            .from('transactions')
            .select('amount, transaction_date')
            .eq('user_id', uid)
            .eq('type', 'expense')
            .gte('transaction_date', trendStart)
            .order('transaction_date'),

        // 4. Profile currency
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
        final dt = DateTime(now.year, now.month - 5 + i);
        return dt;
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
          .map((dt) => _monthKeys[dt.month - 1].tr().substring(0, 3))
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
          Icon(Icons.error_outline,
              size: 48,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'error_generic'.tr(),
            style: AppTypography.headingMd.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Inline retry button — no AppButton import needed here
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
                style: AppTypography.labelMd.copyWith(
                    color: AppColors.textInverse),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/screens/reports/reports_screen.dart
```

Fix any errors (likely missing imports).

- [ ] **Step 3: Commit checkpoint**

```bash
git add lib/screens/reports/reports_screen.dart
git commit -m "feat: ReportsScreen — month selector + data loading + stat row scaffold"
```

---

## Task 4: Add stat row + bar chart + top categories to ReportsScreen

**Files:**
- Modify: `lib/screens/reports/reports_screen.dart` (add `_ReportsContent` and `_TrendChart` widgets at the bottom of the file)

- [ ] **Step 1: Add `_ReportsContent`, `_StatRow`, `_TrendChart`, and `_CategoryRow` at the end of `reports_screen.dart`**

Append these classes after `_ErrorView`:

```dart
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
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

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
            SectionHeader(
              title: 'reports_top_categories'.tr(),
              actionLabel: '',
              onAction: null,
            ),
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
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
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
```

- [ ] **Step 2: Add missing i18n keys**

Check for `reports_trend` and `reports_top_categories` keys:

```bash
grep -E "reports_trend|reports_top_categories" assets/i18n/ar.json assets/i18n/en.json
```

If missing, add to both files. In `ar.json` after `"nav_reports"`:
```json
"reports_trend": "مصاريف آخر ٦ أشهر",
"reports_top_categories": "أعلى الفئات",
```

In `en.json`:
```json
"reports_trend": "6-Month Expense Trend",
"reports_top_categories": "Top Categories",
```

- [ ] **Step 3: Check SectionHeader API**

`SectionHeader` is in `lib/widgets/common/section_header.dart`. Confirm its constructor:
```bash
grep -n "class SectionHeader\|required this\." lib/widgets/common/section_header.dart | head -10
```

If `onAction` is required and doesn't accept null, use an empty callback or remove the action:
```dart
SectionHeader(
  title: 'reports_top_categories'.tr(),
  actionLabel: '',
  onAction: () {},
),
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/screens/reports/reports_screen.dart
```

Fix any errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/reports/reports_screen.dart assets/i18n/ar.json assets/i18n/en.json
git commit -m "feat: ReportsScreen complete — stat row, 6-month bar chart, top categories"
```

---

## Task 5: Update task-master + final analysis

- [ ] **Step 1: Mark Phase 4 subtasks done**

```
task-master set-status --id=4.1 --status=done
task-master set-status --id=4.2 --status=done
task-master set-status --id=4.3 --status=done
task-master set-status --id=4.4 --status=done
task-master set-status --id=4.5 --status=done
task-master set-status --id=4 --status=done
```

- [ ] **Step 2: Run full project analysis**

```bash
flutter analyze lib/
```

Expected: no errors across all changed files.

- [ ] **Step 3: Verify Reports screen on device**

```bash
flutter run
```

Navigate to the Reports tab. Verify:
- Month selector chips scroll horizontally, current month pre-selected
- Tapping a different month triggers reload (loading shimmer briefly visible)
- 3-column stat row shows income (green) / expenses (red) / net (green or red)
- 6-month bar chart renders with correct month labels at bottom
- Top categories section shows up to 5 rows with emoji + name + amount + mini bar
- Dark mode: all colors use AppColors tokens correctly

---

## Self-Review Checklist

- [x] **Spec coverage:**
  - 4.1 search bar + FilterChips → Task 1 (TransactionFilters rewrite) ✓
  - 4.2 ListView itemExtent + pagination + pull-to-refresh → Task 2 steps 5,6 ✓
  - 4.3 shimmer + empty state → Task 2 steps 4, 7 ✓
  - 4.4 month selector + stat row → Task 3 ✓
  - 4.5 bar chart + top categories → Task 4 ✓
- [x] **No placeholders:** all steps have complete code blocks
- [x] **Type consistency:** `_MonthOption` defined in Task 3, used only there. `_ReportsContent` props match `_ReportsScreenState` fields exactly. `_TrendChart` receives `List<double>` trend and `List<String>` labels — both built in `_load()`.
- [x] **fl_chart API:** `BarChart`, `BarChartData`, `BarChartGroupData`, `BarChartRodData`, `FlTitlesData`, `AxisTitles`, `SideTitles`, `FlBorderData`, `FlGridData`, `BarTouchData` — all valid fl_chart 1.1.0 API.
- [x] **RTL:** `EdgeInsetsDirectional` used throughout, no `EdgeInsets.only(left/right)`.
