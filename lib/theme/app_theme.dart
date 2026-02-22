import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Tokens.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: Tokens.accent,
        surface: Tokens.bgMid,
        onSurface: Tokens.textPrimary,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).apply(
        bodyColor: Tokens.textPrimary,
        displayColor: Tokens.textPrimary,
      ),
      iconTheme: const IconThemeData(color: Tokens.textSecondary, size: 20),
      tooltipTheme: const TooltipThemeData(
        height: 0,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(color: Colors.transparent),
        textStyle: TextStyle(fontSize: 0, color: Colors.transparent),
        waitDuration: Duration(days: 999),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Tokens.bgMid,
        contentTextStyle: GoogleFonts.workSans(color: Tokens.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
    );
  }

  // Shorthand text styles — Fraunces for headings, Work Sans for body
  static TextStyle get heading =>
      GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: Tokens.textPrimary);

  static TextStyle get subheading =>
      GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w600, color: Tokens.textPrimary);

  static TextStyle get body =>
      GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, color: Tokens.textPrimary);

  static TextStyle get caption =>
      GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w500, color: Tokens.textSecondary);

  static TextStyle get sidebarGroupLabel =>
      GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Tokens.textMuted, letterSpacing: 1.2);
}
