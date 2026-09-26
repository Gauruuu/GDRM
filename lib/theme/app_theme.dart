import 'package:flutter/material.dart';

class AppTheme {
  // Core Palette (matches Python source exactly)
  static const Color bgMain = Color(0xFF0B0F19);
  static const Color bgGlassSidebar = Color(0xFF161B26);
  static const Color bgGlassPanel = Color(0xFF1E2538);
  static const Color borderGlass = Color(0xFF2E374D);
  static const Color fgLight = Color(0xFFF0F4F8);
  static const Color fgMuted = Color(0xFF8A99AD);
  static const Color colorCyan = Color(0xFF00F0FF);
  static const Color colorAmber = Color(0xFFFFB700);
  static const Color colorMagenta = Color(0xFFFF52AB);
  static const Color shadowDeep = Color(0xFF03050A);
  static const Color footerGray = Color(0xFF465369);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        surface: bgMain,
        primary: colorCyan,
        secondary: colorAmber,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: fgLight),
        bodyMedium: TextStyle(color: fgMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgGlassPanel,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: borderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: borderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: colorCyan, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: const TextStyle(color: fgMuted, fontSize: 11, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: fgMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgGlassPanel,
          foregroundColor: fgLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: borderGlass),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      dividerColor: borderGlass,
    );
  }
}
