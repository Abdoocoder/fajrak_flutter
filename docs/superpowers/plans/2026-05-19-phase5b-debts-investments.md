# Phase 5B — Debts + Investments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align all Debts and Investments screens and widgets to the Fajrak design system by removing `colorScheme` props, replacing raw Flutter components with design-system equivalents, and applying canonical `AppColors`/`AppTypography`/`AppSpacing`/`AppRadius` tokens throughout.

**Architecture:** Same token-alignment pass as Phase 5A — no new components are created. Each file is cleaned independently so failures are isolated. Dialog confirms use `ConfirmDialog.show`. Loading states use `DashboardShimmer`. Empty states use the `EmptyState` widget. `LinearProgressIndicator` → `AppProgressBar`. `ElevatedButton`/`OutlinedButton` → `AppButton`.

**Tech Stack:** Flutter 3.x, easy_localization, Supabase, `lib/widgets/common/` shared components, `lib/core/theme/` tokens.

---

## Token Mapping (applies to every file below)

| Old | New |
|---|---|
| `colorScheme.primary` | `AppColors.primary` |
| `colorScheme.secondary` | `AppColors.accent` (simulator/investments) |
| `colorScheme.error` | `AppColors.expense` |
| `colorScheme.surface` | `isDark ? AppColors.surfaceDark : AppColors.surface` |
| `colorScheme.onSurface` | `isDark ? AppColors.textPrimaryDark : AppColors.textPrimary` |
| `colorScheme.onSurfaceVariant` | `isDark ? AppColors.textSecondaryDark : AppColors.textSecondary` |
| `colorScheme.outlineVariant` | `isDark ? AppColors.borderDark : AppColors.borderLight` |
| `colorScheme.surfaceContainerHighest` | `isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant` |
| `AppColors.success` | `AppColors.income` |
| `AppColors.error` | `AppColors.expense` |
| `AppColors.successLight` | `AppColors.income` |
| `AppColors.textMuted` | `AppColors.textTertiary` |
| `AppColors.surface0` | `isDark ? AppColors.surfaceDark : AppColors.surface` |
| `AppColors.surface2` | `isDark ? AppColors.borderDark : AppColors.borderLight` |
| `LinearProgressIndicator` | `AppProgressBar` |
| `ElevatedButton` | `AppButton(variant: AppButtonVariant.primary, ...)` |
| `OutlinedButton` | `AppButton(variant: AppButtonVariant.secondary, ...)` |
| `AlertDialog` (delete/confirm) | `ConfirmDialog.show(...)` |
| `PageSkeleton()` | `Padding(padding: EdgeInsets.all(AppSpacing.md), child: DashboardShimmer())` |
| `Colors.white` | `AppColors.textInverse` |
| `EdgeInsets.only(bottom: X)` | `EdgeInsetsDirectional.only(bottom: X)` |

---

## File Map

**Modify (no new files):**
- `lib/screens/debts/debts_screen.dart` — screen + `_ReceivableDebtCard`
- `lib/widgets/debts/debt_list_item.dart` — progress bar, payment button, tokens
- `lib/widgets/debts/debt_summary_section.dart` — stat cards, overall progress bar
- `lib/widgets/debts/paid_debt_item.dart` — token swap only
- `lib/widgets/debts/debt_celebration_dialog.dart` — ElevatedButton → AppButton
- `lib/widgets/debts/add_debt_dialog.dart` — ElevatedButton → AppButton, token swap
- `lib/screens/investments/investments_screen.dart` — screen + filter chips + dialogs
- `lib/widgets/investments/portfolio_summary_card.dart` — token swap
- `lib/widgets/investments/portfolio_chart_card.dart` — token swap
- `lib/widgets/investments/wealth_simulator_card.dart` — colorScheme.secondary → accent
- `lib/widgets/investments/investment_transaction_history.dart` — loading shimmer, tokens
- `lib/widgets/investments/investment_list_item.dart` — sell confirm dialog, tokens
- `lib/widgets/investments/investment_cash_card.dart` — ElevatedButton/OutlinedButton → AppButton
- `lib/widgets/investments/add_investment_dialog.dart` — ElevatedButton → AppButton, tokens

---

## Task 1: DebtsScreen + `_ReceivableDebtCard`

**Files:**
- Modify: `lib/screens/debts/debts_screen.dart`

- [ ] **Step 1: Update imports**

