import 'package:flutter/material.dart';

/// Uygulama bölüm kimliği — beğenilen appbar ile aynı renk dili
/// (birikim=yeşil, işlem=mavi, borç=kırmızı). Kartlar da bunu kullanır.
enum AppSection { savings, transactions, debt, neutral }

class AppGradients {
  const AppGradients._();

  static const Color savings = Color(0xFF10B981); // Vibrant Emerald Green
  static const Color transactions = Color(0xFF3B82F6); // Vibrant Blue
  static const Color debt = Color(0xFFF43F5E); // Vibrant Rose/Red
  static const Color neutral = Color(0xFF8B5CF6); // Vibrant Violet

  static Color sectionColor(AppSection section) {
    switch (section) {
      case AppSection.savings:
        return savings;
      case AppSection.transactions:
        return transactions;
      case AppSection.debt:
        return debt;
      case AppSection.neutral:
        return neutral;
    }
  }

  /// Accent renginden temaya uygun yumuşak "aurora" gradyanı (kart zemini).
  /// Blur yok → listelerde performanslı.
  static LinearGradient accentSurface(
    Color accent,
    Brightness brightness,
    double fill,
  ) {
    // Determine the base color based on brightness
    final base = brightness == Brightness.dark
        ? const Color(0xFF13151D) // Match the new deep dark / aurora base
        : Colors.white;

    // Aurora effect uses an angled gradient combining the accent color with subtle shifts
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(accent.withValues(alpha: fill), base),
        Color.alphaBlend(accent.withValues(alpha: fill * 0.3), base),
      ],
      stops: const [0.0, 1.0],
    );
  }

  /// Dolu/canlı gradyan — başlık, özet kartı, birincil buton zemini için.
  static LinearGradient vivid(Color accent) {
    final hsl = HSLColor.fromColor(accent);

    // Create a mesh-like vibrant gradient by shifting hue slightly
    final color1 =
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final color2 = hsl
        .withHue((hsl.hue + 15) % 360)
        .withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0))
        .toColor();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color1, color2],
    );
  }
}
