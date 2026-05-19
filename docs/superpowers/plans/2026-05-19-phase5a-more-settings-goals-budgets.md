# Phase 5A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align More, Settings, Goals, and Budgets screens with the Fajrak design system — remove all `colorScheme` props from display widgets, swap raw Flutter components for token-based design-system equivalents.

**Architecture:** Pure refactoring — no new logic, no new Supabase calls, no new routes. External widget constructor APIs stay the same except removing the `colorScheme` named parameter. All callers are updated in the same commit as the widget.

**Tech Stack:** Flutter 3.x, `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` (core theme), `AppProgressBar`, `AppFilterChips`, `DashboardShimmer`, `EmptyState`, `AppButton`, `ConfirmDialog`, `SectionHeader`.

---

## Token quick-reference (applies to every file below)

| Old | New |
|-----|-----|
| `colorScheme.primary` | `AppColors.primary` |
| `colorScheme.secondary` (goals saved) | `AppColors.income` |
| `colorScheme.secondary` (budget wants) | `AppColors.accent` |
| `colorScheme.surface` | `isDark ? AppColors.surfaceDark : AppColors.surface` |
| `colorScheme.onSurface` | `isDark ? AppColors.textPrimaryDark : AppColors.textPrimary` |
| `colorScheme.onSurfaceVariant` | `isDark ? AppColors.textSecondaryDark : AppColors.textSecondary` |
| `colorScheme.outlineVariant` | `isDark ? AppColors.borderDark : AppColors.borderLight` |
| `colorScheme.error` | `AppColors.expense` |
| `AppColors.error` | `AppColors.expense` |
| `AppColors.success` | `AppColors.income` |
| `AppColors.errorLight` | `AppColors.expense` |
| `AppColors.successLight` | `AppColors.income` |
| `Colors.white` (on primary bg) | `AppColors.textInverse` |
| `LinearProgressIndicator` | `AppProgressBar` (variant per context) |
| `OutlinedButton` / `ElevatedButton` | `AppButton(variant: ...)` |
| `PageSkeleton()` / `CircularProgressIndicator` | `DashboardShimmer()` |
| `EdgeInsets.only(left:…, right:…)` | `EdgeInsetsDirectional.fromSTEB(…)` |
| hardcoded `fontSize`/`fontWeight` | `AppTypography.*` |
| `theme.scaffoldBackgroundColor` | `isDark ? AppColors.backgroundDark : AppColors.background` |
| `AppBar` title on surface BG | `AppTypography.headingMd`, icons `AppColors.textSecondary` |

---

## File map

| Task | Files |
|------|-------|
| 1 | `lib/widgets/more/more_menu_item.dart`, `lib/screens/more/more_screen.dart` |
| 2 | `lib/screens/settings/settings_screen.dart` |
| 3 | `lib/widgets/goals/goal_summary_cards.dart`, `lib/widgets/goals/overall_progress_card.dart` |
| 4 | `lib/widgets/goals/goal_list_item.dart`, `lib/screens/goals/goals_screen.dart` |
| 5 | `lib/widgets/budgets/month_selector.dart`, `lib/widgets/budgets/budget_summary_card.dart`, `lib/widgets/budgets/financial_advisor_card.dart` |
| 6 | `lib/widgets/budgets/budget_rule_card.dart`, `lib/widgets/budgets/budget_list_item.dart`, `lib/widgets/budgets/category_spending_item.dart` |
| 7 | `lib/screens/budgets/budgets_screen.dart` |

---

## Task 1: MoreMenuItem + MoreScreen

**Files:**
- Modify: `lib/widgets/more/more_menu_item.dart`
- Modify: `lib/screens/more/more_screen.dart`

**What changes in `more_menu_item.dart`:**
- Remove `colorScheme: ColorScheme` constructor param
- Convert to `StatefulWidget` (needed for `_pressed` state → `AnimatedScale`)
- All `colorScheme.*` → token equivalents via `isDark`
- `Icons.arrow_back_ios_new` → `Icons.chevron_left` (RTL-aware)
- `EdgeInsets.only(bottom: 12)` → `EdgeInsetsDirectional.only(bottom: AppSpacing.sm)`
- `const EdgeInsets.symmetric(horizontal: 16, vertical: 16)` → `EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)`
- `BorderRadius.circular(16)` → `AppRadius.lg`
- `fontSize: 15, fontWeight: w600` → `AppTypography.headingSm`

**What changes in `more_screen.dart`:**
- Remove `final theme = ...; final colorScheme = ...`
- Add `final isDark = ...`
- `EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24)` → `EdgeInsetsDirectional.fromSTEB(AppSpacing.screenPaddingHorizontal, AppSpacing.md, AppSpacing.screenPaddingHorizontal, AppSpacing.xl)`
- `EdgeInsets.only(bottom: 16, right: 4, left: 4)` → `EdgeInsetsDirectional.only(bottom: AppSpacing.md)`
- `TextStyle(fontSize: 22, fontWeight: w900, ...)` → `AppTypography.headingLg.copyWith(...)`
- Remove `colorScheme:` from all 10 `MoreMenuItem(...)` calls
- Add 3 new imports; remove any that become unused

