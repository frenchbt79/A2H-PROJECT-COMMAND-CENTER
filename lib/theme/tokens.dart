import 'package:flutter/material.dart';

/// Design tokens for the Project Command Center UI.
class Tokens {
  Tokens._();

  // ── Colours ──────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0B0E1A);
  static const Color bgMid = Color(0xFF121630);
  static const Color bloomBlue = Color(0xFF1B3A6B);
  static const Color bloomPurple = Color(0xFF2D1B4E);
  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentDim = Color(0xFF2A7BA8);
  static const Color glassFill = Color(0x1AFFFFFF); // ~10 %
  static const Color glassBorder = Color(0x33FFFFFF); // ~20 %
  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF5C6478);
  static const Color sidebarActive = Color(0x33FFFFFF);
  static const Color chipGreen = Color(0xFF4CAF50);
  static const Color chipYellow = Color(0xFFFFC107);
  static const Color chipRed = Color(0xFFF44336);
  static const Color chipBlue = Color(0xFF42A5F5);
  static const Color chipOrange = Color(0xFFFF9800);
  static const Color chipIndigo = Color(0xFF7C4DFF);

  // ── Radii ────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

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
