# Phase 2 — Navigation Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse 5-tab navigation to 4 tabs, replace glassmorphic nav bar with design-system-compliant version, add gold FAB with show/hide logic and global transition animations.

**Architecture:** `MainScreen` owns the FAB and tab state. `TransactionsScreen` listens to `AppState.transactionVersion` via `didChangeDependencies` so the global FAB can trigger reloads. `NavItemWidget` is updated to use `AppColors` tokens directly. `app_theme.dart` gets a global `PageTransitionsTheme`.

**Tech Stack:** Flutter 3.x, Provider, `AppColors` / `AppTypography` / `AppSpacing` from Phase 1, `easy_localization`, existing `AddTransactionDialog` and `AppState`.

---

### Task 1: Create ReportsScreen placeholder

**Files:**
- Create: `lib/screens/reports/reports_screen.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/empty_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
      body: const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'التقارير / Reports',
        subtitle: 'قريباً — سيُبنى هذا الشاشة في المرحلة الرابعة\nComing in Phase 4',
      ),
    );
  }
}
```

- [ ] **Step 2: Add localization key** — open `assets/translations/ar.json` and `en.json`, add:
  - `ar.json`: `"nav_reports": "التقارير"`
  - `en.json`: `"nav_reports": "Reports"`

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/screens/reports/reports_screen.dart
```
Expected: `No issues found`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/reports/
git commit -m "feat: add ReportsScreen placeholder for Phase 2 nav"
```

---

### Task 2: Add global page transition theme

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Add `_FajrakPageTransitionsBuilder` class at the bottom of `app_theme.dart`**

```dart
/// 250ms fade + translateY(8px→0), easeOut — applied globally.
class _FajrakPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FajrakPageTransitionsBuilder();

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final fade = CurvedAnimation(parent: animation, curve: _easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04), // 8px at typical screen height ≈ 200dp
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: _easeOut));

    if (disableAnimations) {
      return FadeTransition(opacity: animation, child: child);
    }

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
```

- [ ] **Step 2: Add `pageTransitionsTheme` to the `ThemeData` in `_build()`** — place it after the `dividerColor` line:

```dart
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _FajrakPageTransitionsBuilder(),
    TargetPlatform.iOS: _FajrakPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _FajrakPageTransitionsBuilder(),
    TargetPlatform.linux: _FajrakPageTransitionsBuilder(),
    TargetPlatform.macOS: _FajrakPageTransitionsBuilder(),
    TargetPlatform.windows: _FajrakPageTransitionsBuilder(),
  },
),
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/theme/app_theme.dart
```
Expected: `No issues found`

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: add global 250ms fade+slide page transitions"
```

---

### Task 3: Update NavItemWidget to use AppColors tokens

**Files:**
- Modify: `lib/widgets/main_screen/nav_item_widget.dart`

- [ ] **Step 1: Replace the file** — the key changes are: use `AppColors.primary` / `AppColors.textTertiary`, remove the pill indicator container (keep dot), add `AppTypography.labelSm`:

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NavItemWidget extends StatefulWidget {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavItemWidget({
    super.key,
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<NavItemWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentIndex == widget.index;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final pressDuration = reduceMotion ? Duration.zero : const Duration(milliseconds: 100);

    final iconColor = isSelected ? AppColors.primary : AppColors.textTertiary;
    final labelColor = isSelected ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      label: widget.label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? 0.92 : 1.0,
          duration: pressDuration,
          curve: Curves.easeOut,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? widget.selectedIcon : widget.icon,
                  color: iconColor,
                  size: 24,
                  semanticLabel: widget.label,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  style: AppTypography.labelSm.copyWith(color: labelColor),
                  child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                // 4px dot indicator
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(top: 3),
                  width: isSelected ? 4 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/widgets/main_screen/nav_item_widget.dart
```
Expected: `No issues found`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/main_screen/nav_item_widget.dart
git commit -m "refactor: update NavItemWidget to use AppColors tokens and labelSm"
```

---

### Task 4: Redesign MainBottomNavBar — remove GlassPanel

**Files:**
- Modify: `lib/widgets/main_screen/main_bottom_nav_bar.dart`

- [ ] **Step 1: Replace the file** — plain `Container` with surface bg + 1px top border, 4 tabs in RTL order:

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'nav_item_widget.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // RTL: index 0 = Home appears rightmost — Flutter handles RTL automatically
              NavItemWidget(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'nav_home'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 1,
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz,
                label: 'nav_transactions'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 2,
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'nav_reports'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
              NavItemWidget(
                index: 3,
                icon: Icons.menu_outlined,
                selectedIcon: Icons.menu,
                label: 'nav_more'.tr(),
                currentIndex: currentIndex,
                onTap: onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add missing localization key** — add `"nav_more"` to `ar.json` (`"المزيد"`) and `en.json` (`"More"`) if not already present.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/widgets/main_screen/main_bottom_nav_bar.dart
```
Expected: `No issues found`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/main_screen/main_bottom_nav_bar.dart
git commit -m "refactor: replace GlassPanel nav bar with surface container, 4 tabs"
```

---

### Task 5: Wire TransactionsScreen to watch transactionVersion

**Files:**
- Modify: `lib/screens/transactions/transactions_screen.dart`

This allows the global FAB in MainScreen to trigger a reload in TransactionsScreen after saving a transaction.

- [ ] **Step 1: Add `_lastTransactionVersion` field** — in `_TransactionsScreenState` class, after existing fields:

```dart
int _lastTransactionVersion = -1;
```

- [ ] **Step 2: Add `didChangeDependencies` override** — after `initState`:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final version = context.watch<AppState>().transactionVersion;
  if (version != _lastTransactionVersion) {
    _lastTransactionVersion = version;
    if (_lastTransactionVersion != -1) { // skip the initial call from initState
      _load(reset: true);
    }
  }
}
```

