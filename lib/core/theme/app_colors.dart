import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────
  static const primary      = Color(0xFF1A5F8A); // Islamic blue — all primary actions
  static const primaryDark  = Color(0xFF0D3D5C); // deep variant (pressed states)
  static const primaryLight = Color(0xFF2A7FB8); // dark-mode primary

  // ── Accent (FAB + lesson cards ONLY) ──────────────────────────
  static const accent = Color(0xFFD4A843); // gold

  // ── Semantic ───────────────────────────────────────────────────
  static const income  = Color(0xFF2A7D4F); // all income values
  static const expense = Color(0xFFB83232); // all expense values
  static const warning = Color(0xFFE89818); // budget alerts
  static const info    = primary;           // same as primary

  // ── Light mode surfaces ────────────────────────────────────────
  static const background     = Color(0xFFF7F8FA);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F2F5); // input fills, shimmer base
  static const borderLight    = Color(0xFFE5E7EB); // 1px Stripe-style card border
  static const borderHover    = Color(0xFFD1D5DB);

  // ── Light mode text ────────────────────────────────────────────
  static const textPrimary   = Color(0xFF111827); // headings, amounts
  static const textSecondary = Color(0xFF6B7280); // labels, subtitles
  static const textTertiary  = Color(0xFF9CA3AF); // hints, metadata
  static const textInverse   = Color(0xFFFFFFFF); // on primary (#1A5F8A) backgrounds

  // ── Dark mode surfaces ─────────────────────────────────────────
  static const backgroundDark     = Color(0xFF0F1117);
  static const surfaceDark        = Color(0xFF1A1D27);
  static const surfaceVariantDark = Color(0xFF242736);
  static const borderDark         = Color(0xFF2D3144);
  static const borderHoverDark    = Color(0xFF3D4255);

  // ── Dark mode text ─────────────────────────────────────────────
  static const textPrimaryDark   = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFFD1D5DB);
  // accent, income, expense, warning — unchanged in dark mode
  // primary → primaryLight in dark mode

  // ── Category tints (transaction icon circles only) ─────────────
  static const tintShopping  = Color(0xFFFEF3C7);
  static const tintFood      = Color(0xFFFED7AA);
  static const tintTransport = Color(0xFFFEE2E2);
  static const tintHealth    = Color(0xFFFCE7F3);
  static const tintEducation = Color(0xFFEDE9FE);
  static const tintBills     = Color(0xFFDCFCE7);
  static const tintIncome    = Color(0xFFD1FAE5);
  static const tintInvest    = Color(0xFFEDE9FE);
  static const tintOther     = Color(0xFFF3F4F6);

  // ── Lesson card (Islamic night palette) ────────────────────────
  static const lessonBackground = Color(0xFF1A2744);
  static const lessonAccent     = Color(0xFFD4A843);
  static const lessonText       = Color(0xFFFFFFFF);
  static const lessonSubtext    = Color(0x99FFFFFF); // 60% white
  static const lessonVerseBox   = Color(0x1AD4A843); // 10% gold tint

  // ── Account type palette ───────────────────────────────────────
  static const List<Color> accountPalette = [
    Color(0xFF1A5F8A),
    Color(0xFF2A7D4F),
    Color(0xFF8B5CF6),
    Color(0xFFD4A843),
    Color(0xFFB83232),
    Color(0xFF06B6D4),
  ];

  // ── Legacy aliases (keep existing screens compiling) ───────────
  // Semantic aliases
  static const success      = income;           // 105 uses → income
  static const error        = expense;          // 82 uses  → expense
  static const gold         = accent;
  static const purple       = Color(0xFF8B5CF6);
  static const cyan         = Color(0xFF06B6D4);

  // Surface aliases
  static const bgLight      = background;
  static const cardLight    = surface;
  static const bg0          = backgroundDark;
  static const bg1          = Color(0xFF0F1629);
  static const card0        = surfaceDark;
  static const card1        = Color(0xFF1A2540);
  static const border       = borderDark;

  // Text aliases
  static const textPrimaryLight   = textPrimary;
  static const textSecondaryLight = textSecondary;
  static const textMuted          = textTertiary;
  static const textDisabled       = Color(0xFF475569);

  // Semantic light aliases
  static const successLight  = Color(0xFF6EE7B7);
  static const errorLight    = Color(0xFFFCA5A5);
  static const successDark   = Color(0xFF059669);
  static const warningDark   = Color(0xFF92400E);

  // Surface aliases
  static const surface0 = Color(0xFF0F1629);
  static const surface1 = Color(0xFF0F172A);
  static const surface2 = Color(0xFF1E293B);

  // Misc
  static const sky    = Color(0xFF38BDF8);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  // Category color aliases (used in category pickers, not icon circles)
  static const catFood          = Color(0xFFF97316);
  static const catTransport     = Color(0xFF3B82F6);
  static const catShopping      = Color(0xFFEC4899);
  static const catHealth        = Color(0xFF10B981);
  static const catEntertainment = Color(0xFF8B5CF6);
  static const catBills         = Color(0xFF64748B);
  static const catSavings       = Color(0xFF059669);
  static const catInvestment    = primary;
  static const catOther         = Color(0xFF94A3B8);
}
