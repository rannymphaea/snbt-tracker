import 'package:flutter/material.dart';

// ─── Color System ───────────────────────────────────────────────────────────
class AppColors {
  // Primary palette — vivid, bold (Quécaco-inspired)
  static const blue    = Color(0xFF2563EB);  // vibrant blue
  static const blueDk  = Color(0xFF1D4ED8);  // darker blue
  static const coral   = Color(0xFFFF4D4D);  // vivid red-coral
  static const lime    = Color(0xFF22C55E);  // vivid green
  static const amber   = Color(0xFFFBBF24);  // vivid yellow
  static const purple  = Color(0xFF8B5CF6);  // vivid purple
  static const teal    = Color(0xFF14B8A6);  // vivid teal
  static const pink    = Color(0xFFEC4899);  // vivid pink

  // Neutrals
  static const dark    = Color(0xFF0F172A);  // almost black
  static const cream   = Color(0xFFF8F7F4);  // warm off-white background
  static const white   = Colors.white;
  static const hint    = Color(0xFF94A3B8);
  static const border  = Color(0xFF0F172A);

  // Subtest colors (one per subtest)
  static const subtestColors = [
    Color(0xFF2563EB), // Penalaran Matematika
    Color(0xFFFF4D4D), // Literasi Indonesia
    Color(0xFF22C55E), // Literasi Inggris
    Color(0xFF8B5CF6), // Penalaran Umum
    Color(0xFFFBBF24), // PBM
    Color(0xFF14B8A6), // PKB
  ];

  // Pastel fills (lighter version for card backgrounds)
  static const subtestPastel = [
    Color(0xFFDBEAFE), // blue pastel
    Color(0xFFFFE4E4), // coral pastel
    Color(0xFFDCFCE7), // lime pastel
    Color(0xFFEDE9FE), // purple pastel
    Color(0xFFFEF3C7), // amber pastel
    Color(0xFFCCFBF1), // teal pastel
  ];
}

// ─── Shadows (neobrutalism solid) ───────────────────────────────────────────
class AppShadows {
  static const solid = [
    BoxShadow(color: AppColors.dark, offset: Offset(4, 4), blurRadius: 0),
  ];
  static const solidSm = [
    BoxShadow(color: AppColors.dark, offset: Offset(3, 3), blurRadius: 0),
  ];
  static const solidLg = [
    BoxShadow(color: AppColors.dark, offset: Offset(5, 5), blurRadius: 0),
  ];
  static BoxShadow solidColor(Color c, {double offset = 4}) =>
      BoxShadow(color: c, offset: Offset(offset, offset), blurRadius: 0);
}

// ─── Border Radius ──────────────────────────────────────────────────────────
class AppRadius {
  static const card   = BorderRadius.all(Radius.circular(20));
  static const cardLg = BorderRadius.all(Radius.circular(28));
  static const pill   = BorderRadius.all(Radius.circular(999));
  static const sm     = BorderRadius.all(Radius.circular(12));
  static const xs     = BorderRadius.all(Radius.circular(8));
}

// ─── Helper ─────────────────────────────────────────────────────────────────
TextStyle _n(double size, FontWeight w, [Color c = AppColors.dark]) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c,
        letterSpacing: -0.3);

// ─── Theme ──────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: 'Nunito',
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge:   _n(36, FontWeight.w900),
      displayMedium:  _n(28, FontWeight.w900),
      headlineLarge:  _n(24, FontWeight.w800),
      headlineMedium: _n(20, FontWeight.w800),
      titleLarge:     _n(17, FontWeight.w800),
      titleMedium:    _n(15, FontWeight.w700),
      bodyLarge:      _n(15, FontWeight.w600),
      bodyMedium:     _n(13, FontWeight.w600),
      labelLarge:     _n(13, FontWeight.w800),
      labelSmall:     _n(10, FontWeight.w700, AppColors.hint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _n(20, FontWeight.w900),
      iconTheme: const IconThemeData(color: AppColors.dark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        textStyle: _n(15, FontWeight.w800, AppColors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pill,
          side: BorderSide(color: AppColors.dark, width: 2.5),
        ),
        side: const BorderSide(color: AppColors.dark, width: 2.5),
        minimumSize: const Size(0, 52),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
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
        borderSide: const BorderSide(color: AppColors.blue, width: 2.5),
      ),
      hintStyle: _n(13, FontWeight.w600, AppColors.hint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
