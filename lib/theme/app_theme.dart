import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF5F5F0);
  static const Color primary = Color(0xFF007777);
  static const Color primaryLight = Color(0xFF00A3A3);
  static const Color accent = Color(0xFFFF8C69);
  static const Color textDark = Color(0xFF333333);
  static const Color textMedium = Color(0xFF1A1A3A);
  static const Color textLight = Color(0xFF7A9A9A);
  static const Color inputUnderline = Color(0xFF00A3A3);
  static const Color white = Color(0xFFFEFEFE);
  static const Color linkColor = Color(0xFF007777);
  static const Color mint = Color(0xFFE0F7FA);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputUnderline, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textMedium,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}