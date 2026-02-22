import 'package:flutter/material.dart';

/// Design tokens for the Project Command Center UI.
/// Theme: Charcoal Ember — warm charcoal with amber highlights.
class Tokens {
  Tokens._();

  // ── Colours — Charcoal Ember ─────────────────────────────
  static const Color bgDark = Color(0xFF141210);
  static const Color bgMid = Color(0xFF1C1916);
  static const Color bloomBlue = Color(0xFF3A2A18);    // warm amber bloom
  static const Color bloomPurple = Color(0xFF2E2018);   // warm brown bloom
  static const Color accent = Color(0xFFE8923A);        // amber accent
  static const Color accentDim = Color(0xFFC46B18);     // deeper amber
  static const Color glassFill = Color(0x14E8923A);     // amber-tinted glass ~8%
  static const Color glassBorder = Color(0x28E8923A);   // amber-tinted border ~16%
  static const Color textPrimary = Color(0xFFE0D8CC);
  static const Color textSecondary = Color(0xFFA89A88);
  static const Color textMuted = Color(0xFF7A6E60);
  static const Color sidebarActive = Color(0x28E8923A); // amber highlight
  static const Color chipGreen = Color(0xFF66BB6A);
  static const Color chipYellow = Color(0xFFFFB74D);
  static const Color chipRed = Color(0xFFEF5350);
  static const Color chipBlue = Color(0xFFD4A574);      // warm gold instead of blue
  static const Color chipOrange = Color(0xFFC46B18);
  static const Color chipIndigo = Color(0xFFA0785C);    // warm brown instead of indigo

  // ── Dashboard glass card — Charcoal Ember ──────────────
  static const Color dashGradientTop = Color(0xFF231F1B);
  static const Color dashGradientBottom = Color(0xFF1A1614);
  static const double dashCardRadius = 18.0;
  static const Color dashBorder = Color(0x14E8923A);    // ~8% amber
  static const Color dashHighlight = Color(0x0AE8923A); // ~4% amber
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color accentYellow = Color(0xFFFFB74D);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color accentBlue = Color(0xFFD4A574);    // warm gold

  // ── Radii ────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 14;

  // ── Spacing ──────────────────────────────────────────────
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // ── Blur ─────────────────────────────────────────────────
  static const double glassBlur = 15.0;

  // ── Sidebar ──────────────────────────────────────────────
  static const double sidebarWidth = 260.0;

  // ── Breakpoints ──────────────────────────────────────────
  static const double mobileBreakpoint = 800.0;
}
