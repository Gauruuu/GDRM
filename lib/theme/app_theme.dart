import 'package:flutter/material.dart';

class AppTheme {
  // Dark Palette (matches original cyberpunk console)
  static const Color darkBgMain = Color(0xFF0B0F19);
  static const Color darkBgGlassSidebar = Color(0xFF161B26);
  static const Color darkBgGlassPanel = Color(0xFF1E2538);
  static const Color darkBorderGlass = Color(0xFF2E374D);
  static const Color darkFgLight = Color(0xFFF0F4F8);
  static const Color darkFgMuted = Color(0xFF8A99AD);
  static const Color darkColorCyan = Color(0xFF00F0FF);
  static const Color darkColorAmber = Color(0xFFFFB700);
  static const Color darkColorMagenta = Color(0xFFFF52AB);
  static const Color darkShadowDeep = Color(0xFF03050A);
  static const Color darkFooterGray = Color(0xFF465369);

  // Light Palette (modern, crisp, high-contrast security suite)
  static const Color lightBgMain = Color(0xFFF0F4F8);
  static const Color lightBgGlassSidebar = Color(0xFFFFFFFF);
  static const Color lightBgGlassPanel = Color(0xFFFFFFFF);
  static const Color lightBorderGlass = Color(0xFFD3DCE6);
  static const Color lightFgLight = Color(0xFF0F172A);
  static const Color lightFgMuted = Color(0xFF64748B);
  static const Color lightColorCyan = Color(0xFF0284C7);
  static const Color lightColorAmber = Color(0xFFD97706);
  static const Color lightColorMagenta = Color(0xFFDB2777);
  static const Color lightShadowDeep = Color(0x140F172A);
  static const Color lightFooterGray = Color(0xFF94A3B8);

  // Global dynamic state
  static bool isDark = true;

  // Dynamic getters reflecting active theme
  static Color get bgMain => isDark ? darkBgMain : lightBgMain;
  static Color get bgGlassSidebar => isDark ? darkBgGlassSidebar : lightBgGlassSidebar;
  static Color get bgGlassPanel => isDark ? darkBgGlassPanel : lightBgGlassPanel;
  static Color get borderGlass => isDark ? darkBorderGlass : lightBorderGlass;
  static Color get fgLight => isDark ? darkFgLight : lightFgLight;
  static Color get fgMuted => isDark ? darkFgMuted : lightFgMuted;
  static Color get colorCyan => isDark ? darkColorCyan : lightColorCyan;
  static Color get colorAmber => isDark ? darkColorAmber : lightColorAmber;
  static Color get colorMagenta => isDark ? darkColorMagenta : lightColorMagenta;
  static Color get shadowDeep => isDark ? darkShadowDeep : lightShadowDeep;
  static Color get footerGray => isDark ? darkFooterGray : lightFooterGray;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgMain,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        surface: darkBgMain,
        primary: darkColorCyan,
        secondary: darkColorAmber,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkFgLight),
        bodyMedium: TextStyle(color: darkFgMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgGlassPanel,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: darkBorderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkBorderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkColorCyan, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: const TextStyle(color: darkFgMuted, fontSize: 11, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: darkFgMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBgGlassPanel,
          foregroundColor: darkFgLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: darkBorderGlass),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      dividerColor: darkBorderGlass,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgMain,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        surface: lightBgMain,
        primary: lightColorCyan,
        secondary: lightColorAmber,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightFgLight),
        bodyMedium: TextStyle(color: lightFgMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBgGlassPanel,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBorderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBorderGlass),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightColorCyan, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: const TextStyle(color: lightFgMuted, fontSize: 11, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: lightFgMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightBgGlassPanel,
          foregroundColor: lightFgLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: lightBorderGlass),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      dividerColor: lightBorderGlass,
    );
  }
}
