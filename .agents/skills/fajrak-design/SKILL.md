---
name: fajrak-design
description: Complete design system skill for the Fajrak Flutter app. Enforces DESIGN.md (Stripe visual + Apple HIG + Material 3), Emil Kowalski animation principles, impeccable polish gates, bilingual EN/AR, and RTL-first layout. Use before building or modifying any screen or component.
---

# Fajrak Design System Skill

> The single source of truth for building screens and components in the Fajrak Flutter app.
> Always read the project's `DESIGN.md` at the root before implementing anything.

## Three-Word Brief

**Trustworthy. Clear. Islamic.**

- **Stripe** → how it looks (borders not shadows, numbers as heroes, whitespace builds trust)
- **Apple HIG** → how it behaves (100ms feedback, progressive disclosure, interruptions earned)
- **Material 3** → how it's built in Flutter (RTL, dark mode, accessibility)

---

## Quick Reference Card

```
Primary:      #1A5F8A   Accent/FAB:   #D4A843
Income:       #2A7D4F   Expense:      #B83232
Warning:      #E89818   Surface:      #FFFFFF
Background:   #F7F8FA   Border:       #E5E7EB
TextPrimary:  #111827   TextSecondary:#6B7280
TextTertiary: #9CA3AF   TextInverse:  #FFFFFF

Font:         IBM Plex Sans Arabic (GoogleFonts.ibmPlexSansArabic)
Display:      40px / 700 / letterSpacing -2.0   [Stripe hero numbers]
Card radius:  16px    Button radius: 12px
Card padding: 20px    Screen H-pad:  20px
List height:  68px    (TransactionTile — fixed, use itemExtent)
Elevation:    ZERO — always            [Stripe rule]
Shadow:       NONE — always            [FAB is the only exception]
Tap feedback: < 100ms — always         [HIG rule]
```

---

## 1. Color Tokens

### Light Mode
```dart
// Brand
primary      = Color(0xFF1A5F8A)  // Islamic blue — all primary actions
primaryDark  = Color(0xFF0D3D5C)  // deep variant
primaryLight = Color(0xFF2A7FB8)  // for dark mode
accent       = Color(0xFFD4A843)  // Gold — FAB + lesson cards ONLY

// Semantic
income   = Color(0xFF2A7D4F)  // all income values
expense  = Color(0xFFB83232)  // all expense values
warning  = Color(0xFFE89818)  // budget alerts
info     = Color(0xFF1A5F8A)  // same as primary

// Surfaces
background    = Color(0xFFF7F8FA)
surface       = Color(0xFFFFFFFF)
surfaceVariant= Color(0xFFF0F2F5)  // input fills, shimmer base
borderLight   = Color(0xFFE5E7EB)
borderHover   = Color(0xFFD1D5DB)

// Text (light mode)
textPrimary   = Color(0xFF111827)  // headings, amounts
textSecondary = Color(0xFF6B7280)  // labels, subtitles
textTertiary  = Color(0xFF9CA3AF)  // hints, metadata
textInverse   = Color(0xFFFFFFFF)  // on primary (#1A5F8A) backgrounds
```

### Dark Mode
```dart
backgroundDark     = Color(0xFF0F1117)
surfaceDark        = Color(0xFF1A1D27)
surfaceVariantDark = Color(0xFF242736)
borderDark         = Color(0xFF2D3144)
borderHoverDark    = Color(0xFF3D4255)
textPrimaryDark    = Color(0xFFF9FAFB)
textSecondaryDark  = Color(0xFFD1D5DB)
// accent, income, expense, warning — unchanged in dark mode
// primary → primaryLight (#2A7FB8) in dark mode
```

### Category Tints (transaction icon circles only)
```dart
tintShopping  = Color(0xFFFEF3C7)
tintFood      = Color(0xFFFED7AA)
tintTransport = Color(0xFFFEE2E2)
tintHealth    = Color(0xFFFCE7F3)
tintEducation = Color(0xFFEDE9FE)
tintBills     = Color(0xFFDCFCE7)
tintIncome    = Color(0xFFD1FAE5)
tintInvest    = Color(0xFFEDE9FE)
tintOther     = Color(0xFFF3F4F6)
```

