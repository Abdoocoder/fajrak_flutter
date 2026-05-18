# Phase 3 Dashboard — ProgressRing Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the linear `AppProgressBar` in `BudgetProgressCard` with a circular `ProgressRing` widget (120px, primary→accent gradient, centered layout) and clean up dead code.

**Architecture:** A new shared `ProgressRing` widget uses `CustomPaint` + `SweepGradient` for the arc. `BudgetProgressCard` is restructured around it — ring centered, income/expense rows below. No new DB queries; existing `income`/`expenses` props drive the ring value.

**Tech Stack:** Flutter 3.x, `dart:math`, `CustomPainter`, `SweepGradient`, easy_localization

---

## File Map

| File | Action |
|---|---|
| `lib/widgets/common/progress_ring.dart` | Create — shared circular ring widget |
| `lib/widgets/dashboard/budget_progress_card.dart` | Modify — swap linear bar for ProgressRing |
| `lib/widgets/dashboard/recent_transactions_list.dart` | Delete — dead code (legacy imports) |
| `assets/i18n/ar.json` | Add `budget_used` key |
| `assets/i18n/en.json` | Add `budget_used` key |

---

## Task 1: Housekeeping — task-master + dead file + i18n key

**Files:**
- Delete: `lib/widgets/dashboard/recent_transactions_list.dart`
- Modify: `assets/i18n/ar.json`
- Modify: `assets/i18n/en.json`

- [ ] **Step 1: Mark task-master subtasks 3.1–3.4 and 3.6 as done**

  In a Claude Code session with task-master MCP available, run:
  ```
  mcp__task-master-ai__set_task_status(projectRoot, id="3", status="done") for subtasks 1,2,3,4,6
  mcp__task-master-ai__set_task_status for subtask 5: status="in_progress"
  ```
  (Or use the CLI: `task-master set-status --id=3.1 --status=done` etc.)

- [ ] **Step 2: Delete the dead widget file**

  ```bash
  rm lib/widgets/dashboard/recent_transactions_list.dart
  ```

  Verify it is not imported anywhere:
  ```bash
  grep -r "recent_transactions_list" lib/
  ```
  Expected output: empty (no matches).

- [ ] **Step 3: Add `budget_used` i18n key to `assets/i18n/ar.json`**

  Find the block near `"dash_monthly_budget"` and add the new key directly after it:

  ```json
  "dash_monthly_budget": "الميزانية الشهرية",
  "budget_used": "مستخدمة",
  ```

- [ ] **Step 4: Add `budget_used` i18n key to `assets/i18n/en.json`**

  Same position, after `"dash_monthly_budget"`:

  ```json
  "dash_monthly_budget": "Monthly Budget",
  "budget_used": "Used",
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add assets/i18n/ar.json assets/i18n/en.json
  git rm lib/widgets/dashboard/recent_transactions_list.dart
  git commit -m "chore: delete dead RecentTransactionsList widget, add budget_used i18n key"
  ```

---

## Task 2: Create `ProgressRing` shared widget

**Files:**
- Create: `lib/widgets/common/progress_ring.dart`

- [ ] **Step 1: Create the file**

  Create `lib/widgets/common/progress_ring.dart` with this exact content:

  ```dart
  import 'dart:math' as math;
  import 'package:flutter/material.dart';
  import '../../core/theme/app_colors.dart';
  import '../../core/theme/app_typography.dart';

  class ProgressRing extends StatelessWidget {
    const ProgressRing({
      super.key,
      required this.value,
      required this.label,
      this.subLabel,
      this.fillColor,
      this.size = 120,
      this.strokeWidth = 10,
    });

    /// 0.0 – 1.0. Clamped internally.
    final double value;

    /// Center text — e.g. "68%"
    final String label;

    /// Optional sub-label below center — e.g. "مستخدمة / Used"
    final String? subLabel;

    /// Override fill color. null → primary→accent gradient.
    final Color? fillColor;

    final double size;
    final double strokeWidth;

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final trackColor =
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
      final textPrimary =
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
      final textSecondary =
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                value: value.clamp(0.0, 1.0),
                trackColor: trackColor,
                fillColor: fillColor,
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.displaySmall.copyWith(
                    color: textPrimary,
                  ),
                ),
                if (subLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subLabel!,
                    style: AppTypography.labelSm.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
  }

  class _RingPainter extends CustomPainter {
    const _RingPainter({
      required this.value,
      required this.trackColor,
      this.fillColor,
      required this.strokeWidth,
    });

    final double value;
    final Color trackColor;
    final Color? fillColor;
    final double strokeWidth;

    static const _startAngle = -math.pi / 2; // 12 o'clock

    @override
    void paint(Canvas canvas, Size size) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = (size.width - strokeWidth) / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Track — full circle
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      if (value <= 0) return;

      final sweepAngle = value * 2 * math.pi;

      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (fillColor != null) {
        fillPaint.color = fillColor!;
      } else {
        fillPaint.shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + sweepAngle,
          colors: [AppColors.primary, AppColors.accent],
        ).createShader(rect);
      }

      canvas.drawArc(rect, _startAngle, sweepAngle, false, fillPaint);
    }

    @override
    bool shouldRepaint(_RingPainter old) =>
        old.value != value ||
        old.trackColor != trackColor ||
        old.fillColor != fillColor ||
        old.strokeWidth != strokeWidth;
  }
  ```

