## 2026-04-10 - [Destructive Action Confirmation]
**Learning:** Swipe-to-delete in transactions and immediate deletion buttons in budgets/goals are high-risk for accidental data loss. Using `ConfirmDialog` as a bottom sheet (matching Apple HIG) provides a non-intrusive but safe friction point.
**Action:** Always use `confirmDismiss` for `Dismissible` widgets and a confirmation step for 'X' or 'Delete' buttons on financial entities.