### Lesson Card (Islamic Night Palette)
```dart
lessonBackground = Color(0xFF1A2744)
lessonAccent     = Color(0xFFD4A843)
lessonText       = Color(0xFFFFFFFF)
lessonSubtext    = Color(0x99FFFFFF)  // 60% white
lessonVerseBox   = Color(0x1AD4A843) // 10% gold tint
```

### NEVER
- Hardcode white or black — use tokens
- Put textSecondary gray on primary blue backgrounds — use textInverse or rgba(255,255,255,0.7)
- Use accent gold for error or destructive states

---

## 2. Typography

**Font:** `GoogleFonts.ibmPlexSansArabic()` — always, never system fonts.

```dart
// Display — hero numbers, balance cards
displayLarge:  40px  w:700  letterSpacing:-2.0  height:1.1
displayMedium: 32px  w:700  letterSpacing:-1.5  height:1.15
displaySmall:  24px  w:700  letterSpacing:-1.0  height:1.2

// Headings
headingLg:  20px  w:600  height:1.3
headingMd:  17px  w:600  height:1.3
headingSm:  15px  w:600  height:1.4

// Body
bodyLg:  16px  w:400  height:1.6
bodyMd:  14px  w:400  height:1.5
bodySm:  12px  w:400  height:1.4

// Labels
labelLg:  14px  w:500  letterSpacing:0.1
labelMd:  13px  w:500  letterSpacing:0.2
labelSm:  11px  w:500  letterSpacing:0.4

// Currency (tabular figures for all amounts)
currency:      14px  w:500  FontFeature.tabularFigures()
currencyLarge: 32px  w:700  letterSpacing:-1.5  tabular
```

### Rules
- Tight letterSpacing (-1.5 to -2.0) on all display numbers
- weight 600 for headings — never 700
- weight 400 for body — never lighter
- No fontSize below 11px
- No weight 300 (too thin on Arabic)
- No all-caps (poor Arabic readability)
- No mixing Arabic + Latin fonts in same text span

---

## 3. Spacing & Layout

```dart
xs  =  4px   // icon gap, tight inline
sm  =  8px   // between list items, icon padding
md  = 16px   // standard internal padding
lg  = 24px   // between sections
xl  = 32px   // screen top margin, large gaps
xxl = 48px   // hero sections

screenPaddingHorizontal = 20px
cardPadding             = 20px
cardPaddingTight        = 16px
sectionGap              = 24px
listItemHeight          = 68px  // TransactionTile — FIXED
```

### Layout Rules
- Always use `EdgeInsetsDirectional` (start/end) — never left/right
- `SafeArea` on all top-level screens
- No formal grid — single column, full width
- Exceptions: 2-col quick tools, 3-col stat rows, 4-col category pickers

---

## 4. Border Radius

```dart
xs   =  4px   // progress bars, badges
sm   =  8px   // small buttons
md   = 12px   // buttons, input fields
lg   = 16px   // cards ← most used
xl   = 24px   // bottom sheet top corners
full = 999px  // pills, FAB label, category chips
```

---

## 5. Elevation — The Stripe Rule

```
RULE: elevation = 0, always.
RULE: Use 1px border to define card edges.
RULE: No shadow anywhere — FAB is the only exception.
```

```dart
CardTheme(
  elevation: 0,
  color: AppColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: AppColors.borderLight, width: 1),
  ),
)
```

---

## 6. Components

### AppCard
```
background:    surface
border:        1px solid borderLight
border-radius: 16px
padding:       20px (standard) / 16px (tight) / dark navy (lesson)
elevation:     0 — never shadow

Press feedback: AnimatedScale → 0.98, 100ms, Cubic(0.23, 1, 0.32, 1)
```