Replace:
```dart
import '../../utils/app_colors.dart';
import '../../widgets/common/skeleton_loader.dart';
```
With:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loader.dart';
```

- [ ] **Step 2: Replace `_buildPriorityColors` with a top-level constant**

Delete the entire top-level function:
```dart
List<Color> _buildPriorityColors(ColorScheme cs) => [
  cs.error,
  AppColors.warning,
  cs.primary,
  cs.onSurfaceVariant,
  cs.outlineVariant,
];
```

Replace with:
```dart
const _priorityColors = [
  AppColors.expense,
  AppColors.warning,
  AppColors.primary,
  AppColors.textSecondary,
  AppColors.borderLight,
];
```

- [ ] **Step 3: Update `_deleteDebt` — AlertDialog → ConfirmDialog**

Replace the entire `_deleteDebt` method body (the `showDialog` block):
```dart
Future<void> _deleteDebt(String id) async {
  await ConfirmDialog.show(
    context: context,
    title: 'debts_delete_title'.tr(),
    message: 'confirm_delete'.tr(),
    danger: true,
    onConfirm: () async {
      if (_saving) return;
      _saving = true;
      setState(() {});
      try {
        await Supabase.instance.client.from('debts').delete().eq('id', id);
        await _load();
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    },
  );
}
```

- [ ] **Step 4: Update `_receiveDebt` — AlertDialog → ConfirmDialog**

Replace the AlertDialog block in `_receiveDebt`:
```dart
Future<void> _receiveDebt(Map<String, dynamic> debt) async {
  await ConfirmDialog.show(
    context: context,
    title: 'debts_receive_btn'.tr(),
    message: '${'debts_tab_receivable'.tr()}: ${debt['name']}\n${(debt['remaining_amount'] as num).toStringAsFixed(0)} $_currency',
    danger: false,
    onConfirm: () async {
      if (_saving) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      _saving = true;
      setState(() {});
      try {
        await Supabase.instance.client
            .from('debts')
            .update({'is_paid': true})
            .eq('id', debt['id']);
        await Supabase.instance.client.from('transactions').insert({
          'user_id': user.id,
          'type': 'income',
          'amount': debt['remaining_amount'],
          'category': 'دين مستلم',
          'description': 'استلام دين: ${debt['name']}',
          'transaction_date': DateTime.now().toIso8601String().split('T')[0],
        });
        if (mounted) {
          _showCelebration(debt['name']);
          await _load();
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    },
  );
}
```

- [ ] **Step 5: Update `_showAddDialog` — bottom sheet background**

Replace the bottom sheet `backgroundColor` and remove the `cs` local:
```dart
void _showAddDialog({Map<String, dynamic>? existing, List<String>? labels}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final defaultLabels = [
    'priority_very_high'.tr(),
    'priority_high'.tr(),
    'priority_medium'.tr(),
    'priority_low'.tr(),
    'priority_deferred'.tr(),
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => AddDebtDialog(
      existing: existing,
      onSaved: _load,
      priorityColors: _priorityColors,
      priorityLabels: labels ?? defaultLabels,
      baseCurrency: _currency,
    ),
  );
}
```

- [ ] **Step 6: Rewrite `build` — Scaffold, AppBar, loading, refresh**

Replace the `build` method opening through the body:
```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

  final priorityLabels = [
    'priority_very_high'.tr(),
    'priority_high'.tr(),
    'priority_medium'.tr(),
    'priority_low'.tr(),
    'priority_deferred'.tr(),
  ];

  final totalRemaining = _debts.fold(0.0, (a, d) => a + (d['remaining_amount'] as num).toDouble());
  final totalOriginal  = _debts.fold(0.0, (a, d) => a + (d['original_amount'] as num).toDouble());
  final totalMonthly   = _debts.fold(0.0, (a, d) => a + (d['monthly_payment'] as num).toDouble());
  final totalReceivable = _receivableDebts.fold(0.0, (a, d) => a + (d['remaining_amount'] as num).toDouble());

  return Scaffold(
    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
    appBar: AppBar(
      backgroundColor: surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text('debts_title'.tr(), style: AppTypography.headingMd.copyWith(color: textPrimary)),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primary),
          tooltip: 'debts_add'.tr(),
          onPressed: () => _showAddDialog(labels: priorityLabels),
        ),
      ],
    ),
    body: _loading
        ? Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const DashboardShimmer(),
          )
        : RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  DebtSummarySection(
                    totalRemaining: totalRemaining,
                    totalOriginal: totalOriginal,
                    totalMonthly: totalMonthly,
                    currency: _currency,
                    lifeTimePaid: _totalPaidAmount,
                    paidCount: _paidDebts.length,
                  ),