- [ ] **Step 1: Write `lib/widgets/more/more_menu_item.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class MoreMenuItem extends StatefulWidget {
  const MoreMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<MoreMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: const Cubic(0.23, 1, 0.32, 1),
        child: Container(
          margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.headingSm.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write the `build` method of `lib/screens/more/more_screen.dart`**

Add these imports after the existing ones:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
```

Replace the entire `build` method:
```dart
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPaddingHorizontal,
          AppSpacing.md,
          AppSpacing.screenPaddingHorizontal,
          AppSpacing.xl,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
            child: Text(
              'nav_more'.tr(),
              style: AppTypography.headingLg.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          MoreMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'nav_debts'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebtsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.pie_chart_outline,
            title: 'nav_budgets'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.track_changes,
            title: 'nav_goals'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.trending_up,
            title: 'nav_investments'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvestmentsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.local_fire_department_outlined,
            title: 'fire_title'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FIRECalculatorScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.cruelty_free_outlined,
            title: 'zakat_title'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.menu_book_outlined,
            title: 'nav_learn'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearnScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.notifications_none,
            title: 'nav_alerts'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.settings_outlined,
            title: 'nav_settings'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          MoreMenuItem(
            icon: Icons.help_outline,
            title: 'nav_help'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Run `flutter analyze` — expect 0 errors**

```bash
flutter analyze lib/widgets/more/more_menu_item.dart lib/screens/more/more_screen.dart
```

Expected output: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/more/more_menu_item.dart lib/screens/more/more_screen.dart
git commit -m "refactor: Phase 5A — MoreMenuItem + MoreScreen design tokens"
```

---

## Task 2: SettingsScreen

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

**What changes:**
- Add 4 imports: `app_colors.dart`, `app_spacing.dart`, `app_typography.dart`, `shimmer_loader.dart`
- Remove `final theme = ...; final colorScheme = ...` in `build`
- Add `final isDark = Theme.of(context).brightness == Brightness.dark`
- `Scaffold.backgroundColor` → `isDark ? AppColors.backgroundDark : AppColors.background`
- `AppBar.title` style → `AppTypography.headingMd.copyWith(color: isDark ? ... : ...)`
- `AppBar.iconTheme` → `const IconThemeData(color: AppColors.textSecondary)`
- Add `AppBar.backgroundColor` and `elevation: 0`
- `CircularProgressIndicator(color: AppColors.primary)` (center) → `Padding(padding: EdgeInsets.all(AppSpacing.md), child: const DashboardShimmer())`
- `colorScheme.onSurfaceVariant.withValues(alpha: 0.5)` → `AppColors.textTertiary.withValues(alpha: 0.5)` in version label
- `TextStyle(color:..., fontSize: 11, fontWeight: FontWeight.w700)` → `AppTypography.labelSm.copyWith(color: ...)`
- `const EdgeInsets.all(16)` → `const EdgeInsets.all(AppSpacing.md)` in `SingleChildScrollView.padding`

- [ ] **Step 1: Add imports to `lib/screens/settings/settings_screen.dart`**