### AppButton Variants
```
PRIMARY:   bg #1A5F8A, text white w:600, height 52px, radius 12px
SECONDARY: transparent, border 1.5px #1A5F8A, text #1A5F8A, height 52px
GHOST:     transparent, no border, text textPrimary, height 40px
ACCENT:    bg #D4A843, text #7A5800 w:600, height 48px, radius full
DANGER:    transparent, border 1.5px #B83232, text #B83232, height 52px
SMALL:     height 32px, padding 12px, fontSize 11px, radius 8px

Loading state [Emil]:
  → label animates to opacity 0.7 + blur(2px)
  → CircularProgressIndicator (white, size 20) appears
  → all fields disabled to prevent double-submit

Disabled: opacity 0.5, no tap response
Press:    scale 0.98 → 100ms Cubic(0.23,1,0.32,1) [DESIGN.md spec]
```

### BalanceCard
```
label:   "رصيدك هذا الشهر / Your balance this month" — labelSm, textSecondary
amount:  displayLarge (40px, 700, letterSpacing -2.0) + currency suffix
         count-up animation on load: 0 → actual, 600ms Cubic(0.25,1,0.5,1)
divider: 1px vertical line
income:  "↑ دخل / Income" + amount in income green
expense: "↓ مصروف / Expense" + amount in expense red

States:
  default:  white card, primary blue amount
  negative: border switches to expense red, ⚠ icon before amount
  on-track: 4px accent gold dot top-right corner
```

### TransactionTile
```
height:   68px FIXED — ListView.builder + itemExtent: 68
padding:  14px horizontal, 12px vertical
leading:  40px full-radius circle, category tint bg, emoji 18px
title:    description — bodyMd w:600, textPrimary, maxLines:1, ellipsis
subtitle: "date · category" — bodySm, textTertiary
trailing: amount — currency style, income green or expense red
separator: none between tiles — 1px Divider at month section start only

Gestures:
  Swipe left  → delete (Dismissible)
  Long press  → context menu (edit, delete, duplicate)
  Tap         → detail view

[Emil] Stagger on first load: 40ms per tile, first 6 tiles only.
       Subsequent loads (pull-to-refresh): no stagger.
```

### AppTextField
```
height:   48px
bg:       surface
border:   1px solid borderLight
radius:   12px
padding:  16px horizontal, 14px vertical
font:     bodyMd, textPrimary

States:
  focused:  1.5px border primary
  error:    1.5px border expense red + error text below
  disabled: opacity 0.5
  filled:   surfaceVariant background

Label:  above field, labelMd, textSecondary
Error:  below field, bodySm, expense red
Hint:   inside field, bodyMd, textTertiary

Validation: on blur only — never on every keystroke
Error text: Semantics(liveRegion: true) for TalkBack
```

### ProgressBar
```
track height: 6px
track bg:     surfaceVariant
radius:       4px
fill:         primary → accent gradient (budget)
              income green (goals)
              expense red (overspent)
Label row above: title (left/start) · percentage chip (right/end)
Info row below:  days remaining · amount remaining
```

### ProgressRing (Budget hero)
```
size:         120px
stroke width: 10px
track:        surfaceVariant
fill:         primary → accent gradient
center:       percentage — displaySmall, textPrimary
sub label:    "مستخدمة / Used" — labelSm, textSecondary
```

### LessonCard
```
background:   lessonBackground (#1A2744)
radius:       16px
padding:      16px
header:       "✦" + "درس اليوم / Lesson of the Day" — labelSm, accent gold
badge:        "درس X من ١٧" — bodySm, 60% white
title:        headingSm, white
preview:      2 lines max, bodySm, 60% white, ellipsis
cta:          "اقرأ المزيد ← / Read more" — labelMd, accent gold
decoration:   80px blurred circle, 10% gold, top-right corner
```

### ShimmerLoader
```
NEVER use CircularProgressIndicator for list or data loading.
Always use shimmer matching the shape of incoming content.

baseColor:       surfaceVariant
highlightColor:  surface
animation:       1.5s linear infinite

TransactionShimmer: 6 tiles × 68px
DashboardShimmer:   3 placeholder cards matching layout order
```

### EmptyState
```
icon:     outlined Material icon, 48px, textTertiary
title:    headingMd, textPrimary, centered — bilingual
subtitle: bodyMd, textSecondary, centered, 2 lines max — bilingual
cta:      AppButton primary (optional)

Position: vertically centered in available space, not at top.
```

