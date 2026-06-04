import 'package:flutter/material.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';

/// A collection of complete Flutter themes.
/// Includes Aurora aesthetics.
/// Author: İbo + GPT-5 🤝

class CustomeAppThemes {
  // ---------------------------------------------------------------
  // 🌌 Aurora Theme (Premium, vibrant, deep dark)
  // ---------------------------------------------------------------
  static ThemeData auroraTheme = ThemeData(
    brightness: Brightness.dark,
    extensions: const <ThemeExtension<dynamic>>[AppSurface.aurora],
    scaffoldBackgroundColor:
        const Color(0xFF0F0C29), // Match AppSurface baseColor
    primaryColor: const Color(0xFF8A2387), // Rich purple/pink vibe
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8A2387),
      secondary: Color(0xFFE94057),
      surface: Color(0xFF0F0C29),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: Colors.transparent, // Handled by AppCard
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      elevation: 0,
      margin: const EdgeInsets.all(12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE94057),
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x80E94057),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      hintStyle: const TextStyle(color: Colors.white60),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    dividerColor: Colors.white10,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFE94057),
      foregroundColor: Colors.white,
      elevation: 12,
    ),
  );
}
