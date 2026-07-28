import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ─────────────────────────────────────────────────────────
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

  // Subtest colors
  static const subtestColors = [
    Color(0xFF2E6FF2), // Penalaran Matematika - blue
    Color(0xFFFF6B4A), // Literasi Indonesia  - coral
    Color(0xFF3BA55C), // Literasi Inggris    - green
    Color(0xFF9B59B6), // Penalaran Umum      - purple
    Color(0xFFF5B942), // PBM                 - yellow
    Color(0xFF1ABC9C), // PKB                 - teal
  ];
}

// ─── Shadow ────────────────────────────────────────────────────────────────
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

// ─── Theme ──────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.dark),
      displayMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.dark),
      headlineLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark),
      headlineMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
      titleLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
      titleMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
      bodyLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
      bodyMedium: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
      labelLarge: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark),
      labelSmall: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.hint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark,
      ),
      iconTheme: const IconThemeData(color: AppColors.dark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.dark,
        textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
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
      hintStyle: GoogleFonts.nunito(color: AppColors.hint, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
