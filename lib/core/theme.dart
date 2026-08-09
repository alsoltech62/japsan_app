import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color primaryNavy = Color(0xFF0F2247);
  static const Color secondaryNavy = Color(0xFF1D376B);
  static const Color darkNavy = Color(0xFF09152F);
  
  // Gold Colors
  static const Color premiumGold = Color(0xFFC89B3C);
  static const Color luxuryGold = Color(0xFFE7C46A);
  static const Color deepGold = Color(0xFFA97823);

  // Background Colors
  static const Color appBackground = Color(0xFFF8F7F3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF3F5F8);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F2247);
  static const Color textSecondary = Color(0xFF5E6472);
  static const Color textLight = Color(0xFF8A919F);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2E9E4D);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFD83A3A);
  static const Color info = Color(0xFF2D7FF9);

  // Borders
  static const Color lightBorder = Color(0xFFE5E8EF);

  // Legacy Aliases for UI overhaul migration
  static const Color primaryGold = premiumGold;
  static const Color darkGold = deepGold;
  static const Color surfaceDark = cardBackground;
  static const Color surfaceDarker = secondaryBackground;
  static const Color textDim = textLight;
  static const Color backgroundDark = appBackground;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: appBackground,
      primaryColor: primaryNavy,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: premiumGold,
        surface: cardBackground,
        onPrimary: textWhite,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
            titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
            bodyLarge: GoogleFonts.inter(color: textPrimary),
            bodyMedium: GoogleFonts.inter(color: textSecondary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: primaryNavy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: primaryNavy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: textWhite,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: premiumGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        prefixIconColor: primaryNavy,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shadowColor: primaryNavy.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primaryNavy,
        unselectedItemColor: textLight,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