### FilterChips
```
height:  34px
padding: 0 14px
radius:  full
active:  bg primary, text white, no border
inactive:bg surfaceVariant, text textSecondary, 1px borderLight
scroll:  SingleChildScrollView horizontal, no wrap
```

### CategoryPill
```
shape:   pill (radius full)
padding: 4px vertical, 10px horizontal
bg:      category tint color
text:    labelSm, w:500, dark variant of tint
icon:    emoji 12px, before text, 4px gap
border:  none
```

### SectionHeader
```
layout:  Row, spaceBetween
title:   headingSm, textPrimary
action:  "الكل ← / See all" — labelMd, primary
padding: 20px horizontal, 14px top, 8px bottom
```

---

## 7. Navigation

### Bottom Nav (4 tabs only)
```
background:  surface
border-top:  1px borderLight
elevation:   0
selected:    primary
unselected:  textTertiary
indicator:   4px dot below icon, primary color
label:       labelSm

Tabs (RTL order — rightmost = first):
  1. الرئيسية / Home        icon: home_outlined
  2. المعاملات / Transactions icon: swap_horiz_outlined
  3. التقارير / Reports      icon: bar_chart_outlined
  4. المزيد / More           icon: menu_outlined
```

### Floating Action Button
```
type:       FloatingActionButton.extended
label:      "سجّل معاملة / Add Transaction"
bg:         accent gold (#D4A843)
text:       #7A5800, w:600
icon:       Icons.add, #7A5800
elevation:  0
shadow:     0 4px 12px rgba(212,168,67,0.35)  ← only shadow in the app
position:   center, 16px above nav bar

Show on:    Home, Transactions, Reports
Hide on:    More, all secondary screens

[Emil] Expand animation: start from scale(0.92) + opacity 0
       Duration: 200ms, Cubic(0.23,1,0.32,1)
```

### App Bar
```
Dashboard:  primary (#1A5F8A) background — text uses textInverse (white)
All others: surface background — text uses textPrimary
elevation:  0 (never scrolled elevation)
title:      headingMd — aligned start (right in RTL)
leading:    back arrow, RTL-aware
actions:    max 2 icons, 22px, textSecondary
```

### Bottom Sheet
```
drag handle:   4px × 32px pill, surfaceVariant, centered top
radius:        24px top corners only
bg:            surface
padding:       20px
max height:    90% screen
keyboard:      rises with keyboard

[Emil] Open: 300ms Cubic(0.32,0.72,0,1)  ← drawer curve
       Close: 220ms Cubic(0.23,1,0.32,1) ← faster on exit
```

---

## 8. Screen Patterns

### Dashboard (Header Overlap)
```
1. AppBar — primary blue bg, greeting + date in white/70% white
2. BalanceCard — overlaps header by -18px (Stack + Positioned)
3. BudgetProgressCard — shows 2 categories max, "الكل ←" link
4. SectionHeader "آخر المعاملات / Recent Transactions" + "الكل ←"
5. Last 3 TransactionTiles in AppCard
6. Gold FAB — always visible at center bottom
NO gamification widgets. NO health score. NO challenges. NO wealth simulator.
```

### List Screens (Transactions, Alerts)
```
1. Search bar — full width, 20px padding
2. FilterChips — horizontal scroll
3. Month section header + summary
4. ListView.builder ALWAYS — itemExtent: 68 for transactions
5. Pull-to-refresh (RefreshIndicator, primary color)
6. Pagination: 20 items/page, load more on scroll
7. Empty state centered if no items
```

### Reports Screen (NEW — Combined layout)
```
1. Month selector chips (horizontal scroll)
2. 3-column stat row: income | divider | expense | divider | net
3. 6-month expense trend bar chart
4. "أعلى الفئات / Top Categories" — 5 CategoryPills with amounts
5. No submit button — all reactive to month selector
```

### Form Screens
```
Short forms:  bottom sheet preferred
Complex forms: full screen (Debt, Goals)
Amount field: always auto-focused
Large numeric display while typing (displayMedium)
Confirm button: sticky bottom, above keyboard
Confirm disabled until required fields valid
```