```

- [ ] **Step 7: Replace alert chips section — remove cs.* tokens**

In the `_debtAlerts.map(...)` block, replace all `cs.*` references:
- `cs.primary` → `AppColors.primary`
- `cs.secondary` → `AppColors.income`
- `cs.error` → `AppColors.expense` (background + icon)
- `cs.onSurfaceVariant` → `textSecondary`

- [ ] **Step 8: Replace the "ديون عليّ" section header container**

Replace `cs.error` with `AppColors.expense` throughout the collapsible header container for `_debts`:
```dart
GestureDetector(
  onTap: () => setState(() => _showOwed = !_showOwed),
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.expense.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.expense.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.credit_card, size: 16, color: AppColors.expense),
        const SizedBox(width: 6),
        Expanded(
          child: Text('debts_tab_owed'.tr(),
              style: AppTypography.bodyMd.copyWith(color: AppColors.expense, fontWeight: FontWeight.w700)),
        ),
        if (!_showOwed)
          Text('${totalRemaining.toStringAsFixed(0)} $_currency',
              style: AppTypography.labelMd.copyWith(color: AppColors.expense, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${_debts.length}',
              style: AppTypography.labelSm.copyWith(color: AppColors.expense, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 6),
        Icon(_showOwed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.expense),
      ],
    ),
  ),
),
```

- [ ] **Step 9: Replace "ديون لي" section header — cs.primary → AppColors.primary**

Same pattern as Step 8 but all colors → `AppColors.primary`.

- [ ] **Step 10: Replace empty state Container with EmptyState widget**

```dart
if (_debts.isEmpty && _receivableDebts.isEmpty)
  EmptyState(
    icon: Icons.celebration_outlined,
    title: 'debts_no_active'.tr(),
    subtitle: '',
  ),
```

- [ ] **Step 11: Replace "paid debts" toggle container — cs.* → AppColors tokens**

```dart
GestureDetector(
  onTap: () => setState(() => _showPaid = !_showPaid),
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        Expanded(child: Text('debts_show_paid'.tr(),
            style: AppTypography.bodyMd.copyWith(color: textPrimary, fontWeight: FontWeight.w700))),
        Text('${_paidDebts.length}',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Icon(_showPaid ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: textSecondary),
      ],
    ),
  ),
),
```

- [ ] **Step 12: Replace `_ReceivableDebtCard.build` — all cs.* → AppColors tokens**

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  final amount = (debt['remaining_amount'] as num).toStringAsFixed(0);
  final dueDate = debt['due_date'] as String?;

  return Container(
    margin: const EdgeInsetsDirectional.only(bottom: 10),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: AppColors.primary, size: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Text(debt['name'] ?? '',
                  style: AppTypography.headingSm.copyWith(color: textPrimary)),
            ),
            Text('$amount $currency',
                style: AppTypography.headingSm.copyWith(color: AppColors.primary)),
          ],
        ),
        if (debt['notes'] != null && (debt['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(debt['notes'], style: AppTypography.bodySm.copyWith(color: textSecondary)),
        ],
        if (dueDate != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text("${'debts_due_date'.tr()}: $dueDate",
                  style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'debts_receive_btn'.tr(),
                variant: AppButtonVariant.secondary,
                onPressed: onReceive,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.expense, size: 18),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

Also add import for `app_button.dart` to `debts_screen.dart`:
```dart
import '../../widgets/common/app_button.dart';
```

- [ ] **Step 13: Analyze and commit**

```bash
flutter analyze lib/screens/debts/debts_screen.dart
```
Expected: `No issues found!`

```bash
git add lib/screens/debts/debts_screen.dart
git commit -m "refactor: Phase 5B — DebtsScreen token alignment + ConfirmDialog"
```

---

## Task 2: DebtListItem

**Files:**
- Modify: `lib/widgets/debts/debt_list_item.dart`

- [ ] **Step 1: Update imports**

Replace `import '../../utils/app_colors.dart';` with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';
```

- [ ] **Step 2: Replace card container — cs.* tokens**

In `_DebtListItemState.build`, remove `final theme = Theme.of(context);` and `final cs = theme.colorScheme;`. Add:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
final border = isDark ? AppColors.borderDark : AppColors.borderLight;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
```

Card outer decoration:
```dart
decoration: BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(color: border),
),
```

- [ ] **Step 3: Replace all AppColors.error → AppColors.expense and AppColors.success → AppColors.income**

Replace all occurrences (use replace_all):
- `AppColors.error` → `AppColors.expense` (overdue badge bg/text, remaining amount, delete button)
- `AppColors.success` → `AppColors.income` (pay button bg, pay button border, progress fill)
- `AppColors.successLight` → `AppColors.income` (pay button label text)
- `AppColors.textMuted` → `AppColors.textTertiary` (exchange rate hint)

- [ ] **Step 4: Replace `LinearProgressIndicator` with `AppProgressBar`**

Remove:
```dart
Semantics(
  value: '${pct.toStringAsFixed(0)}%',
  child: ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: LinearProgressIndicator(
      value: (pct / 100).clamp(0.0, 1.0),
      backgroundColor: cs.outlineVariant,
      color: AppColors.success,
      minHeight: 8,
    ),
  ),
),
```

Replace with:
```dart
AppProgressBar(
  value: (pct / 100).clamp(0.0, 1.0),
  title: '',
  percentageLabel: '${pct.toStringAsFixed(0)}%',
  variant: ProgressBarVariant.goal,
),
```

Keep the custom badge Row below the bar (payment day, due date chips) unchanged.

- [ ] **Step 5: Replace cs.onSurface/onSurfaceVariant/surfaceContainerHigh in payment TextField**

```dart
style: TextStyle(color: textPrimary, fontSize: 13),
decoration: InputDecoration(
  hintText: 'trans_amount'.tr(),
  hintStyle: TextStyle(color: textSecondary),
  filled: true,
  fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
),
```

DropdownButton:
```dart
dropdownColor: surface,
style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
```

Close button in payment row:
```dart
decoration: BoxDecoration(
  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
  borderRadius: BorderRadius.circular(8),
),
child: Icon(Icons.close, color: textSecondary, size: 14),
```

- [ ] **Step 6: Replace `Colors.white` in pay confirm button**

```dart
child: _payingSaving
    ? const SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse),
      )
    : const Icon(Icons.check, color: AppColors.textInverse, size: 14),