Add after `import '../../utils/app_colors.dart';`:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/shimmer_loader.dart';
```

Remove the old `import '../../utils/app_colors.dart';` line (both paths work, but core is canonical — or keep utils, either is fine).

- [ ] **Step 2: Replace the `build` method**

```dart
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          'settings_title'.tr(),
          style: AppTypography.headingMd.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: const DashboardShimmer(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileForm(
                    initialProfile: _initialProfile,
                    userEmail: _userEmail,
                    memberSince: _memberSince,
                  ),
                  const PreferencesSection(),
                  AssetsForm(
                    initialProfile: _initialProfile,
                    netWorth:
                        _cashBalance + _savings + _investments - _totalDebt,
                    cashBalance: _cashBalance,
                    savings: _savings,
                    investments: _investments,
                    totalDebt: _totalDebt,
                    currency: _currency,
                  ),
                  const ExportDeleteSection(),
                  const SizedBox(height: 12),
                  const TestimonialCard(),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      '🌄 — $_appVersion',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
```

- [ ] **Step 3: Run `flutter analyze`**

```bash
flutter analyze lib/screens/settings/settings_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "refactor: Phase 5A — SettingsScreen design tokens"
```

---

## Task 3: GoalSummaryCards + OverallProgressCard

**Files:**
- Modify: `lib/widgets/goals/goal_summary_cards.dart`
- Modify: `lib/widgets/goals/overall_progress_card.dart`

**What changes in `goal_summary_cards.dart`:**
- Remove `colorScheme: ColorScheme` param
- Add `isDark` inside `build` and `_statCard`
- `colorScheme.primary` → `AppColors.primary`
- `AppColors.success` → `AppColors.income`
- `colorScheme.secondary` (saved stat) → `AppColors.income`
- `colorScheme.onSurfaceVariant` → `isDark ? AppColors.textSecondaryDark : AppColors.textSecondary`
- `fontSize: 16, fontWeight: w900` → `AppTypography.headingMd`
- `fontSize: 10` → `AppTypography.labelSm`
- `BorderRadius.circular(12)` → `AppRadius.md`
- Pass `isDark` to `_statCard` helper

**What changes in `overall_progress_card.dart`:**
- Remove `colorScheme: ColorScheme` param
- Add `isDark` check
- Replace entire Container + custom Row + `LinearProgressIndicator` → `AppProgressBar`
- `BorderRadius.circular(14)` → `AppRadius.lg`
- `const EdgeInsets.all(16)` → `EdgeInsets.all(AppSpacing.md)`
- Import: `progress_bar.dart` + core theme files

- [ ] **Step 1: Write `lib/widgets/goals/goal_summary_cards.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class GoalSummaryCards extends StatelessWidget {
  const GoalSummaryCards({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalSaved,
    required this.currency,
  });

  final int totalGoals;
  final int completedGoals;
  final double totalSaved;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark,
            Icons.track_changes,
            '$totalGoals',
            'goals_count_label'.tr(),
            AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            isDark,
            Icons.check_circle_outline,
            '$completedGoals',
            'goals_completed_label'.tr(),
            AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            isDark,
            Icons.account_balance_wallet,
            totalSaved.toStringAsFixed(0),
            'goals_saved_label'.tr(),
            AppColors.income,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `lib/widgets/goals/overall_progress_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../common/progress_bar.dart';

class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({
    super.key,
    required this.totalSaved,
    required this.totalTarget,
    required this.currency,
  });

  final double totalSaved;
  final double totalTarget;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: AppProgressBar(
        value: progress,
        title: 'goals_overall_progress'.tr(),
        variant: ProgressBarVariant.goal,
        infoEnd:
            '${totalSaved.toStringAsFixed(0)} / ${totalTarget.toStringAsFixed(0)} $currency',
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

```bash
flutter analyze lib/widgets/goals/goal_summary_cards.dart lib/widgets/goals/overall_progress_card.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/goals/goal_summary_cards.dart lib/widgets/goals/overall_progress_card.dart
git commit -m "refactor: Phase 5A — GoalSummaryCards + OverallProgressCard tokens"
```

---

## Task 4: GoalListItem + GoalsScreen

**Files:**
- Modify: `lib/widgets/goals/goal_list_item.dart`
- Modify: `lib/screens/goals/goals_screen.dart`

**What changes in `goal_list_item.dart`:**
- Remove `colorScheme: ColorScheme` param
- Add `isDark`
- `color` var: `AppColors.success` → `AppColors.income`; `colorScheme.primary` → `AppColors.primary`; `colorScheme.secondary` → `AppColors.income`
- Rename to `accentColor` for clarity; inline delete button uses `AppColors.expense`
- `colorScheme.surface` → surface token; `colorScheme.onSurface` → primary text token
- `LinearProgressIndicator` → `AppProgressBar` (variant: goal, fillColor override)
- `OutlinedButton` → `AppButton(variant: AppButtonVariant.secondary)`
- `fontSize: 15, fontWeight: w900` → `AppTypography.headingSm`
- `fontSize: 12, fontWeight: w700` (progress label) removed (AppProgressBar owns it)
- Extract private `_ActionButton` widget for edit/delete buttons
- `EdgeInsets.only(bottom: 12)` → `EdgeInsetsDirectional.only(bottom: AppSpacing.sm)`
- `const EdgeInsets.all(16)` → `EdgeInsets.all(AppSpacing.md)`
- Import core theme files, `app_button.dart`, `progress_bar.dart`; remove `../../utils/app_colors.dart`

**What changes in `goals_screen.dart`:**
- Add import `shimmer_loader.dart`; remove import `skeleton_loader.dart`
- Add import `empty_state.dart`
- Add imports for core theme files
- `final theme = ...; final colorScheme = ...` → `final isDark = ...`
- `theme.scaffoldBackgroundColor` → `isDark ? AppColors.backgroundDark : AppColors.background`
- AppBar: `AppTypography.headingMd`, `AppColors.textSecondary` icons, `AppColors.primary` for add, `AppColors.surface`/`surfaceDark` bg, `elevation: 0`
- `PageSkeleton()` → `Padding(padding: EdgeInsets.all(AppSpacing.md), child: const DashboardShimmer())`
- `RefreshIndicator(color: colorScheme.primary)` → `RefreshIndicator(color: AppColors.primary)`
- `SingleChildScrollView(padding: EdgeInsets.all(16))` → `padding: EdgeInsets.all(AppSpacing.md)`
- Remove `colorScheme:` from `GoalSummaryCards`, `OverallProgressCard`, `GoalListItem` calls
- Replace inline empty state `Container` → `EmptyState(icon, title, subtitle, ctaLabel, onCta)`
- `backgroundColor: Theme.of(context).colorScheme.surface` in `_showAddDialog` + `_showAddAmountDialog` → dark-aware token

- [ ] **Step 1: Write `lib/widgets/goals/goal_list_item.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';
import '../common/progress_bar.dart';

class GoalListItem extends StatelessWidget {
  const GoalListItem({
    super.key,
    required this.goal,
    required this.currency,
    required this.onAddAmount,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> goal;
  final String currency;
  final Function(Map<String, dynamic>) onAddAmount;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target = (goal['target_amount'] as num).toDouble();
    final current = (goal['current_amount'] as num).toDouble();
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;
    final isDone = current >= target;

    // income (green) for done or early stages; primary (blue) when nearing target
    final accentColor =
        (!isDone && progress >= 0.7) ? AppColors.primary : AppColors.income;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((goal['icon'] as String?) != null) ...[
                Icon(
                  _getIconData(goal['icon'] as String),
                  size: 22,
                  color: accentColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  goal['name'] ?? '',
                  style: AppTypography.headingSm.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isDone) ...[
                Icon(Icons.check_circle_outline, size: 18, color: accentColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              _ActionButton(
                icon: Icons.edit,
                color: AppColors.primary,
                onTap: () => onEdit(goal),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.close,
                color: AppColors.expense,
                onTap: () => onDelete(goal['id'].toString()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: progress,
            title: '',
            percentageLabel: '${(progress * 100).toStringAsFixed(0)}%',
            variant: ProgressBarVariant.goal,
            fillColor: accentColor,
            infoEnd: isDone
                ? null
                : 'goals_remaining_value'.tr(
                    args: [remaining.toStringAsFixed(0), currency],
                  ),
          ),
          if (!isDone) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'goals_add_saving'.tr(),
              onPressed: () => onAddAmount(goal),
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String? iconString) {
    final codePoint =
        int.tryParse(iconString ?? '') ?? Icons.track_changes.codePoint;
    const icons = [
      Icons.track_changes,
      Icons.directions_car,
      Icons.home,
      Icons.diamond,
      Icons.diamond_outlined,
      Icons.flight,
      Icons.laptop,
      Icons.phone_android,
      Icons.school,
      Icons.workspace_premium,
      Icons.public,
      Icons.cast_for_education,
      Icons.work,
      Icons.fitness_center,
      Icons.favorite,
      Icons.eco,
      Icons.rocket_launch,
      Icons.star,
      Icons.energy_savings_leaf,
      Icons.bar_chart,
      Icons.calendar_today,
      Icons.account_balance_wallet,
      Icons.card_giftcard,
      Icons.shield,
      Icons.bolt,
      Icons.local_fire_department,
      Icons.lightbulb,
      Icons.inventory_2,
      Icons.attach_money,
      Icons.beach_access,
    ];
    for (final icon in icons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.track_changes;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `lib/screens/goals/goals_screen.dart`**

**Imports section** — replace `skeleton_loader.dart` import with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loader.dart';
```

**`_showAddDialog` and `_showAddAmountDialog`** — replace `backgroundColor: Theme.of(context).colorScheme.surface` with:
```dart
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColors.surfaceDark
    : AppColors.surface,
```

**`build` method** — full replacement:
```dart
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalTarget = _goals.fold(
      0.0,
      (a, g) => a + (g['target_amount'] as num).toDouble(),
    );
    final totalSaved = _goals.fold(
      0.0,
      (a, g) => a + (g['current_amount'] as num).toDouble(),
    );
    final completed = _goals
        .where(
          (g) =>
              (g['current_amount'] as num) >= (g['target_amount'] as num),
        )
        .length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          'goals_title'.tr(),
          style: AppTypography.headingMd.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'goals_add'.tr(),
            onPressed: () => _showAddDialog(),
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
                    GoalSummaryCards(
                      totalGoals: _goals.length,
                      completedGoals: completed,
                      totalSaved: totalSaved,
                      currency: _currency,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_goals.isNotEmpty) ...[
                      OverallProgressCard(
                        totalSaved: totalSaved,
                        totalTarget: totalTarget,
                        currency: _currency,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_goals.isEmpty)
                      EmptyState(
                        icon: Icons.track_changes,
                        title: 'goals_empty'.tr(),
                        subtitle: '',
                        ctaLabel: 'goals_add_first'.tr(),
                        onCta: () => _showAddDialog(),
                      )
                    else
                      ..._goals.map(
                        (goal) => GoalListItem(
                          key: ValueKey(goal['id']),
                          goal: goal,
                          currency: _currency,
                          onAddAmount: _showAddAmountDialog,
                          onEdit: (g) => _showAddDialog(existing: g),
                          onDelete: _deleteGoal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
```

- [ ] **Step 3: Run `flutter analyze`**

```bash
flutter analyze lib/widgets/goals/goal_list_item.dart lib/screens/goals/goals_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/goals/goal_list_item.dart lib/screens/goals/goals_screen.dart
git commit -m "refactor: Phase 5A — GoalListItem + GoalsScreen tokens"
```

---

## Task 5: MonthSelector + BudgetSummaryCard + FinancialAdvisorCard

**Files:**
- Modify: `lib/widgets/budgets/month_selector.dart`
- Modify: `lib/widgets/budgets/budget_summary_card.dart`
- Modify: `lib/widgets/budgets/financial_advisor_card.dart`

**What changes in `month_selector.dart`:**
- Remove `colorScheme: ColorScheme` param
- Replace custom `ListView.builder` chips with `AppFilterChips`
- `AppFilterChips` takes `options: List<String>`, `selected: String`, `onSelected: ValueChanged<String>` — convert between index (int) and label (String) internally
- Pass `padding: EdgeInsets.zero` so callers control outer padding

**What changes in `budget_summary_card.dart`:**
- Remove `colorScheme` param; add `isDark`
- `colorScheme.surface` → surface token
- `colorScheme.outlineVariant` → border token
- `colorScheme.onSurface` → primary text token
- `colorScheme.onSurfaceVariant` → secondary text token
- `AppColors.successLight` → `AppColors.income`
- `AppColors.errorLight` → `AppColors.expense`
- `colorScheme.error` (inline in totalSpent text) → `AppColors.expense`
- Replace `LinearProgressIndicator` block → `AppProgressBar` (removes custom Row + Semantics + ClipRRect)
- `fontWeight: w900, fontSize: 12` → `AppTypography.labelMd`
- `fontWeight: w900` (available amount) → `AppTypography.headingMd`
- `fontSize: 18` (available amount) → `AppTypography.headingMd`
- `fontSize: 11` rows → `AppTypography.bodySm`
- `fontSize: 13` rows → `AppTypography.bodyMd`
- Import core theme files + `progress_bar.dart`; remove `../../utils/app_colors.dart`

**What changes in `financial_advisor_card.dart`:**
- Remove `colorScheme: ColorScheme` param (keep `getInsightColor` callback — it's still needed)
- Add `isDark`
- `colorScheme.surface` → surface token
- `colorScheme.outlineVariant` → border token
- `colorScheme.primary` (robot icon) → `AppColors.primary`
- `colorScheme.onSurface` → primary text token
- `fontSize: 13, fontWeight: w900` → `AppTypography.labelMd`
- `fontSize: 12, fontWeight: w700` (insight text) → `AppTypography.labelSm`
- `BorderRadius.circular(16)` → `AppRadius.lg`; `BorderRadius.circular(10)` → `AppRadius.sm + 2` (just use `10.0`)
- `const EdgeInsets.all(14)` → no exact token, keep 14.0 (between md=16 and sm=8, fine as-is)
- Import core theme files

- [ ] **Step 1: Write `lib/widgets/budgets/month_selector.dart`**

```dart
import 'package:flutter/material.dart';
import '../common/filter_chips.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.monthLabels,
    required this.onMonthSelected,
  });

  final int selectedMonth;
  final List<String> monthLabels;
  final Function(int) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = monthLabels[selectedMonth - 1];
    return AppFilterChips(
      options: monthLabels,
      selected: selectedLabel,
      onSelected: (label) {
        final idx = monthLabels.indexOf(label);
        if (idx >= 0) onMonthSelected(idx + 1);
      },
      padding: EdgeInsets.zero,
    );
  }
}
```

- [ ] **Step 2: Write `lib/widgets/budgets/budget_summary_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.income,
    required this.totalDebtPayments,
    required this.available,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.currency,
  });

  final double income;
  final double totalDebtPayments;
  final double available;
  final double totalBudgeted;
  final double totalSpent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dash_summary_month'.tr(),
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            label: 'dash_income'.tr(),
            value: '+${income.toStringAsFixed(0)} $currency',
            valueColor: AppColors.income,
            isDark: isDark,
          ),
          if (totalDebtPayments > 0)
            _SummaryRow(
              label: 'dash_debts_payment'.tr(),
              value: '-${totalDebtPayments.toStringAsFixed(0)} $currency',
              valueColor: AppColors.expense,
              isDark: isDark,
            ),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dash_available_spending'.tr(),
                style: AppTypography.headingSm.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${available.toStringAsFixed(0)} $currency',
                style: AppTypography.headingMd.copyWith(
                  color: available >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
          if (totalBudgeted > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            AppProgressBar(
              value: totalBudgeted > 0
                  ? (totalSpent / totalBudgeted).clamp(0.0, 1.0)
                  : 0,
              title: 'dash_spent_from_categories'.tr(),
              variant: totalSpent > totalBudgeted
                  ? ProgressBarVariant.overspent
                  : ProgressBarVariant.budget,
              infoEnd:
                  '${totalSpent.toStringAsFixed(0)} / ${totalBudgeted.toStringAsFixed(0)} $currency',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMd.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Write `lib/widgets/budgets/financial_advisor_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class FinancialAdvisorCard extends StatelessWidget {
  const FinancialAdvisorCard({
    super.key,
    required this.insights,
    required this.getInsightColor,
  });

  final List<Map<String, dynamic>> insights;
  final Color Function(String) getInsightColor;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'dash_financial_advisor'.tr(),
                  style: AppTypography.labelMd.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: insights.map((ins) {
                final color = getInsightColor(ins['type']!);
                return Container(
                  margin:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(ins['icon'] as IconData, size: 16, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ins['text']!,
                          style: AppTypography.labelSm.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze lib/widgets/budgets/month_selector.dart lib/widgets/budgets/budget_summary_card.dart lib/widgets/budgets/financial_advisor_card.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/budgets/month_selector.dart lib/widgets/budgets/budget_summary_card.dart lib/widgets/budgets/financial_advisor_card.dart
git commit -m "refactor: Phase 5A — MonthSelector + BudgetSummaryCard + FinancialAdvisorCard tokens"
```

---

## Task 6: BudgetRuleCard + BudgetListItem + CategorySpendingItem

**Files:**
- Modify: `lib/widgets/budgets/budget_rule_card.dart`
- Modify: `lib/widgets/budgets/budget_list_item.dart`
- Modify: `lib/widgets/budgets/category_spending_item.dart`

**What changes in `budget_rule_card.dart`:**
- Remove `colorScheme` param; add `isDark`
- `colorScheme.primary` → `AppColors.primary`
- `colorScheme.secondary` (30% "wants" column) → `AppColors.accent`
- `AppColors.success` (20% "savings" column) → `AppColors.income`
- `Colors.white` (apply button text) → handled by `AppButton.small` variant
- Replace inline `GestureDetector + Container` apply button → `AppButton(variant: AppButtonVariant.small, fullWidth: false)`
- `colorScheme.onSurface` → primary text token
- `colorScheme.onSurfaceVariant` → secondary text token
- `fontSize: 13, fontWeight: w900` → `AppTypography.labelMd`
- `fontSize: 16, fontWeight: w900` (pct) → `AppTypography.headingMd`
- `fontSize: 10, fontWeight: w800` (amount) → `AppTypography.labelSm`
- `fontSize: 11` (label) → `AppTypography.labelSm`
- `EdgeInsets.fromLTRB` → `EdgeInsetsDirectional.fromSTEB`
- Import core theme files + `app_button.dart`; remove `../../utils/app_colors.dart`

**What changes in `budget_list_item.dart`:**
- Remove `colorScheme` param; add `isDark`
- `colorScheme.surface` → surface token; `colorScheme.outlineVariant` → border token
- `colorScheme.error.withValues` → `AppColors.expense.withValues`
- `Colors.orange.withValues` → `AppColors.warning.withValues`
- `AppColors.error` → `AppColors.expense`
- `AppColors.errorLight` → `AppColors.expense`
- `AppColors.successLight` → `AppColors.income`
- `colorScheme.primary` (edit button) → `AppColors.primary`
- `colorScheme.onSurface` → primary text token; `colorScheme.onSurfaceVariant` → secondary text
- `LinearProgressIndicator` → `AppProgressBar`
- `fontSize: 14, fontWeight: w800` → `AppTypography.bodyMd` (with w600 via copyWith)
- `fontSize: 12, fontWeight: w700` (subtitle) → `AppTypography.bodySm`
- `fontSize: 16, fontWeight: w900` (pct) removed (AppProgressBar owns percentage)
- `fontSize: 11` rows → `AppTypography.labelSm`
- Import core theme files + `progress_bar.dart`; remove `../../utils/app_colors.dart`
- Extract private `_ActionButton` widget (same pattern as `GoalListItem`)

**What changes in `category_spending_item.dart`:**
- Remove `colorScheme` param; add `isDark`
- `colorScheme.surface` → surface token; `colorScheme.outlineVariant` → border token
- `colorScheme.onSurface` → primary text token; `colorScheme.onSurfaceVariant` → secondary text
- `LinearProgressIndicator` → `AppProgressBar(variant: ProgressBarVariant.budget)` — bar fills width, title = category, infoEnd = amount + percentage
- Remove redundant `Row(mainAxisAlignment: spaceBetween)` above bar — `AppProgressBar.title` handles it
- Import core theme files + `progress_bar.dart`

- [ ] **Step 1: Write `lib/widgets/budgets/budget_rule_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/app_button.dart';

class BudgetRuleCard extends StatelessWidget {
  const BudgetRuleCard({
    super.key,
    required this.available,
    required this.currency,
    required this.onApply,
  });

  final double available;
  final String currency;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.balance, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'dash_rule_503020'.tr(),
                    style: AppTypography.labelMd.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                AppButton(
                  label: 'dash_rule_apply'.tr(),
                  variant: AppButtonVariant.small,
                  onPressed: onApply,
                  fullWidth: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _RuleItem(
                    pct: '50%',
                    label: 'dash_rule_necessities'.tr(),
                    amount: (available * 0.5).round().toDouble(),
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RuleItem(
                    pct: '30%',
                    label: 'dash_rule_wants'.tr(),
                    amount: (available * 0.3).round().toDouble(),
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RuleItem(
                    pct: '20%',
                    label: 'dash_rule_savings'.tr(),
                    amount: (available * 0.2).round().toDouble(),
                    color: AppColors.income,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.pct,
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  final String pct;
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            pct,
            style: AppTypography.headingMd.copyWith(color: color),
          ),
          Text(
            amount.toStringAsFixed(0),
            style: AppTypography.labelSm.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `lib/widgets/budgets/budget_list_item.dart`**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class BudgetListItem extends StatelessWidget {
  const BudgetListItem({
    super.key,
    required this.budget,
    required this.spent,
    required this.currency,
    required this.localizedCategories,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> budget;
  final double spent;
  final String currency;
  final List<Map<String, dynamic>> localizedCategories;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = localizedCategories.firstWhere(
      (c) => c['key'] == budget['category'],
      orElse: () => {'key': budget['category'], 'icon': Icons.edit_note},
    );
    final limit = (budget['monthly_limit'] as num).toDouble();
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final over = spent > limit;
    final warn = !over && pct > 0.8;
    final remaining = (limit - spent).clamp(0.0, double.infinity);

    // Semantic color for status
    final statusColor = over
        ? AppColors.expense
        : warn
            ? AppColors.warning
            : AppColors.income;

    // Border color per status
    final borderColor = over
        ? AppColors.expense.withValues(alpha: 0.3)
        : warn
            ? AppColors.warning.withValues(alpha: 0.2)
            : isDark
                ? AppColors.borderDark
                : AppColors.borderLight;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Icon(
                    cat['icon'] as IconData,
                    size: 22,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget['category'] as String,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} $currency'
                      '${over ? ' ⚠ تجاوزت!' : warn ? ' ◼ اقتربت' : ''}',
                      style: AppTypography.bodySm.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                icon: Icons.edit,
                color: AppColors.primary,
                onTap: () => onEdit(budget),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ActionButton(
                icon: Icons.close,
                color: AppColors.expense,
                onTap: () => onDelete(budget['id'].toString()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: pct,
            title: '',
            percentageLabel: '${(pct * 100).round()}%',
            variant: over
                ? ProgressBarVariant.overspent
                : ProgressBarVariant.budget,
            fillColor: over
                ? AppColors.expense
                : warn
                    ? AppColors.warning
                    : null, // null → variant gradient
            infoStart: 'budget_remaining_label'.tr(),
            infoEnd:
                '${remaining.toStringAsFixed(0)} $currency — ${'budget_limit_label'.tr(namedArgs: {'amount': limit.toStringAsFixed(0), 'currency': currency})}',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}
```

- [ ] **Step 3: Write `lib/widgets/budgets/category_spending_item.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../common/progress_bar.dart';

class CategorySpendingItem extends StatelessWidget {
  const CategorySpendingItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.currency,
  });

  final String category;
  final double amount;
  final double percentage;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: AppProgressBar(
        value: percentage / 100,
        title: category,
        variant: ProgressBarVariant.budget,
        infoEnd:
            '${amount.toStringAsFixed(0)} $currency (${percentage.toStringAsFixed(0)}%)',
      ),
    );
  }
}
```

- [ ] **Step 4: Run `flutter analyze`**

```bash
flutter analyze lib/widgets/budgets/budget_rule_card.dart lib/widgets/budgets/budget_list_item.dart lib/widgets/budgets/category_spending_item.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/budgets/budget_rule_card.dart lib/widgets/budgets/budget_list_item.dart lib/widgets/budgets/category_spending_item.dart
git commit -m "refactor: Phase 5A — BudgetRuleCard + BudgetListItem + CategorySpendingItem tokens"
```

---

## Task 7: BudgetsScreen

**Files:**
- Modify: `lib/screens/budgets/budgets_screen.dart`

**What changes:**
- Replace `import '../../widgets/common/skeleton_loader.dart'` → `import '../../widgets/common/shimmer_loader.dart'`
- Add imports: `app_colors.dart`, `app_spacing.dart`, `app_typography.dart` (core theme)
- Remove `final theme = ...; final colorScheme = ...` in `build`; add `final isDark = ...`
- `theme.scaffoldBackgroundColor` → `isDark ? AppColors.backgroundDark : AppColors.background`
- AppBar: `AppTypography.headingMd` title, `AppColors.textSecondary` iconTheme, `AppColors.primary` add icon, `AppColors.surface/surfaceDark` bg, `elevation: 0`
- `PageSkeleton()` → `Padding(padding: EdgeInsets.all(AppSpacing.md), child: const DashboardShimmer())`
- `RefreshIndicator(color: colorScheme.primary)` → `RefreshIndicator(color: AppColors.primary)`
- `padding: const EdgeInsets.all(16)` → `padding: const EdgeInsets.all(AppSpacing.md)`
- `MonthSelector(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- `BudgetSummaryCard(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- `FinancialAdvisorCard(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- `BudgetRuleCard(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- **Replace `AlertDialog` with `ConfirmDialog.show()`** in `BudgetRuleCard.onApply` callback
- `BudgetListItem(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- `CategorySpendingItem(colorScheme: colorScheme, ...)` → remove `colorScheme:` named arg
- Section title `Text` widgets → `AppTypography.headingSm` + token color (do NOT use `SectionHeader` widget here — it has internal 20px padding that conflicts with the scrollview's padding)
- `_insightColor`: `AppColors.error` → `AppColors.expense`; `AppColors.success` → `AppColors.income`
- SnackBar `backgroundColor: Theme.of(context).colorScheme.primary` → `AppColors.primary`
- `backgroundColor: Theme.of(context).colorScheme.surface` in `_showAddDialog` → dark-aware token

- [ ] **Step 1: Update imports in `lib/screens/budgets/budgets_screen.dart`**

Replace `import '../../widgets/common/skeleton_loader.dart';` with:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/shimmer_loader.dart';
```

- [ ] **Step 2: Update `_insightColor` method**

```dart
  Color _insightColor(String type) {
    switch (type) {
      case 'danger':
        return AppColors.expense;
      case 'warning':
        return AppColors.warning;
      case 'success':
        return AppColors.income;
      default:
        return AppColors.primary;
    }
  }
```

- [ ] **Step 3: Update `_showAddDialog`**

Replace `backgroundColor: Theme.of(context).colorScheme.surface` with:
```dart
backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? AppColors.surfaceDark
    : AppColors.surface,
```

- [ ] **Step 4: Update `_apply502030` SnackBar**

Replace `backgroundColor: Theme.of(context).colorScheme.primary` with `backgroundColor: AppColors.primary`.

- [ ] **Step 5: Replace the `build` method**

```dart
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final available = _income - _totalDebtPayments;
    final totalBudgeted = _budgets.fold(
      0.0,
      (a, b) => a + (b['monthly_limit'] as num).toDouble(),
    );
    final totalSpent = _budgets.fold(
      0.0,
      (a, b) => a + (_spending[b['category']] ?? 0),
    );
    final insights = _getAdvisorInsights();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        title: Text(
          'nav_budgets'.tr(),
          style: AppTypography.headingMd.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'budget_add'.tr(),
            onPressed: () => _showAddDialog(),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonthSelector(
                      selectedMonth: _month,
                      monthLabels: _monthLabels,
                      onMonthSelected: (m) {
                        setState(() {
                          _month = m;
                          _loading = true;
                        });
                        _load();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_income > 0) ...[
                      BudgetSummaryCard(
                        income: _income,
                        totalDebtPayments: _totalDebtPayments,
                        available: available,
                        totalBudgeted: totalBudgeted,
                        totalSpent: totalSpent,
                        currency: _currency,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    FinancialAdvisorCard(
                      insights: insights,
                      getInsightColor: _insightColor,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (_income > 0) ...[
                      BudgetRuleCard(
                        available: available,
                        currency: _currency,
                        onApply: () => ConfirmDialog.show(
                          context: context,
                          title: 'dash_rule_confirm_title'.tr(),
                          message: 'dash_rule_confirm_body'.tr(),
                          danger: false,
                          onConfirm: _apply502030,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (_budgets.isNotEmpty) ...[
                      Text(
                        'dash_my_budgets'.tr(),
                        style: AppTypography.headingSm.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._budgets.map(
                        (b) => BudgetListItem(
                          key: ValueKey(b['id']),
                          budget: b,
                          spent: _spending[b['category']] ?? 0,
                          currency: _currency,
                          localizedCategories: _localizedCategories,
                          onEdit: (budget) => _showAddDialog(existing: budget),
                          onDelete: _deleteBudget,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (_spending.isNotEmpty) ...[
                      Text(
                        'dash_spending_by_category'.tr(),
                        style: AppTypography.headingSm.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._spending.entries.map((e) {
                        final totalExpenses = _spending.values.fold(
                          0.0,
                          (a, b) => a + b,
                        );
                        final pct = totalExpenses > 0
                            ? (e.value / totalExpenses * 100)
                            : 0.0;
                        return CategorySpendingItem(
                          key: ValueKey(e.key),
                          category: e.key,
                          amount: e.value,
                          percentage: pct,
                          currency: _currency,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
```

- [ ] **Step 6: Run `flutter analyze`**

```bash
flutter analyze lib/screens/budgets/budgets_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Run full analyze pass**

```bash
flutter analyze lib/
```

Expected: `No issues found!` (or only pre-existing warnings unrelated to Phase 5A files)

- [ ] **Step 8: Commit**

```bash
git add lib/screens/budgets/budgets_screen.dart
git commit -m "refactor: Phase 5A — BudgetsScreen tokens + ConfirmDialog + DashboardShimmer"
```

---

## Self-review

**Spec coverage:**
- MoreMenuItem: colorScheme removed ✓, AnimatedScale press ✓, AppColors/AppTypography ✓, chevron_left ✓, EdgeInsetsDirectional ✓
- MoreScreen: colorScheme removed from all calls ✓, AppTypography.headingLg ✓, EdgeInsetsDirectional ✓
- SettingsScreen: AppBar surface bg ✓, AppTypography ✓, DashboardShimmer ✓, scaffold bg token ✓
- GoalsScreen: AppBar ✓, DashboardShimmer ✓, EmptyState widget ✓, bottom sheet bg token ✓, colorScheme removed from sub-widget calls ✓
- GoalSummaryCards: colorScheme removed ✓, AppColors.primary/income ✓
- OverallProgressCard: colorScheme removed ✓, AppProgressBar(goal) ✓
- GoalListItem: colorScheme removed ✓, AppProgressBar ✓, AppButton.secondary ✓
- BudgetsScreen: AppBar ✓, DashboardShimmer ✓, ConfirmDialog ✓, AppTypography section headers ✓, colorScheme removed ✓, _insightColor fixed ✓, SnackBar fixed ✓
- MonthSelector: AppFilterChips ✓, colorScheme removed ✓
- BudgetSummaryCard: colorScheme removed ✓, AppProgressBar ✓, errorLight/successLight → income/expense ✓
- FinancialAdvisorCard: colorScheme removed ✓ (getInsightColor callback kept) ✓
- BudgetRuleCard: colorScheme removed ✓, secondary→accent ✓, success→income ✓, Colors.white→AppButton.small ✓
- BudgetListItem: colorScheme removed ✓, AppProgressBar ✓, error/errorLight/successLight fixed ✓
- CategorySpendingItem: colorScheme removed ✓, AppProgressBar ✓

**No placeholders found.**

**Type consistency:** `AppProgressBar(value, title, variant, fillColor?, infoStart?, infoEnd?)` used consistently. `AppFilterChips(options, selected, onSelected, padding?)` used in MonthSelector. `AppButton(label, onPressed, variant, fullWidth)` used in GoalListItem + BudgetRuleCard. `ConfirmDialog.show(context, title, message, danger, onConfirm)` used in BudgetsScreen.

**Caller-side check:** Every widget that had `colorScheme:` as a named param now has that param removed from its constructor — callers in GoalsScreen and BudgetsScreen have the arg removed too. No orphaned `colorScheme:` args remain.