### Calculator Screens (FIRE, Zakat)
```
Form inputs in collapsible AppCard sections
Result card always visible — updates live as user types
Result hero: displayMedium with semantic color
No submit button — reactive
```

### More Screen
```
Grid/list of tool links — tool name only visible (progressive disclosure)
Tap → opens full screen
Tools: Accounts, Budgets, Debts, Goals, Investments,
       Learn, Achievements, Alerts, FIRE, Zakat, Settings, Help
```

---

## 9. Animation — DESIGN.md + Emil

### Custom Easing Curves
```dart
// Use these instead of Flutter's generic built-ins
static const easeOut    = Cubic(0.23, 1, 0.32, 1);     // enter animations
static const easeInOut  = Cubic(0.77, 0, 0.175, 1);    // on-screen movement
static const easeDrawer = Cubic(0.32, 0.72, 0, 1);     // bottom sheet open
static const easeOutQuart = Cubic(0.25, 1, 0.5, 1);    // number count-up
```

### Duration Budget
```
100ms   card press (scale 0.98)           [HIG: immediate]
150ms   tab switch — opacity fade only    [Emil: tabs tapped many times/day]
200ms   FAB expand, toast appear          [HIG: feedback]
220ms   bottom sheet close                [Emil: asymmetric — faster on exit]
250ms   page route (fade + slide up 8px)  [HIG: spatial model]
300ms   bottom sheet open                 [HIG: context shift]
600ms   balance count-up (0 → actual)     [Stripe: data confidence]
1000ms  lesson complete shimmer (once)    [reward]
```

### Stagger — First Load Only
```dart
// Transaction tiles and dashboard cards on first load
// 40ms delay per item, first 6 items only
// translateY(8px) + opacity 0 → 0 + 1, 250ms easeOut
// Pull-to-refresh: NO stagger — user already knows the layout
```

### Rules
```
[HIG]    NEVER animate on every frame
[HIG]    NEVER duration > 400ms on UI transitions
[HIG]    NEVER bounce/spring on financial data — too playful
[Emil]   NEVER start from scale(0) — use scale(0.92) minimum
[Emil]   NEVER use ease-in — always ease-out or ease-in-out
[Stripe] ALWAYS shimmer — never spinner for list data
[Stripe] ALWAYS scale feedback (0.98) on tappable cards
[HIG]    ALWAYS check MediaQuery.disableAnimations
         → if true: duration = 0, keep opacity/color changes only
```

---

## 10. RTL & Arabic

### Setup
```dart
MaterialApp.router(
  locale: const Locale('ar'),
  supportedLocales: [Locale('ar'), Locale('en')],
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
)
```

### Rules
```
ALWAYS use EdgeInsetsDirectional (start/end) — never left/right
ALWAYS use Icons.chevron_left for forward chevrons (flips in RTL)
Back arrow auto-flips — no manual override needed
Text alignment defaults to start (= right in Arabic)
ListTile leading appears on RIGHT in RTL — correct, don't fix
```

### Bilingual — EN + AR
```dart
// Every user-facing string goes through easy_localization
Text('transaction_title'.tr())

// Arabic-Indic numerals for financial values
NumberFormat.currency(locale: 'ar_JO', symbol: 'د.أ', decimalDigits: 2)
// Output: ١٬٢٣٤.٥٦ د.أ

// Date format
DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now())
// Output: الأربعاء، ١٨ مايو ٢٠٢٦
```

### Terminology — MUST be consistent across all screens
```
AR: معاملة / EN: Transaction       (never: عملية, سجل, record)
AR: ميزانية / EN: Budget
AR: هدف     / EN: Goal
AR: دين     / EN: Debt
AR: حساب    / EN: Account
AR: تقرير   / EN: Report
```

---

## 11. Accessibility