```

- [ ] **Step 7: Replace cs.onSurfaceVariant in label/badge row below the bar**

```dart
Text(
  'debts_paid_pct'.tr(args: [pct.toStringAsFixed(0)]),
  style: AppTypography.labelSm.copyWith(color: textSecondary),
),
```

Monthly payment label:
```dart
style: AppTypography.labelSm.copyWith(color: textSecondary),
```

- [ ] **Step 8: Analyze and commit**

```bash
flutter analyze lib/widgets/debts/debt_list_item.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/debts/debt_list_item.dart
git commit -m "refactor: Phase 5B — DebtListItem token alignment + AppProgressBar"
```

---

## Task 3: Debt sub-widgets (DebtSummarySection, PaidDebtItem, DebtCelebrationDialog)

**Files:**
- Modify: `lib/widgets/debts/debt_summary_section.dart`
- Modify: `lib/widgets/debts/paid_debt_item.dart`
- Modify: `lib/widgets/debts/debt_celebration_dialog.dart`

### debt_summary_section.dart

- [ ] **Step 1: Update imports**

Replace `import '../../utils/app_colors.dart';` with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';
```

- [ ] **Step 2: Remove `cs` from `_statCard` helper — use `isDark` local**

Change the signature:
```dart
Widget _statCard(String label, String value, Color color, {required bool isDark}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
    ),
    child: Column(
      children: [
        Text(value, style: AppTypography.headingMd.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSm.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ), textAlign: TextAlign.center),
      ],
    ),
  );
}
```

- [ ] **Step 3: Rewrite `build` — replace all cs.* and AppColors.error/success aliases**

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  final paidPct = totalOriginal > 0
      ? ((totalOriginal - totalRemaining) / totalOriginal * 100)
      : 0.0;

  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _statCard('debts_total_remaining'.tr(),
              '${totalRemaining.toStringAsFixed(0)} $currency', AppColors.expense, isDark: isDark)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('debts_paid'.tr(),
              '${paidPct.toStringAsFixed(0)}%', AppColors.income, isDark: isDark)),
          const SizedBox(width: 8),
          Expanded(child: _statCard('debts_monthly_total'.tr(),
              '${totalMonthly.toStringAsFixed(0)} $currency', AppColors.warning, isDark: isDark)),
        ],
      ),
      const SizedBox(height: 12),

      if (lifeTimePaid > 0)
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsetsDirectional.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.income.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 28, color: AppColors.income),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('debts_total_paid_life'.tr(),
                      style: AppTypography.labelSm.copyWith(color: textSecondary)),
                  Text('${lifeTimePaid.toStringAsFixed(0)} $currency',
                      style: AppTypography.headingMd.copyWith(color: AppColors.income)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('debts_paid_count'.tr(),
                      style: AppTypography.labelSm.copyWith(color: textSecondary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$paidCount ',
                          style: AppTypography.headingSm.copyWith(color: AppColors.income)),
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.income),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsetsDirectional.only(bottom: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('debts_overall_progress'.tr(),
                    style: AppTypography.labelSm.copyWith(color: textSecondary, fontWeight: FontWeight.w700)),
                Text('${paidPct.toStringAsFixed(1)}%',
                    style: AppTypography.labelSm.copyWith(color: AppColors.income, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 8),
            AppProgressBar(
              value: (paidPct / 100).clamp(0.0, 1.0),
              title: '',
              percentageLabel: '${paidPct.toStringAsFixed(0)}%',
              variant: ProgressBarVariant.goal,
              infoStart: 'debts_paid_amount'.tr(args: [(totalOriginal - totalRemaining).toStringAsFixed(0), currency]),
              infoEnd: 'debts_original_amount_label'.tr(args: [totalOriginal.toStringAsFixed(0), currency]),
            ),
          ],
        ),
      ),
    ],
  );
}
```

### paid_debt_item.dart

- [ ] **Step 4: Full rewrite**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PaidDebtItem extends StatelessWidget {
  final Map<String, dynamic> debt;
  final String currency;

  const PaidDebtItem({super.key, required this.debt, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 24, color: AppColors.income),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt['name'] ?? '',
                  style: AppTypography.bodyMd.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (debt['updated_at'] != null)
                  Text(
                    debt['updated_at'].toString().substring(0, 10),
                    style: AppTypography.labelSm.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${(debt['original_amount'] as num).toStringAsFixed(0)} $currency',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.income,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
```

