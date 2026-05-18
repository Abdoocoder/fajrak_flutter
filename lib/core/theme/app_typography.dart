import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const _f = 'IBMPlexSansArabic';
  static const List<String> _fallback = [
    'Cairo',
    'Roboto',
    'Noto Color Emoji',
    'Noto Sans Arabic',
    'sans-serif',
  ];
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // ── DESIGN.md Scale ────────────────────────────────────────────
  // Display — Stripe hero numbers, balance cards
  static const displayLarge = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.0,
    height: 1.1,
  );
  static const displayMedium = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.15,
  );
  static const displaySmall = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.2,
  );

  // Headings
  static const headingLg = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const headingMd = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const headingSm = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static const bodyLg = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const bodyMd = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const bodySm = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Labels
  static const labelLg = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const labelMd = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  static const labelSm = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // Currency — tabular figures for all amounts
  static const currency = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );
  static const currencyLarge = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    fontFeatures: _tabular,
  );

  // ── Apple HIG 11-Level Scale (legacy — keep for existing screens) ──
  static const TextStyle largeTitle = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle title3 = headingLg; // 20px w:600
  static const TextStyle headline = headingMd; // 17px w:600
  static const TextStyle body = bodyLg;         // 16px w:400
  static const TextStyle callout = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle subheadline = headingSm; // 15px w:600
  static const TextStyle footnote = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle caption1 = bodySm; // 12px w:400
  static const TextStyle caption2 = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // ── Stripe Currency Styles (legacy aliases) ────────────────────
  static const TextStyle amountXl = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    fontFeatures: _tabular,
  );
  static const TextStyle amountLg = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );
  static const TextStyle amount = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );
  static const TextStyle amountSm = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    fontFeatures: _tabular,
  );
  static const TextStyle amountXs = currency;

  // ── Material 3 TextTheme ───────────────────────────────────────
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: displaySmall,
    headlineMedium: headingLg,
    headlineSmall: headingMd,
    titleLarge: headingMd,
    titleMedium: bodyLg,
    titleSmall: headingSm,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
