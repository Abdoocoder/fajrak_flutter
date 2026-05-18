abstract final class AppSpacing {
  // ── 8-pt grid ─────────────────────────────────────────────
  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;

  // ── Semantic spacings ──────────────────────────────────────
  static const double screenPaddingHorizontal = 20.0; // screen edge padding
  static const double cardPadding             = 20.0; // Stripe inner card padding
  static const double cardPaddingTight        = 16.0; // compact card padding
  static const double sectionGap              = 24.0; // between major sections
  static const double listItemHeight          = 68.0; // TransactionTile — FIXED, use itemExtent
  static const double itemGap                 = 12.0; // between list items
  static const double iconGap                 =  8.0; // icon ↔ label
  static const double buttonHeight            = 52.0; // PRIMARY / SECONDARY / DANGER buttons
  static const double fieldHeight             = 48.0; // AppTextField height
  static const double tapTarget               = 44.0; // Apple HIG minimum tap area
  static const double navBarHeight            = 64.0; // bottom navigation bar

  // ── Legacy aliases ─────────────────────────────────────────
  static const double pageHorizontal = screenPaddingHorizontal;
  static const double inputHeight    = buttonHeight;
}