### debt_celebration_dialog.dart

- [ ] **Step 5: Replace ElevatedButton and Colors.white**

Replace `Colors.white` title text color → `AppColors.textInverse`.

Replace the `ElevatedButton` at the bottom:
```dart
AppButton(
  label: 'debts_celebration_btn'.tr(),
  variant: AppButtonVariant.primary,
  onPressed: () => Navigator.pop(context),
),
```

Add import:
```dart
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
```

The dialog background stays as `const Color(0xFF0F1629)` (maps to `AppColors.surface0` — exact match).
Optionally swap: `backgroundColor: AppColors.surface0`.

- [ ] **Step 6: Analyze all three and commit**

```bash
flutter analyze lib/widgets/debts/debt_summary_section.dart lib/widgets/debts/paid_debt_item.dart lib/widgets/debts/debt_celebration_dialog.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/debts/debt_summary_section.dart lib/widgets/debts/paid_debt_item.dart lib/widgets/debts/debt_celebration_dialog.dart
git commit -m "refactor: Phase 5B — debt sub-widgets token alignment"
```

---

## Task 4: AddDebtDialog

**Files:**
- Modify: `lib/widgets/debts/add_debt_dialog.dart`

- [ ] **Step 1: Update imports**

Replace `import '../../utils/app_colors.dart';` (if present) with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
```

- [ ] **Step 2: Replace all `colorScheme.*` tokens**

Find every `final cs = Theme.of(context).colorScheme;` or `final colorScheme = Theme.of(context).colorScheme;` block and replace the variable with an `isDark` local:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
final border = isDark ? AppColors.borderDark : AppColors.borderLight;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
```

Then replace all downstream `cs.*` / `colorScheme.*` refs with the matching local var or `AppColors.*` token per the token mapping table.

- [ ] **Step 3: Replace ElevatedButton (line ~772)**

Find:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: ...,
    foregroundColor: Colors.white,
    ...
  ),
  onPressed: ...,
  child: Text(...),
),
```

Replace with:
```dart
AppButton(
  label: 'save'.tr(),   // or whichever label key the dialog uses
  variant: AppButtonVariant.primary,
  onPressed: _saving ? null : _save,
  isLoading: _saving,
),
```

- [ ] **Step 4: Analyze and commit**

```bash
flutter analyze lib/widgets/debts/add_debt_dialog.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/debts/add_debt_dialog.dart
git commit -m "refactor: Phase 5B — AddDebtDialog token alignment + AppButton"
```

---

## Task 5: InvestmentsScreen

**Files:**
- Modify: `lib/screens/investments/investments_screen.dart`

- [ ] **Step 1: Update imports**

Replace `import '../../widgets/common/skeleton_loader.dart';` with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/filter_chips.dart';
import '../../widgets/common/shimmer_loader.dart';
```

Remove any existing `import '../../utils/app_colors.dart';`.

- [ ] **Step 2: Replace `_deleteInvestment` — AlertDialog → ConfirmDialog**

```dart
Future<void> _deleteInvestment(String id) async {
  await ConfirmDialog.show(
    context: context,
    title: 'inv_delete_title'.tr(),
    message: 'confirm_delete'.tr(),
    danger: true,
    onConfirm: () async {
      if (_saving) return;
      _saving = true;
      setState(() {});
      try {
        await Supabase.instance.client.from('investments').delete().eq('id', id);
        await _load();
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    },
  );
}
```

- [ ] **Step 3: Update `_showAddDialog` bottom sheet background**

```dart
void _showAddDialog() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => AddInvestmentDialog(onSaved: () => _load()),
  );
}
```

- [ ] **Step 4: Rewrite `build` — Scaffold, AppBar, loading, empty state**

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

  return Scaffold(
    backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
    appBar: AppBar(
      backgroundColor: surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text('inv_title'.tr(), style: AppTypography.headingMd.copyWith(color: textPrimary)),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      actions: [
        GestureDetector(
          onTap: () => setState(() => _showInUsd = !_showInUsd),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Text(
              _showInUsd ? 'inv_currency_usd'.tr() : _currency,
              style: AppTypography.labelSm.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primary),
          tooltip: 'inv_refresh'.tr(),
          onPressed: () async {
            setState(() => _loading = true);
            await _load(refreshPrices: true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primary),
          tooltip: 'inv_add'.tr(),
          onPressed: _showAddDialog,
        ),
      ],
    ),
    body: _loading
        ? Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const DashboardShimmer(),
          )
        : RefreshIndicator(
            onRefresh: () => _load(refreshPrices: true),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(children: [ /* see Step 5 */ ]),
            ),
          ),
  );
}
```

- [ ] **Step 5: Replace empty state and filter chips in the Column children**

Empty state (replaces the old Container):
```dart
if (_investments.isEmpty)
  EmptyState(
    icon: Icons.show_chart,
    title: 'inv_empty'.tr(),
    subtitle: '',
    ctaLabel: 'inv_add_first'.tr(),
    onCta: _showAddDialog,
  )
