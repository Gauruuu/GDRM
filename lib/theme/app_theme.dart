import 'package:flutter/material.dart';

class AppTheme {
  // ── Dark Palette (matches new minimalist dark mode in screenshots) ──────────
  static const Color darkBgMain = Color(0xFF121413);
  static const Color darkBgGlassSidebar = Color(0xFF151817);
  static const Color darkBgGlassPanel = Color(0xFF1A1D1C);
  static const Color darkBorderGlass = Color(0xFF282D2A);
  static const Color darkFgLight = Color(0xFFF3F4F6);
  static const Color darkFgMuted = Color(0xFF8E9592);
  static const Color darkPrimaryGreen = Color(0xFF2EA069);
  static const Color darkNavActiveBg = Color(0xFF18372A);
  static const Color darkNavActiveFg = Color(0xFF52C993);
  static const Color darkSecondaryBtnBg = Color(0xFF1E2220);
  static const Color darkSecondaryBtnBorder = Color(0xFF2F3532);
  static const Color darkColorCyan = Color(0xFF2EA069);
  static const Color darkColorAmber = Color(0xFFF59E0B);
  static const Color darkColorMagenta = Color(0xFF34D399);
  static const Color darkShadowDeep = Color(0xFF090A09);
  static const Color darkFooterGray = Color(0xFF525C57);

  // ── Light Palette (matches new minimalist warm off-white in screenshots) ────
  static const Color lightBgMain = Color(0xFFF7F8F6);
  static const Color lightBgGlassSidebar = Color(0xFFFFFFFF);
  static const Color lightBgGlassPanel = Color(0xFFFFFFFF);
  static const Color lightBorderGlass = Color(0xFFE5E7EB);
  static const Color lightFgLight = Color(0xFF111827);
  static const Color lightFgMuted = Color(0xFF6B7280);
  static const Color lightPrimaryGreen = Color(0xFF163E2E);
  static const Color lightNavActiveBg = Color(0xFFE8F3EE);
  static const Color lightNavActiveFg = Color(0xFF163E2E);
  static const Color lightSecondaryBtnBg = Color(0xFFFFFFFF);
  static const Color lightSecondaryBtnBorder = Color(0xFFD1D5DB);
  static const Color lightColorCyan = Color(0xFF163E2E);
  static const Color lightColorAmber = Color(0xFFD97706);
  static const Color lightColorMagenta = Color(0xFF16A34A);
  static const Color lightShadowDeep = Color(0x0A000000);
  static const Color lightFooterGray = Color(0xFF9CA3AF);

  // Global dynamic state
  static bool isDark = false; // Default to light mode or match user preference

  // Dynamic getters reflecting active theme
  static Color get bgMain => isDark ? darkBgMain : lightBgMain;
  static Color get bgGlassSidebar => isDark ? darkBgGlassSidebar : lightBgGlassSidebar;
  static Color get bgGlassPanel => isDark ? darkBgGlassPanel : lightBgGlassPanel;
  static Color get borderGlass => isDark ? darkBorderGlass : lightBorderGlass;
  static Color get fgLight => isDark ? darkFgLight : lightFgLight;
  static Color get fgMuted => isDark ? darkFgMuted : lightFgMuted;
  static Color get primaryGreen => isDark ? darkPrimaryGreen : lightPrimaryGreen;
  static Color get navActiveBg => isDark ? darkNavActiveBg : lightNavActiveBg;
  static Color get navActiveFg => isDark ? darkNavActiveFg : lightNavActiveFg;
  static Color get secondaryBtnBg => isDark ? darkSecondaryBtnBg : lightSecondaryBtnBg;
  static Color get secondaryBtnBorder => isDark ? darkSecondaryBtnBorder : lightSecondaryBtnBorder;
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
        primary: darkPrimaryGreen,
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
          borderRadius: BorderRadius.circular(6),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkBorderGlass),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkPrimaryGreen, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        labelStyle: const TextStyle(color: darkFgMuted, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: darkFgMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          elevation: 0,
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
        primary: lightPrimaryGreen,
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
          borderRadius: BorderRadius.circular(6),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBorderGlass),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightPrimaryGreen, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        labelStyle: const TextStyle(color: lightFgMuted, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: lightFgMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          elevation: 0,
        ),
      ),
      dividerColor: lightBorderGlass,
    );
  }
}