- [ ] **Step 2: Verify it compiles**

  ```bash
  flutter analyze lib/widgets/common/progress_ring.dart
  ```

  Expected: no errors. Warnings about unused imports are fine; fix any actual errors.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/widgets/common/progress_ring.dart
  git commit -m "feat: add ProgressRing shared widget — CustomPaint gradient arc"
  ```

---

## Task 3: Redesign `BudgetProgressCard` with `ProgressRing`

**Files:**
- Modify: `lib/widgets/dashboard/budget_progress_card.dart`

The new layout: tight `AppCard`, header row (title + "see all"), centered `ProgressRing` 120px, income row, 1px divider, expense row.

- [ ] **Step 1: Replace the entire file content**

  ```dart
  import 'package:flutter/material.dart';
  import 'package:easy_localization/easy_localization.dart';
  import '../../core/theme/app_colors.dart';
  import '../../core/theme/app_spacing.dart';
  import '../../core/theme/app_typography.dart';
  import '../common/app_card.dart';
  import '../common/progress_ring.dart';

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
      final dividerColor =
          isDark ? AppColors.borderDark : AppColors.borderLight;

      // Empty state — no income data yet
      if (income == 0) {
        return AppCard(
          variant: AppCardVariant.tight,
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 24,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary,
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
      final pct = (fraction * 100).round();

      // Ring fill color: gradient (null) / warning / overspent
      Color? ringFillColor;
      if (fraction >= 0.9) {
        ringFillColor = AppColors.expense;
      } else if (fraction >= 0.7) {
        ringFillColor = AppColors.warning;
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

            // ProgressRing — centered
            Center(
              child: ProgressRing(
                value: fraction,
                label: '$pct%',
                subLabel: 'budget_used'.tr(),
                fillColor: ringFillColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Income row
            _StatRow(
              isIncome: true,
              label: 'trans_income'.tr(),
              amount: income,
              currency: currency,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.xs),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: AppSpacing.xs),

            // Expense row
            _StatRow(
              isIncome: false,
              label: 'trans_expense'.tr(),
              amount: expenses,
              currency: currency,
              isDark: isDark,
            ),
          ],
        ),
      );
    }
  }

  class _StatRow extends StatelessWidget {
    const _StatRow({
      required this.isIncome,
      required this.label,
      required this.amount,
      required this.currency,
      required this.isDark,
    });

    final bool isIncome;
    final String label;
    final double amount;
    final String currency;
    final bool isDark;

    @override
    Widget build(BuildContext context) {
      final color = isIncome ? AppColors.income : AppColors.expense;
      final labelColor =
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
      final n = amount.abs();
      final formatted =
          n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 11,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: labelColor),
          ),
          const Spacer(),
          Text(
            '$formatted $currency',
            style: AppTypography.headingSm.copyWith(
              color: color,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 2: Analyze the changed files**

  ```bash
  flutter analyze lib/widgets/dashboard/budget_progress_card.dart lib/widgets/common/progress_ring.dart
  ```

  Expected: no errors. If `withValues` is flagged on older Flutter SDK, replace with `withOpacity`.

- [ ] **Step 3: Run the app and check the dashboard visually**

  ```bash
  flutter run
  ```

  Navigate to the Dashboard tab. Verify:
  - BudgetProgressCard shows the circular ring (not the old linear bar)
  - Ring shows correct percentage in center with "مستخدمة / Used" sub-label
  - Income row (green ↑) and expense row (red ↓) appear below the ring
  - "الكل ←" link appears in the header row
  - When expenses ≥ 70% of income → ring turns amber
  - When expenses ≥ 90% of income → ring turns red
  - When income == 0 → fallback empty card (wallet icon row) appears
  - Dark mode: ring track and text use correct dark tokens

- [ ] **Step 4: Commit**

  ```bash
  git add lib/widgets/dashboard/budget_progress_card.dart
  git commit -m "feat: upgrade BudgetProgressCard to ProgressRing hero — circular 120px gradient arc"
  ```

---

## Task 4: Mark Phase 3 complete in task-master

- [ ] **Step 1: Mark subtask 3.5 as done**

  Use task-master MCP or CLI:
  ```
  task-master set-status --id=3.5 --status=done
  ```

- [ ] **Step 2: Mark task 3 (Phase 3) as done**

  ```
  task-master set-status --id=3 --status=done
  ```

- [ ] **Step 3: Verify phase 3 is complete**

  ```
  task-master list
  ```

  Expected: Task 3 shows `done`. Tasks 1 and 2 show `done`. Tasks 4 and 5 show `pending`.

---

## Self-Review Checklist

- [x] **Spec coverage:** ProgressRing widget ✓, BudgetProgressCard redesign ✓, dead file deletion ✓, i18n keys ✓, task-master updates ✓
- [x] **No placeholders:** all steps have exact file paths and complete code
- [x] **Type consistency:** `ProgressRing` constructor matches usage in `BudgetProgressCard` (value, label, subLabel, fillColor all consistent)
- [x] **Color tokens:** `AppColors.surfaceVariant/Dark`, `AppColors.primary`, `AppColors.accent`, `AppColors.warning`, `AppColors.expense` — all from tokens, no hardcoded values
- [x] **Dark mode:** `isDark` branch in both `ProgressRing` and `BudgetProgressCard` uses `*Dark` token variants
- [x] **i18n:** `'budget_used'.tr()` added to both JSON files before use; `trans_income` and `trans_expense` already exist
- [x] **RTL:** No `left/right` padding anywhere; `Spacer()` in `_StatRow` works in both directions