```

Filter chips (replaces the custom horizontal Row):
```dart
// Build label ↔ key mapping
final filterKeys = ['all', 'halal', 'crypto', 'stocks'];
final filterLabels = filterKeys.map((f) => 'inv_filter_$f'.tr()).toList();

AppFilterChips(
  options: filterLabels,
  selected: filterLabels[filterKeys.indexOf(_filterType)],
  onSelected: (label) {
    final idx = filterLabels.indexOf(label);
    if (idx >= 0) setState(() => _filterType = filterKeys[idx]);
  },
  padding: EdgeInsets.zero,
),
```

Sort popup `color` → `surface`:
```dart
PopupMenuButton<String>(
  color: surface,
  ...
)
```

Portfolio count label → `AppTypography.headingSm.copyWith(color: textPrimary)`.

Sort toggle container colors → `surfaceVariant` / `border` / `textSecondary`.

Halal tip box at bottom:
```dart
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
  ),
  child: Row(
    children: [
      const Icon(Icons.mosque, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text('inv_halal_tip'.tr(),
          style: AppTypography.bodySm.copyWith(color: textSecondary))),
    ],
  ),
),
```

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze lib/screens/investments/investments_screen.dart
```
Expected: `No issues found!`

```bash
git add lib/screens/investments/investments_screen.dart
git commit -m "refactor: Phase 5B — InvestmentsScreen token alignment + ConfirmDialog + AppFilterChips"
```

---

## Task 6: Portfolio display widgets (4 files)

**Files:**
- Modify: `lib/widgets/investments/portfolio_summary_card.dart`
- Modify: `lib/widgets/investments/portfolio_chart_card.dart`
- Modify: `lib/widgets/investments/wealth_simulator_card.dart`
- Modify: `lib/widgets/investments/investment_transaction_history.dart`

### portfolio_summary_card.dart

- [ ] **Step 1: Rewrite — remove colorScheme, add AppColors + AppTypography**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double totalCost;
  final bool showInUsd;
  final double jodRate;
  final int assetsCount;
  final int halalCount;

  const PortfolioSummaryCard({
    super.key,
    required this.totalValue,
    required this.totalCost,
    required this.showInUsd,
    required this.jodRate,
    required this.assetsCount,
    required this.halalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final gain = totalValue - totalCost;
    final gainPct = totalCost > 0 ? (gain / totalCost * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.15),
        ]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('inv_total_value'.tr(),
              style: AppTypography.labelMd.copyWith(color: textSecondary)),
          const SizedBox(height: 8),
          Text(
            showInUsd
                ? '\$${totalValue.toStringAsFixed(2)}'
                : '${(totalValue * jodRate).toStringAsFixed(2)} JOD',
            style: AppTypography.displaySmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gain >= 0 ? Icons.trending_up : Icons.trending_down,
                color: gain >= 0 ? AppColors.income : AppColors.expense,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${gain >= 0 ? '+' : ''}\$${gain.toStringAsFixed(2)} (${gainPct.toStringAsFixed(1)}%)',
                style: AppTypography.labelMd.copyWith(
                  color: gain >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('inv_cost'.tr(), '\$${totalCost.toStringAsFixed(0)}', textSecondary),
              _miniStat('inv_assets'.tr(), '$assetsCount', AppColors.primary),
              _miniStat('inv_halal'.tr(), '$halalCount', AppColors.income),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.headingSm.copyWith(color: color)),
        Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
```

### portfolio_chart_card.dart

- [ ] **Step 2: Replace legacy surface tokens and colorScheme refs**

Replace imports:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
```

Update `_colors` list (keep `AppColors.purple` and `AppColors.cyan` as-is — they are chart-palette colors):
```dart
static const List<Color> _colors = [
  AppColors.primary,
  AppColors.income,    // was AppColors.success
  AppColors.warning,
  AppColors.purple,
  AppColors.expense,   // was AppColors.error
];
```

In `build`:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
final border = isDark ? AppColors.borderDark : AppColors.borderLight;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
```

Card container:
```dart
decoration: BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: border),
),
```

Title: `AppTypography.labelMd.copyWith(color: textPrimary, fontWeight: FontWeight.w900)`.

Bar divider `colorScheme.surface` → `surface`.

Legend rows: `colorScheme.onSurface` → `textPrimary`, `colorScheme.onSurfaceVariant` → `textSecondary`.

### wealth_simulator_card.dart

- [ ] **Step 3: Replace colorScheme.secondary → AppColors.accent throughout**

```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
```

In `build`:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
final border = isDark ? AppColors.borderDark : AppColors.borderLight;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
```

Toggle header:
```dart
decoration: BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
),
```

Expanded content box:
```dart
decoration: BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: border),
),
```

Result highlight box:
```dart
decoration: BoxDecoration(
  color: AppColors.accent.withValues(alpha: 0.1),
  borderRadius: BorderRadius.circular(AppRadius.sm),
  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
),
```