- [ ] **Step 3: Verify no double-load on initState** — `_load()` is already called in `initState`. The `didChangeDependencies` guard (`_lastTransactionVersion != -1` check is wrong — let me correct it).

Replace the `didChangeDependencies` from Step 2 with this corrected version:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final version = context.watch<AppState>().transactionVersion;
  if (_lastTransactionVersion == -1) {
    // First call — just record the version, initState already called _load()
    _lastTransactionVersion = version;
  } else if (version != _lastTransactionVersion) {
    _lastTransactionVersion = version;
    _load(reset: true);
  }
}
```

- [ ] **Step 4: Remove the FAB from TransactionsScreen** — locate and delete the `floatingActionButton:` parameter in TransactionsScreen's `Scaffold` build method:

```dart
// DELETE these lines from the Scaffold widget:
floatingActionButton: FloatingActionButton(
  onPressed: _showAddDialog,
  backgroundColor: colorScheme.primary,
  child: const Icon(Icons.add, color: Colors.white),
),
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/screens/transactions/transactions_screen.dart
```
Expected: `No issues found`

- [ ] **Step 6: Commit**

```bash
git add lib/screens/transactions/transactions_screen.dart
git commit -m "refactor: watch transactionVersion for global FAB reload, remove local FAB"
```

---

### Task 6: Rewrite MainScreen — 4 tabs + gold FAB

**Files:**
- Modify: `lib/screens/main_screen.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'more/more_screen.dart';
import '../widgets/main_screen/main_bottom_nav_bar.dart';
import '../widgets/transactions/add_transaction_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // 0 = Home (Dashboard)

  late final List<bool> _visited;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    MoreScreen(),
  ];

  // FAB animation
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  late final Animation<double> _fabOpacity;

  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  void initState() {
    super.initState();
    _visited = List.generate(_screens.length, (i) => i == 0);

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: _easeOut),
    );
    _fabOpacity = CurvedAnimation(parent: _fabController, curve: _easeOut);

    // Show FAB immediately on Home tab
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadUnreadAlerts();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  bool get _showFab => _currentIndex != 3; // Hide on More tab

  void _onTabSelected(int index) {
    final wasShowingFab = _showFab;
    setState(() {
      _currentIndex = index;
      _visited[index] = true;
    });
    final nowShowingFab = _showFab;

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      if (nowShowingFab) _fabController.value = 1.0;
      return;
    }
    if (!wasShowingFab && nowShowingFab) {
      _fabController.forward(from: 0.0);
    } else if (wasShowingFab && !nowShowingFab) {
      _fabController.reverse();
    }
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AddTransactionDialog(
        onSaved: () {
          context.read<AppState>().notifyTransactionChanged();
        },
        baseCurrency: context.read<AppState>().currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (i) {
          if (!_visited[i]) return const SizedBox.shrink();
          return _screens[i];
        }),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showFab
          ? AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) => Opacity(
                opacity: _fabOpacity.value,
                child: Transform.scale(
                  scale: _fabScale.value,
                  child: child,
                ),
              ),
              child: _GoldFab(onPressed: _showAddTransaction),
            )
          : null,
    );
  }
}

