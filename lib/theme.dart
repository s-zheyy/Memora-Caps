import 'package:flutter/material.dart';

/// Central place for Memora Caps' visual identity so every screen
/// matches the UI mockups (deep navy header, rounded cards, pill buttons).
class AppColors {
  static const Color navyDark = Color(0xFF141B33);
  static const Color navy = Color(0xFF1D2A54);
  static const Color navyLight = Color(0xFF2E3D74);
  static const Color accentBlue = Color(0xFF3B5BDB);
  static const Color background = Color(0xFFF5F6FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B1F3B);
  static const Color textMuted = Color(0xFF7A7F9A);
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A100);
  static const Color danger = Color(0xFFE0503C);
  static const Color streak = Color(0xFFE0503C);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accentBlue,
      primary: AppColors.accentBlue,
      background: AppColors.background,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