Result value text:
```dart
Text('${fv.toStringAsFixed(0)} ${widget.currency}',
    style: AppTypography.displayMedium.copyWith(color: AppColors.accent)),
```

Sliders: `activeColor: AppColors.accent`, `inactiveColor: border`.

In `_slider` helper, replace `final colorScheme = Theme.of(context).colorScheme;` with:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
```

### investment_transaction_history.dart

- [ ] **Step 4: Replace loading spinner with DashboardShimmer + fix all cs.* tokens**

Replace import, add:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../common/shimmer_loader.dart';
```

Loading state:
```dart
if (_loading) {
  return const Padding(
    padding: EdgeInsets.all(20),
    child: DashboardShimmer(),
  );
}
```

In `build`, add `isDark` locals. Replace all `Theme.of(context).colorScheme.*` calls:
- `colorScheme.outlineVariant` → `isDark ? AppColors.borderDark : AppColors.borderLight`
- `colorScheme.onSurface` → `isDark ? AppColors.textPrimaryDark : AppColors.textPrimary`
- `colorScheme.onSurfaceVariant` → `isDark ? AppColors.textSecondaryDark : AppColors.textSecondary`
- `colorScheme.surfaceContainerHighest` → `isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant`

Drag handle:
```dart
color: isDark ? AppColors.borderDark : AppColors.borderLight,
```

Title: `AppTypography.headingMd.copyWith(color: textPrimary)`.

Simplify redundant ternary in list builder:
```dart
final color = isBuy ? AppColors.income : AppColors.expense;
```

- [ ] **Step 5: Analyze all four and commit**

```bash
flutter analyze lib/widgets/investments/portfolio_summary_card.dart lib/widgets/investments/portfolio_chart_card.dart lib/widgets/investments/wealth_simulator_card.dart lib/widgets/investments/investment_transaction_history.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/investments/portfolio_summary_card.dart lib/widgets/investments/portfolio_chart_card.dart lib/widgets/investments/wealth_simulator_card.dart lib/widgets/investments/investment_transaction_history.dart
git commit -m "refactor: Phase 5B — portfolio display widgets token alignment"
```

---

## Task 7: InvestmentListItem

**Files:**
- Modify: `lib/widgets/investments/investment_list_item.dart`

- [ ] **Step 1: Update imports**

```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
```

Remove `import '../../utils/app_colors.dart';`.

- [ ] **Step 2: Update bottom sheet `backgroundColor` in `_showAddDialog` and `_showTxHistory`**

Both use `Theme.of(context).colorScheme.surface`. Replace with:
```dart
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColors.surfaceDark
    : AppColors.surface,
```

- [ ] **Step 3: Replace sell confirm — keep AlertDialog but clean tokens**

The sell summary dialog has a custom table, so keep `AlertDialog` (not `ConfirmDialog`). Replace all `colorScheme.*` refs inside it:

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (ctx) {
    final isDark = ctx.findAncestorWidgetOfExactType<MaterialApp>() != null
        ? Theme.of(ctx).brightness == Brightness.dark : false;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: Text('inv_sell_confirm_btn'.tr(),
          style: AppTypography.headingMd.copyWith(color: textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _summaryRow(ctx, 'inv_sell_avg_buy'.tr(), '\$${avgBuyPrice.toStringAsFixed(2)}', textSecondary),
          const SizedBox(height: 8),
          _summaryRow(ctx, 'inv_price'.tr(), '\$${price.toStringAsFixed(2)}', textSecondary),
          const SizedBox(height: 8),
          _summaryRow(ctx, 'inv_sell_proceeds'.tr(), '\$${proceeds.toStringAsFixed(2)}', textPrimary),
          const Divider(height: 20),
          _summaryRow(
            ctx,
            isGain ? 'inv_sell_realized_gain'.tr() : 'inv_sell_realized_loss'.tr(),
            '${isGain ? '+' : ''}\$${realizedPnl.toStringAsFixed(2)}',
            isGain ? AppColors.income : AppColors.expense,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('inv_cancel'.tr(), style: TextStyle(color: textSecondary)),
        ),
        AppButton(
          label: 'inv_sell_confirm_btn'.tr(),
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.pop(ctx, true),
          fullWidth: false,
        ),
      ],
    );
  },
);
```

- [ ] **Step 4: Replace AppColors.success/error in `_summaryRow` calls and mini fields**

- `AppColors.success` → `AppColors.income`
- `AppColors.error` → `AppColors.expense`
- `Colors.white` (in old sell ElevatedButton) → removed (now uses AppButton)

`_miniField` fill color:
```dart
fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
```
`_miniField` style:
```dart
style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary, fontSize: 12),
```

- [ ] **Step 5: Rewrite card container in `build`**

Add `isDark` locals in `build`. Replace card container:
```dart
return Container(
  margin: const EdgeInsetsDirectional.only(bottom: 10),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: isDark ? AppColors.surfaceDark : AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
  ),
  ...