class _GoldFab extends StatelessWidget {
  const _GoldFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59D4A843), // rgba(212,168,67,0.35)
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF7A5800),
        icon: const Icon(Icons.add, semanticLabel: 'أضف معاملة'),
        label: Text(
          'سجّل معاملة / Add Transaction',
          style: AppTypography.labelLg.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7A5800),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Check `AddTransactionDialog` constructor** — verify it accepts `baseCurrency` (not `currency`) and `onSaved`:

```bash
grep -n "baseCurrency\|currency\|onSaved" lib/widgets/transactions/add_transaction_dialog.dart | head -10
```

Adjust the named parameter in `_showAddTransaction()` to match what `AddTransactionDialog` actually expects.

- [ ] **Step 3: Check `AppState.currency`** — verify the getter name:

```bash
grep -n "String.*currency\|get currency" lib/app_state.dart | head -5
```

Adjust the `context.read<AppState>().currency` call to match the actual getter.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/screens/main_screen.dart
```
Expected: `No issues found`

- [ ] **Step 5: Run the app and manually verify**
  - Home tab shows Dashboard, FAB visible ✓
  - Transactions tab shows list, FAB visible ✓
  - Reports tab shows empty state, FAB visible ✓
  - More tab: FAB animates out ✓
  - FAB tap opens AddTransactionDialog ✓
  - Save a transaction → Transactions tab reloads ✓
  - Nav bar: surface bg, 1px top border, 4px dot on selected ✓

- [ ] **Step 6: Commit**

```bash
git add lib/screens/main_screen.dart
git commit -m "feat: 4-tab navigation, gold FAB with show/hide animation"
```

---

### Task 7: Check localization keys exist

**Files:**
- Modify: `assets/translations/ar.json`, `assets/translations/en.json`

- [ ] **Step 1: Check which keys exist**

```bash
grep -E "nav_home|nav_transactions|nav_reports|nav_more" assets/translations/ar.json assets/translations/en.json
```

- [ ] **Step 2: Add any missing keys** — the required keys and values:

| Key | ar | en |
|-----|----|----|
| `nav_home` | `الرئيسية` | `Home` |
| `nav_transactions` | `المعاملات` | `Transactions` |
| `nav_reports` | `التقارير` | `Reports` |
| `nav_more` | `المزيد` | `More` |

- [ ] **Step 3: Verify app runs without missing translation warnings**

```bash
flutter run --debug 2>&1 | grep -i "translation\|missing" | head -10
```

- [ ] **Step 4: Commit if changed**

```bash
git add assets/translations/
git commit -m "i18n: add nav_reports and nav_more translation keys"
```

---

## Self-Review

**Spec coverage:**
- ✅ 4-tab structure (Task 4 + 6)
- ✅ ReportsScreen placeholder (Task 1)
- ✅ GlassPanel removed (Task 4)
- ✅ NavItemWidget tokens (Task 3)
- ✅ Gold FAB with show/hide (Task 6)
- ✅ FAB enter animation scale 0.92→1 + opacity (Task 6)
- ✅ Page transitions 250ms fade+slide (Task 2)
- ✅ `disableAnimations` respected in all animation code
- ✅ TransactionsScreen reload wired via `transactionVersion` (Task 5)
- ✅ Localization keys (Task 7)

**No placeholders found.**

**Type consistency:** `AppColors.accent`, `AppColors.primary`, `AppColors.textTertiary`, `AppColors.borderLight`, `AppColors.borderDark` — all defined in Phase 1. `AppTypography.labelSm`, `AppTypography.labelLg`, `AppTypography.headingMd` — all defined in Phase 1. `AppSpacing.navBarHeight` — defined in Phase 1.
