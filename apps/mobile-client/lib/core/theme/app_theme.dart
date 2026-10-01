import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_palette.dart';

class AppTheme {
  // Current active palette (defaults to Theme 1)
  static AppThemePalette _current = AppThemePalette.theme1;
  static AppThemePalette get current => _current;

  static void setPalette(AppThemePalette palette) {
    _current = palette;
  }

  // Active theme dynamic getters - Tự động cập nhật 100% khi đổi Theme
  static Color get primaryColor => _current.primary;
  static Color get primaryLight => _current.primaryLight;
  static Color get secondaryColor => _current.secondary;
  static Color get accentColor => _current.accent;
  static const Color warningColor = Color(0xFFFDCB6E);

  // Background and cards
  static Color get lightBackground => _current.lightBackground;
  static Color get lavenderCard => _current.cardColor;
  static Color get cardColor => _current.cardColor;
  static Color get lavenderSurface => _current.surfaceColor;
  static Color get surfaceColor => _current.surfaceColor;
  static Color get darkTextPrimary => _current.textPrimary;
  static Color get darkTextSecondary => _current.textSecondary;
  static const Color badgeBackground = Color(0xFF383350);

  // Legacy Dark Palette compatibility
  static Color get darkBackground => _current.lightBackground;
  static Color get darkCard => _current.cardColor;
  static Color get darkSurface => _current.surfaceColor;

  // Gradients
  static LinearGradient get primaryGradient => _current.primaryGradient;
  static LinearGradient get accentGradient => _current.accentGradient;

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Configuration builder
  static ThemeData buildTheme(AppThemePalette palette) {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: palette.lightBackground,
      primaryColor: palette.primary,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.cardColor,
        error: palette.accent,
      ),
      cardTheme: CardThemeData(
        color: palette.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: palette.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: palette.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: palette.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: palette.textSecondary,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceColor,
        hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => buildTheme(_current);
  static ThemeData get darkTheme => lightTheme;
}

extension ThemeContextExtension on BuildContext {
  AppThemePalette get themePalette => AppTheme.current;
}
