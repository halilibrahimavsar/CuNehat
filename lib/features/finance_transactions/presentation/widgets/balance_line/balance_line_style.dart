import 'package:flutter/material.dart';

/// Gün fişinin kâğıdı. Fiş İKİ temada da krem kâğıttır — tasarımın imzası
/// bu; yalnız zemin ve gölge temaya göre ayarlanır. Renkler kâğıt üstünde
/// ölçülü: gri yazı #5F594F krem üstünde ~6:1, kırmızı/yeşil ayrıca
/// AÇIKLIKLA da ayrışır (renk körlüğünde yalnız ton yetmez).
@immutable
class ReceiptPalette {
  final Color paper;
  final Color ink;
  final Color muted;
  final Color rule;
  final Color expense;
  final Color income;
  final Color moved;
  final Color stamp;
  final Color factFill;
  final Color shadow;

  const ReceiptPalette._({
    required this.paper,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.expense,
    required this.income,
    required this.moved,
    required this.stamp,
    required this.factFill,
    required this.shadow,
  });

  static const _light = ReceiptPalette._(
    paper: Color(0xFFFCF8EF),
    ink: Color(0xFF1B1A17),
    muted: Color(0xFF5F594F),
    rule: Color(0xFFB3AB9C),
    expense: Color(0xFFA8231A),
    income: Color(0xFF2D6A1F),
    moved: Color(0xFF57554F),
    stamp: Color(0xFF9A2A1E),
    factFill: Color(0xFFEFE8DA),
    shadow: Color(0x330F172A),
  );

  static const _dark = ReceiptPalette._(
    paper: Color(0xFFF3EEE4),
    ink: Color(0xFF1B1A17),
    muted: Color(0xFF5F594F),
    rule: Color(0xFFB3AB9C),
    expense: Color(0xFFA8231A),
    income: Color(0xFF2D6A1F),
    moved: Color(0xFF57554F),
    stamp: Color(0xFF9A2A1E),
    factFill: Color(0xFFE8E1D3),
    shadow: Color(0xB3000000),
  );

  static ReceiptPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Fişin daktilo yazısı (pubspec'te gömülü, Latin + Türkçe alt kümesi).
const String receiptFontFamily = 'JetBrainsMono';

/// Dile duyarlı BÜYÜK HARF. Dart'ın `toUpperCase`'i Türkçe değil:
/// "Cumartesi" → "CUMARTESI" yazardı (doğrusu "CUMARTESİ").
String upperForLocale(String text, Locale locale) {
  if (locale.languageCode == 'tr' || locale.languageCode == 'az') {
    return text.replaceAll('i', 'İ').toUpperCase();
  }
  return text.toUpperCase();
}
