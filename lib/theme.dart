import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color bgColor = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgSidebar = Color(0xFF0D1320);
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color accentColor = Color(0xFF00D4AA);
  static const Color liveColor = Color(0xFFFF4444);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9BB4);
  static const Color dividerColor = Color(0xFF1E2A3A);
  static const Color selectedBg = Color(0xFF1A1F35);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: bgCard,
        error: liveColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSidebar,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryColor, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get bgGradient => const LinearGradient(
        colors: [bgColor, Color(0xFF0F1629)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
