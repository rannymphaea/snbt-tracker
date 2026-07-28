import 'package:flutter/material.dart';

// ─── Color Palette ──────────────────────────────────────────────────────────
class AppColors {
  static const cream    = Color(0xFFFDF8F0);
  static const yellow   = Color(0xFFF5B942);
  static const coral    = Color(0xFFFF6B4A);
  static const blue     = Color(0xFF2E6FF2);
  static const green    = Color(0xFF3BA55C);
  static const dark     = Color(0xFF2D2D2D);
  static const purple   = Color(0xFF9B59B6);
  static const red      = Color(0xFFE74C3C);
  static const teal     = Color(0xFF1ABC9C);
  static const cardBg   = Colors.white;
  static const border   = Color(0xFF2D2D2D);
  static const hint     = Color(0xFF999999);
  static const divider  = Color(0xFFF0EDE8);

  static const subtestColors = [
    Color(0xFF2E6FF2), // Penalaran Matematika
    Color(0xFFFF6B4A), // Literasi Indonesia
    Color(0xFF3BA55C), // Literasi Inggris
    Color(0xFF9B59B6), // Penalaran Umum
    Color(0xFFF5B942), // PBM
    Color(0xFF1ABC9C), // PKB
  ];
}

// ─── Shadows ────────────────────────────────────────────────────────────────
class AppShadows {
  static const solid = [
    BoxShadow(color: AppColors.dark, offset: Offset(3, 3), blurRadius: 0),
  ];
  static const solidSm = [
    BoxShadow(color: AppColors.dark, offset: Offset(2, 2), blurRadius: 0),
  ];
  static BoxShadow solidColor(Color c) =>
      BoxShadow(color: c, offset: const Offset(3, 3), blurRadius: 0);
}

// ─── Border Radius ──────────────────────────────────────────────────────────
class AppRadius {
  static const card   = BorderRadius.all(Radius.circular(16));
  static const cardLg = BorderRadius.all(Radius.circular(20));
  static const pill   = BorderRadius.all(Radius.circular(999));
  static const sm     = BorderRadius.all(Radius.circular(10));
}

// ─── Local Nunito TextStyle helper ──────────────────────────────────────────
TextStyle _n(double size, FontWeight w, [Color c = AppColors.dark]) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c);

// ─── Theme ──────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: 'Nunito',
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge:   _n(32, FontWeight.w900),
      displayMedium:  _n(26, FontWeight.w800),
      headlineLarge:  _n(22, FontWeight.w800),
      headlineMedium: _n(18, FontWeight.w700),
      titleLarge:     _n(16, FontWeight.w700),
      titleMedium:    _n(14, FontWeight.w700),
      bodyLarge:      _n(14, FontWeight.w600),
      bodyMedium:     _n(13, FontWeight.w600),
      labelLarge:     _n(12, FontWeight.w700),
      labelSmall:     _n(10, FontWeight.w700, AppColors.hint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _n(20, FontWeight.w800),
      iconTheme: const IconThemeData(color: AppColors.dark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.dark,
        textStyle: _n(15, FontWeight.w800),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: const BorderSide(color: AppColors.dark, width: 2),
        minimumSize: const Size(0, 48),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.dark, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.dark, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
      hintStyle: _n(13, FontWeight.w600, AppColors.hint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