```

Icon circle:
```dart
decoration: BoxDecoration(
  color: AppColors.primary.withValues(alpha: 0.1),
  borderRadius: BorderRadius.circular(AppRadius.sm),
),
```

Symbol initial letter: `color: AppColors.primary`, `AppTypography.headingMd`.

- [ ] **Step 6: Analyze and commit**

```bash
flutter analyze lib/widgets/investments/investment_list_item.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/investments/investment_list_item.dart
git commit -m "refactor: Phase 5B — InvestmentListItem token alignment"
```

---

## Task 8: InvestmentCashCard + AddInvestmentDialog

**Files:**
- Modify: `lib/widgets/investments/investment_cash_card.dart`
- Modify: `lib/widgets/investments/add_investment_dialog.dart`

### investment_cash_card.dart

- [ ] **Step 1: Update imports**

```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
```

- [ ] **Step 2: Update `_showTransferDialog` — bottom sheet background + drag handle**

```dart
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColors.surfaceDark : AppColors.surface,
```

Drag handle inside modal:
```dart
color: Theme.of(ctx).brightness == Brightness.dark
    ? AppColors.borderDark : AppColors.borderLight,
```

All `Theme.of(ctx).colorScheme.*` inside `StatefulBuilder` → resolve with `ctx.brightness` local.

- [ ] **Step 3: Replace `ElevatedButton` → `AppButton` in modal**

```dart
AppButton(
  label: 'inv_cash_transfer_confirm'.tr(),
  variant: AppButtonVariant.primary,
  onPressed: _transferring ? null : () => _doTransfer(ctx, setModalState),
  isLoading: _transferring,
),
```

- [ ] **Step 4: Replace `AppColors.success` → `AppColors.income` throughout**

All balance amount text, border, badge: `AppColors.success` → `AppColors.income`.

SnackBar background: `backgroundColor: AppColors.income`.

- [ ] **Step 5: Replace `OutlinedButton.icon` → `AppButton`**

```dart
AppButton(
  label: 'inv_cash_transfer_btn'.tr(),
  variant: AppButtonVariant.secondary,
  icon: Icons.arrow_forward,
  onPressed: _showTransferDialog,
),
```

- [ ] **Step 6: Replace card container colorScheme refs**

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
final border = isDark ? AppColors.borderDark : AppColors.borderLight;
final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
```

Card:
```dart
decoration: BoxDecoration(
  color: surface,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  border: Border.all(
    color: hasBalance ? AppColors.income.withValues(alpha: 0.3) : border,
  ),
),
```

Title: `AppTypography.labelLg.copyWith(color: textPrimary, fontWeight: FontWeight.w900)`.

### add_investment_dialog.dart

- [ ] **Step 7: Update imports and token-swap all colorScheme refs**

Add imports:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
```

All `colorScheme.*` → AppColors tokens via the same pattern. In each method that reads the colorScheme, add an `isDark` local instead.

- [ ] **Step 8: Replace ElevatedButton (line ~341)**

```dart
AppButton(
  label: 'save'.tr(),
  variant: AppButtonVariant.primary,
  isLoading: _saving,
  onPressed: _saving ? null : _save,
),
```

All `Colors.white` in foregroundColor → remove (AppButton handles foreground internally).

- [ ] **Step 9: Analyze both and commit**

```bash
flutter analyze lib/widgets/investments/investment_cash_card.dart lib/widgets/investments/add_investment_dialog.dart
```
Expected: `No issues found!`

```bash
git add lib/widgets/investments/investment_cash_card.dart lib/widgets/investments/add_investment_dialog.dart
git commit -m "refactor: Phase 5B — InvestmentCashCard + AddInvestmentDialog token alignment + AppButton"
```

---

## Final Verification

- [ ] **Full analyze**

```bash
flutter analyze lib/screens/debts/ lib/widgets/debts/ lib/screens/investments/ lib/widgets/investments/
```
Expected: `No issues found!`

---

## Self-Review

**Spec coverage:** All 13 files addressed across 8 tasks. Each task is independently committable.

**Placeholder scan:** No TBD or "similar to task N" present. All code shown explicitly.

**Type consistency:**
- `AppColors.income` used for all success/green states throughout (not mixed with `AppColors.success`)
- `AppColors.expense` used for all error/red states (not mixed with `AppColors.error`)  
- `AppColors.accent` used for `colorScheme.secondary` in investments/simulator context
- `AppProgressBar` import path: `'../common/progress_bar.dart'` (from widgets/) or `'../../widgets/common/progress_bar.dart'` (from screens/)
- `DashboardShimmer` — no `const` constructor in widget files that are not const-safe; use `const` only where enclosing scope is const

**Note on `AppSpacing.cardPadding`:** Used in `PortfolioSummaryCard` — verify this constant exists in `app_spacing.dart`. If not, use `20.0` directly.
