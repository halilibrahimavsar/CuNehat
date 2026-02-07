import 'package:flutter/material.dart';
import 'dart:ui';

/// A collection of complete Flutter themes.
/// Includes GlassMorphism and NeoMorphism aesthetics.
/// Author: İbo + GPT-5 🤝

class CustomeAppThemes {
  // ---------------------------------------------------------------
  // 🧊 GlassMorphism Theme
  // ---------------------------------------------------------------
  static ThemeData glassTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F111A),
    primaryColor: const Color(0xFF00E5FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF64FFDA),
      surface: Color(0x331E1E2A),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.all(12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    dividerColor: Colors.white24,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00E5FF),
      foregroundColor: Colors.black,
      elevation: 6,
    ),
  );

  // ---------------------------------------------------------------
  // 🌑 NeoMorphism Theme
  // ---------------------------------------------------------------
  static final ThemeData neoTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFE0E0E0),
    primaryColor: const Color(0xFF3A86FF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3A86FF),
      secondary: Color(0xFF8338EC),
      surface: Color(0xFFE0E0E0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE0E0E0),
      elevation: 6,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFE0E0E0),
      elevation: 8,
      shadowColor: Colors.grey[500],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE0E0E0),
        foregroundColor: Colors.black87,
        shadowColor: Colors.grey[500],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE0E0E0),
      hintStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    dividerColor: Colors.grey.shade400,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFE0E0E0),
      foregroundColor: const Color(0xFF3A86FF),
      elevation: 10,
      // shadowColor: Colors.grey[600],
    ),
  );

  // ---------------------------------------------------------------
  // Optional blur helper (for custom widgets)
  // ---------------------------------------------------------------
  static Widget glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  static BoxDecoration neoBoxDecoration({bool pressed = false}) {
    return BoxDecoration(
      color: const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(16),
      boxShadow: pressed
          ? [
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.grey.shade500,
                offset: const Offset(5, 5),
                blurRadius: 10,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.grey.shade500,
                offset: const Offset(5, 5),
                blurRadius: 15,
              ),
              const BoxShadow(
                color: Colors.white,
                offset: Offset(-5, -5),
                blurRadius: 15,
              ),
            ],
    );
  }
}
