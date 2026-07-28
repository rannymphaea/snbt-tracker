// lib/utils/app_theme.dart -- Dark theme (Stitch AI palette)
import 'package:flutter/material.dart';

// -- Color System (Dark) --
class AppColors {
  // Background layers
  static const bg         = Color(0xFF0D0D1A);   // deepest background
  static const surface    = Color(0xFF1A1A2E);   // card surface
  static const surfaceAlt = Color(0xFF252540);   // input fields, secondary

  // Primary palette
  static const accent     = Color(0xFF7C3AED);   // violet highlights
  static const primary    = Color(0xFF22C55E);   // green CTA (login, start)
  static const secondary  = Color(0xFFF59E0B);   // amber/orange (nav, tryout)

  // Subtest colors
  static const violet     = Color(0xFF7C3AED);
  static const teal       = Color(0xFF14B8A6);
  static const coral      = Color(0xFFEF4444);
  static const lime       = Color(0xFF22C55E);
  static const amber      = Color(0xFFF59E0B);
  static const blue       = Color(0xFF3B82F6);
  static const pink       = Color(0xFFEC4899);

  // Text
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted     = Color(0xFF6B7280);

  // Border
  static const border     = Color(0xFF374151);
  static const borderLight= Color(0xFF4B5563);

  // Per-subtest (matches materi-snbt.json order)
  static const subtestColors = [
    Color(0xFF7C3AED), // PU
    Color(0xFF14B8A6), // PPU
    Color(0xFFEF4444), // PBM
    Color(0xFF22C55E), // PK
    Color(0xFFF59E0B), // LBI
    Color(0xFF3B82F6), // LBE
    Color(0xFFEC4899), // PM
  ];
}

// -- Shadows --
class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const elevated = [
    BoxShadow(color: Color(0x60000000), offset: Offset(0, 8), blurRadius: 24),
  ];
}

// -- Border Radius --
class AppRadius {
  static const card   = BorderRadius.all(Radius.circular(16));
  static const cardLg = BorderRadius.all(Radius.circular(24));
  static const pill   = BorderRadius.all(Radius.circular(999));
  static const sm     = BorderRadius.all(Radius.circular(10));
  static const xs     = BorderRadius.all(Radius.circular(6));
}

// -- Theme --
TextStyle _t(double size, FontWeight w, [Color c = AppColors.textPrimary]) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c);

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Nunito',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.coral,
    ),
    textTheme: TextTheme(
      displayLarge:   _t(32, FontWeight.w900),
      displayMedium:  _t(26, FontWeight.w900),
      headlineLarge:  _t(22, FontWeight.w800),
      headlineMedium: _t(18, FontWeight.w800),
      titleLarge:     _t(16, FontWeight.w800),
      titleMedium:    _t(14, FontWeight.w700),
      bodyLarge:      _t(14, FontWeight.w600),
      bodyMedium:     _t(13, FontWeight.w500),
      labelLarge:     _t(13, FontWeight.w800),
      labelSmall:     _t(10, FontWeight.w600, AppColors.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _t(18, FontWeight.w900, AppColors.accent),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: _t(15, FontWeight.w800, Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        minimumSize: const Size(0, 52),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: _t(13, FontWeight.w500, AppColors.textMuted),
      labelStyle: _t(12, FontWeight.w600, AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textMuted,
    ),
    dividerColor: AppColors.border,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
  );
}
