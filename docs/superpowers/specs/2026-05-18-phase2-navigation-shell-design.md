# Phase 2 — Navigation Shell Design

**Date:** 2026-05-18  
**Status:** Approved

## Summary

Collapse the current 5-tab navigation to 4 tabs per the fajrak-design spec. Replace the banned GlassPanel nav bar with a plain surface container. Add the gold FAB with correct show/hide logic. Apply global page transitions.

## Tab Structure

| Index | Screen | Icon | RTL position |
|-------|--------|------|-------------|
| 0 | Home (DashboardScreen) | `home_outlined` | rightmost |
| 1 | Transactions (TransactionsScreen) | `swap_horiz_outlined` | |
| 2 | Reports (ReportsScreen — placeholder) | `bar_chart_outlined` | |
| 3 | More (MoreScreen) | `menu_outlined` | leftmost |

- Default tab: 0 (Home)
- AccountsScreen and DebtsScreen tabs removed — accessible from MoreScreen links (already wired)
- `_currentIndex` default changes from 4 → 0

## Bottom Nav Bar

- Remove `GlassPanel` (glassmorphism — banned)
- Replace with `Container`: `AppColors.surface` bg, 1px top `AppColors.borderLight`, elevation 0
- `NavItemWidget` keeps existing 4px dot indicator; colors updated to `AppColors.primary` / `AppColors.textTertiary`
- Icons: outlined variants unselected, filled selected

## Gold FAB

- `FloatingActionButton.extended`
- bg: `AppColors.accent` (#D4A843), fg: `Color(0xFF7A5800)`
- Label: `"سجّل معاملة / Add Transaction"`, icon: `Icons.add`
- elevation: 0; shadow applied via `Material` wrapper: `0 4px 12px rgba(212,168,67,0.35)`
- Location: `FloatingActionButtonLocation.centerFloat`, 16px above nav bar
- **Show** on tabs 0 (Home), 1 (Transactions), 2 (Reports)
- **Hide** on tab 3 (More) — `AnimatedScale` + `AnimatedOpacity` out, 200ms
- **Enter animation:** scale 0.92→1 + opacity 0→1, 200ms `Cubic(0.23,1,0.32,1)`
- Respects `MediaQuery.disableAnimations`

## Page Transitions

- Global `PageTransitionsTheme` in `app_theme.dart`
- Custom builder: 250ms fade + `translateY(8px → 0)`, `Cubic(0.23,1,0.32,1)`
- Applied to all platforms (Android + iOS + web)
- `disableAnimations` → duration 0, keep opacity change

## ReportsScreen Placeholder

- `lib/screens/reports/reports_screen.dart` (new file, new directory)
- Surface AppBar (`AppColors.surface` bg, `AppColors.textPrimary` title)
- Title: `"التقارير / Reports"`
- Body: `EmptyState` centered — `Icons.bar_chart_outlined`, bilingual title + subtitle, no CTA
- Phase 4 will replace the body with full reports content

## Files Changed

- `lib/screens/main_screen.dart` — 4 tabs, new default index
- `lib/widgets/main_screen/main_bottom_nav_bar.dart` — remove GlassPanel, plain container
- `lib/widgets/main_screen/nav_item_widget.dart` — token colors
- `lib/screens/reports/reports_screen.dart` — new placeholder
- `lib/core/theme/app_theme.dart` — PageTransitionsTheme
