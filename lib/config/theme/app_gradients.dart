import 'package:flutter/material.dart';

/// Uygulama bölüm kimliği — beğenilen appbar ile aynı renk dili
/// (birikim=yeşil, işlem=mavi, borç=kırmızı). Kartlar da bunu kullanır.
enum AppSection { savings, transactions, debt, neutral }

class AppGradients {
  const AppGradients._();

  static const Color savings = Color(0xFF22C55E); // birikim / yatırım
  static const Color transactions = Color(0xFF3B82F6); // işlemler
  static const Color debt = Color(0xFFEF4444); // borç
  static const Color neutral = Color(0xFF6366F1); // nötr / genel

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
    final base =
        brightness == Brightness.dark ? const Color(0xFF1A1D2B) : Colors.white;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(accent.withValues(alpha: fill), base),
        Color.alphaBlend(accent.withValues(alpha: fill * 0.45), base),
      ],
    );
  }

  /// Dolu/canlı gradyan — başlık, özet kartı, birincil buton zemini için.
  static LinearGradient vivid(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor(),
      ],
    );
  }
}
