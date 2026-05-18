# Phase 3: Dashboard Redesign — Design Spec

## Goal

Replace the current dashboard (15+ widgets, DashboardLayoutProvider, GlassPanel) with the
Header Overlap pattern from the Fajrak design system: a focused 4-section screen — header,
BalanceCard, BudgetProgressCard, and recent transactions — with no gamification widgets.

---

## Architecture

The dashboard follows the **Header Overlap** pattern: a primary-blue AppBar painted behind a
`CustomScrollView` with a `SliverAppBar` (pinned), and a `BalanceCard` that visually overlaps
the app bar by −18 dp via negative top margin inside the first sliver. All data loading stays
in `_DashboardScreenState`; the three content widgets are stateless and receive their data
via constructor.

`DashboardLayoutProvider` and `_DashCardSelector` are deleted entirely. No customiser, no
toggleable cards.

---

## Sections (top to bottom)

### 1. Sliver App Bar (Header)

- Background: `AppColors.primary` (#1A5F8A)
- Text colour: `AppColors.textInverse` (white) for name, `rgba(255,255,255,0.70)` for date
- Greeting: "مرحباً {name} / Hello {name}" — `AppTypography.headingMd`, textInverse
- Date: `DateFormat('EEEE، d MMMM yyyy', 'ar').format(now)` — `AppTypography.bodySm`, 70% white
- Two action icons (notifications bell + future use), both 22 px, textInverse
- `pinned: true`, `expandedHeight: 96`, `collapsedHeight: 56`, elevation: 0, no `surfaceTintColor`

### 2. BalanceCard (`lib/widgets/dashboard/balance_card.dart` — NEW)

New stateful widget. Sits inside a `SliverToBoxAdapter` with `EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0)` and a `Transform.translate(offset: Offset(0, -18))` to create the overlap.

**Props:** `net` (double), `income` (double), `expenses` (double), `currency` (String)

**Layout (inside `AppCard` standard variant):**
- Label row: `AppTypography.labelSm`, `AppColors.textSecondary` — "رصيدك هذا الشهر / Your balance this month"
- Amount row: `AppTypography.displayLarge` (40/700/LS-2.0), `AppColors.primary` — animated count-up
  - Negative net → `AppColors.expense` colour + ⚠️ `Icon(Icons.warning_amber_rounded, 18)` before amount
  - Suffix: currency code in `AppTypography.headingMd`, `AppColors.textSecondary`
- 1 px `Divider` (`AppColors.borderLight`)
- Income/expense row: two `Expanded` columns
  - Income: ↑ icon (`AppColors.income`), `AppTypography.labelSm` label, `AppTypography.currency` amount in `AppColors.income`
  - Expense: ↓ icon (`AppColors.expense`), `AppTypography.labelSm` label, `AppTypography.currency` amount in `AppColors.expense`

**Count-up animation:**
- `AnimationController` duration 600 ms, curve `Cubic(0.25, 1, 0.5, 1)` (easeOutQuart)
- `Tween<double>(begin: 0, end: net).animate(...)`
- `initState` → `controller.forward()`; rebuild on new `net` via `didUpdateWidget` (reset + forward)
- Always respects `MediaQuery.disableAnimations` → skip to final value

**Negative state:** `AppCard` border switches to `AppColors.expense` (`BorderSide(color: AppColors.expense, width: 1.5)`)

### 3. BudgetProgressCard (`lib/widgets/dashboard/budget_progress_card.dart` — REWRITE)

Simplified card: shows total monthly spend vs income as a single horizontal progress bar.
Full per-category budgets belong to Phase 4 (Budgets screen); this card is a summary teaser.

**Props:** `income` (double), `expenses` (double), `currency` (String)

**Layout (inside `AppCard` tight variant):**
- `SectionHeader`-style row: title "الميزانية الشهرية / Monthly Budget" (`AppTypography.headingSm`), action "الكل ← / See all" in `AppColors.primary` → navigates to tab index 2 (Reports, placeholder for now)
- `AppProgressBar` (budget variant, gradient) showing `fraction = (expenses/income).clamp(0,1)`
  - Label row above: `AppTypography.labelSm` title (empty — bar label is implicit), percentage chip `${(fraction*100).round()}%`
  - Info row below: remaining = income − expenses, `AppTypography.bodySm`, `AppColors.textSecondary`
- If `income == 0`: show `EmptyState` with `Icons.account_balance_wallet_outlined`, "لا توجد بيانات / No data"

**Colour logic:**
- `fraction < 0.7` → budget variant (primary→accent gradient)
- `0.7 ≤ fraction < 0.9` → override fill to `AppColors.warning`
- `fraction ≥ 0.9` → override fill to `AppColors.expense`

### 4. Recent Transactions

Two sub-widgets reused from Phase 1:

**Section header** (`AppSectionHeader`):
- Title: "آخر المعاملات / Recent Transactions"
- Action: "الكل ← / See all" → `onTabSelected(1)` via `MainScreen` callback

The dashboard needs access to `onTabSelected`. Pass it down: `DashboardScreen` receives `onSwitchTab` (type `ValueChanged<int>`) from `MainScreen`.

**Transaction list** (inside `AppCard` standard variant, no padding override):
- `ListView.builder` with `itemExtent: 68`, `shrinkWrap: true`, `physics: NeverScrollableScrollPhysics()`
- Shows last 3 items from `_recentTx` (already limited to 5 in the query — take `sublist(0, min(3, length))`)
- Uses `TransactionListItem` from Phase 1 (no stagger on dashboard — stagger is first-load only on list screens)
- If empty: `EmptyState` with `Icons.receipt_long_outlined`, "لا توجد معاملات / No transactions yet"

---

## Data Loading

Keep existing `_load()` + `_loadPhase2()` structure. Remove unused fields:
- Keep: `_income`, `_expenses`, `_net`, `_currency`, `_name`, `_recentTx`, `_loading`, `_hasError`
- Remove: `_healthScore`, `_stage`, `_totalDebt`, `_totalReceivable`, `_netWorth`, `_invValue`, `_goalsSaved`, `_goalsTarget`, `_prevIncome`, `_prevExpenses`, `_months6Data`, `_categoryData`, `_monthlyDebtCommitments`, `_totalAccountsBalance`, `_accounts`, `_accountsLoading`, `_saving`, `_lastUpdated`, `_foodSpending`, `_entertainmentSpending`
- Simplify `_loadPhase2()`: drop the parallel futures for debts, goals, chartsList, previous-month txs, `FinanceService.fetchFinancialDashboard`, `CurrencyService.fetchExchangeRate`; keep only profile + `FinanceService.fetchMonthlyFinancialSummary` + recent txs

**Transaction version watch:** Keep `_loadedTransactionVersion` + `txVersion` select in `build()` to reload on FAB save.

---

## Files Changed

| File | Action |
|---|---|
| `lib/screens/dashboard/dashboard_screen.dart` | Full rewrite |
| `lib/widgets/dashboard/balance_card.dart` | Create new |
| `lib/widgets/dashboard/budget_progress_card.dart` | Rewrite |
| `lib/widgets/dashboard/dashboard_header.dart` | Delete (replaced by SliverAppBar inline) |
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
| `lib/screens/main_screen.dart` | Change `_screens` from `static const List<Widget>` to a `List<Widget>` getter that passes `_switchTab` to `DashboardScreen` |

---

## Error State

Full-screen centered column:
- `Icon(Icons.error_outline, 48, AppColors.textTertiary)`
- `Text('error_generic'.tr())` — `AppTypography.headingMd`, `AppColors.textPrimary`
- `AppButton` primary — `'retry'.tr()` → `_load()`

---

## Shimmer Loading

Show `DashboardShimmer` (from Phase 1 `shimmer_loader.dart`) while `_loading == true`.
Replace the current `PageSkeleton` / `CardSkeleton` mix.

---

## Quality Gates

- [ ] No `GlassPanel`, no `DashboardLayoutProvider`, no `_DashCardSelector` remaining
- [ ] All amounts use `AppTypography.currency` or `currencyLarge` with tabular figures
- [ ] Text on primary-blue header uses `AppColors.textInverse`, not `textSecondary`
- [ ] Count-up skips to final value when `MediaQuery.disableAnimations == true`
- [ ] Dark mode tested: balance card, progress bar, header all render correctly
- [ ] `EdgeInsetsDirectional` everywhere — no `EdgeInsets.only(left/right)`
- [ ] BalanceCard negative state: border switches to `AppColors.expense`
- [ ] "See all" on recent transactions navigates to Transactions tab (index 1)