```
Tap targets:  48×48dp minimum, 56×56dp preferred for primary actions
Contrast:     4.5:1 body text, 3:1 large text (WCAG AA)
TalkBack:     semanticLabel in Arabic on every icon
              excludeFromSemantics: true on decorative icons
              Semantics(liveRegion: true) on error messages
Text scaling: support up to 200% — use maxLines + ellipsis for constrained containers
              never hardcode heights that break on large text
Gestures:     every swipe gesture has a tap alternative
Focus ring:   2px primary color on all keyboard-focusable elements
```

---

## 12. Dark Mode

```
Never hardcode white or black — always use color tokens
Never opacity on white to fake disabled — use textTertiary
Always test every screen in dark mode before shipping
Category tints: slightly darker variants in dark mode
```

---

## 13. Quality Gates (Impeccable)

Before marking any screen or component done, verify:

### Impeccable Product Slop Test
> Would a user fluent in Stripe's dashboard sit down in Fajrak and trust this screen, or pause at a subtly-off component?

### Drift Classification
For every deviation from this skill, name the root cause:
- **Missing token** — value should be in AppColors/AppTypography but isn't → add the token
- **One-off implementation** — a shared widget exists but wasn't used → swap to the shared widget
- **Conceptual misalignment** — the flow or hierarchy doesn't match adjacent screens → rework the flow

### Component Checklist
Every interactive component must have ALL states:
- [ ] Default
- [ ] Pressed / Active (scale 0.98, 100ms)
- [ ] Focused (keyboard — 2px primary ring)
- [ ] Disabled (opacity 0.5)
- [ ] Loading (shimmer or button spinner)
- [ ] Error (inline, expense red, liveRegion)
- [ ] Empty (designed state with icon + bilingual text + CTA)

### Screen Checklist
- [ ] All strings use `.tr()` — bilingual EN + AR
- [ ] Text on blue AppBar uses textInverse (white) not textSecondary gray
- [ ] All amounts use tabular figures + Arabic-Indic numerals
- [ ] All padding uses start/end (never left/right)
- [ ] SafeArea wraps the screen
- [ ] Loading → shimmer (never CircularProgressIndicator for data)
- [ ] Empty → designed empty state (never blank)
- [ ] Error → specific message + retry button (never "something went wrong")
- [ ] Dark mode tested
- [ ] MediaQuery.disableAnimations respected
- [ ] All icons have semanticLabel in Arabic
- [ ] No hardcoded colors — all from AppColors tokens

---

## 14. What NOT to Do

```
[Stripe] ✗ elevation or boxShadow on cards
[Stripe] ✗ more than 2 brand colors per screen
[Stripe] ✗ show a number that might be stale — blank > stale
[HIG]    ✗ dialog for non-destructive confirmations
[HIG]    ✗ interrupt user for notifications or promotions
[HIG]    ✗ leave form data blank after submission error
[HIG]    ✗ "something went wrong" without a recovery action
[HIG]    ✗ animations when disableAnimations is true
[Emil]   ✗ start animations from scale(0)
[Emil]   ✗ ease-in on any UI element
[Emil]   ✗ same enter/exit duration (exit should be faster)
[Impeccable] ✗ gray text on colored backgrounds (use textInverse)
[Impeccable] ✗ inconsistent component vocabulary across screens
[Both]   ✗ all-caps text in Arabic
[Both]   ✗ more than 4 tabs in bottom nav
[Both]   ✗ load all transactions without pagination
[Both]   ✗ left/right padding — use start/end
[Both]   ✗ glassmorphism — borders, not blur
[Both]   ✗ Google Fonts with allowRuntimeFetching: true in production
```

---

## Sources

- DESIGN.md: project root `DESIGN.md` — primary authority
- Emil Kowalski animation philosophy: animations.dev
- Impeccable product polish standard: product slop test
- Stripe Design: https://stripe.com/docs/stripe-apps/design
- Apple HIG: https://developer.apple.com/design/human-interface-guidelines
- Material 3: https://m3.material.io
- IBM Plex Sans Arabic: https://fonts.google.com/specimen/IBM+Plex+Sans+Arabic
- WCAG 2.1 AA: https://www.w3.org/TR/WCAG21/

---

*fajrak-design skill v1.0 · May 2026*
*Use this skill before building or modifying any screen in the Fajrak app.*
