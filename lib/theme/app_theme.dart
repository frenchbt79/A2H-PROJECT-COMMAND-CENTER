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
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Tokens.textPrimary,
        displayColor: Tokens.textPrimary,
      ),
      iconTheme: const IconThemeData(color: Tokens.textSecondary, size: 20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Tokens.bgMid,
        contentTextStyle: GoogleFonts.inter(color: Tokens.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
    );
  }

  // Shorthand text styles
  static TextStyle get heading =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Tokens.textPrimary);

  static TextStyle get subheading =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Tokens.textPrimary);

  static TextStyle get body =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: Tokens.textPrimary);

  static TextStyle get caption =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Tokens.textSecondary);

  static TextStyle get sidebarGroupLabel =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Tokens.textMuted, letterSpacing: 1.2);
}
