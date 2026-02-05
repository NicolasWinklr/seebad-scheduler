// Seebad Bregenz Theme
// Based on https://www.seebad-bregenz.at visual design

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Seebad brand colors
class SeebadColors {
  // Primary brand color - deep aquatic blue
  static const Color primary = Color(0xFF005DA9);
  static const Color primaryDark = Color(0xFF004080);
  static const Color primaryLight = Color(0xFF3380BD);

  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4F8);

  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnBlue = Colors.white;

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Area colors
  static const Color areaSauna = Color(0xFFFF9800);
  static const Color areaMili = Color(0xFF4CAF50);
  static const Color areaBad = Color(0xFF005DA9);

  // Violation colors
  static const Color violationHard = Color(0xFFE53935);
  static const Color violationSoft = Color(0xFFFFB300);
}

/// Seebad theme configuration
class SeebadTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SeebadColors.primary,
        brightness: Brightness.light,
        primary: SeebadColors.primary,
        onPrimary: SeebadColors.onPrimary,
        secondary: SeebadColors.primaryLight,
        surface: SeebadColors.surface,
        error: SeebadColors.error,
      ),
      scaffoldBackgroundColor: SeebadColors.background,
      textTheme: _buildTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: SeebadColors.primary,
        foregroundColor: SeebadColors.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: SeebadColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SeebadColors.primary,
          foregroundColor: SeebadColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SeebadColors.primary,
          side: const BorderSide(color: SeebadColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SeebadColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SeebadColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SeebadColors.surfaceVariant,
        selectedColor: SeebadColors.primary,
        labelStyle: GoogleFonts.outfit(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SeebadColors.textPrimary,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    // Using Outfit as a Söhne-inspired geometric sans-serif
    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.w700, color: SeebadColors.textPrimary),
      displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.w700, color: SeebadColors.textPrimary),
      displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w600, color: SeebadColors.textPrimary),
      headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w600, color: SeebadColors.textPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600, color: SeebadColors.textPrimary),
      headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: SeebadColors.textPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500, color: SeebadColors.textPrimary),
      titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: SeebadColors.textPrimary),
      titleSmall: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: SeebadColors.textPrimary),
      bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400, color: SeebadColors.textPrimary),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: SeebadColors.textPrimary),
      bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: SeebadColors.textSecondary),
      labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: SeebadColors.textPrimary),
      labelMedium: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: SeebadColors.textPrimary),
      labelSmall: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: SeebadColors.textSecondary),
    );
  }
}

/// Common box shadows
class SeebadShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Spacing constants
class SeebadSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
