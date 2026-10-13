import 'dart:math' as math;

import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Tutarlar yeşil ve kırmızı YAZILIYOR. Vurgu renkleri (`MoneyColors.income`
/// / `expense`) açık zeminde yazı olarak okunmuyordu: gelir yeşili beyaz
/// kartta 2,5:1, gider kırmızısı 3,7:1 (AA alt sınırı 4,5:1).
void main() {
  final themes = {
    'açık': ThemeNames.all[ThemeNames.sysLight]!,
    'koyu': ThemeNames.all[ThemeNames.sysDark]!,
  };

  for (final entry in themes.entries) {
    final theme = entry.value;
    final brightness = theme.brightness;
    final page = theme.colorScheme.surface;
    final card = theme.extension<AppSurface>()!.baseColor;

    test('${entry.key}: gelir metni sayfa ve kart zemininde okunur (4,5:1)',
        () {
      final color = MoneyColors.incomeText(brightness);
      expect(_contrast(color, page), greaterThanOrEqualTo(4.5));
      expect(_contrast(color, card), greaterThanOrEqualTo(4.5));
    });

    test('${entry.key}: gider metni sayfa ve kart zemininde okunur (4,5:1)',
        () {
      final color = MoneyColors.expenseText(brightness);
      expect(_contrast(color, page), greaterThanOrEqualTo(4.5));
      expect(_contrast(color, card), greaterThanOrEqualTo(4.5));
    });

    test('${entry.key}: işaretli tutar işaretine göre boyanır', () {
      expect(
        MoneyColors.signedText(10, brightness),
        MoneyColors.incomeText(brightness),
      );
      expect(
        MoneyColors.signedText(0, brightness),
        MoneyColors.incomeText(brightness),
      );
      expect(
        MoneyColors.signedText(-10, brightness),
        MoneyColors.expenseText(brightness),
      );
    });
  }

  test('açık temada vurgu renkleri yazı için YETERSİZ (neden ayrı ton var)',
      () {
    // Bu test vurgu rengi koyulaştırılırsa düşer: o gün metin tonları
    // gereksizleşir ve kaldırılabilir.
    const white = Color(0xFFFFFFFF);
    expect(_contrast(MoneyColors.income, white), lessThan(4.5));
    expect(_contrast(MoneyColors.expense, white), lessThan(4.5));
  });
}
