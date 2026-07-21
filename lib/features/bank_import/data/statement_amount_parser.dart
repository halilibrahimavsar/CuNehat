/// Banka ekstresi tutar hücrelerini ayrıştırır. Fiş parser'ının aksine İŞARETİ
/// KORUR (gider/gelir yönü tutardan gelebilir).
///
/// Ayraç sezgisi (nokta binlik mi, virgül ondalık mı) mevcut
/// [parseMoneyToken]'dan (lib/core/utils/receipt_text_parser.dart) yeniden
/// kullanılır; o işareti düşürdüğü için işaret burada ayrıca tespit edilip
/// yeniden uygulanır.
library;

import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/utils/receipt_text_parser.dart';

/// İşaretli parasal değer: negatif = gider. Muhasebe parantezi `(90,00)` = -90.
/// Ayrıştırılamazsa null. Sonuç kuruşa yuvarlı.
double? parseSignedMoney(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final magnitude = parseMoneyToken(s); // pozitif büyüklük (işaret düşer)
  if (magnitude == null) return null;
  final negative = s.contains('-') || (s.startsWith('(') && s.endsWith(')'));
  return roundToCents(negative ? -magnitude : magnitude);
}

/// İşaretsiz büyüklük (borç/alacak sütunu değerleri için). Boş/sıfır → null.
/// Sonuç kuruşa yuvarlı ve pozitif.
double? parseUnsignedMoney(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final magnitude = parseMoneyToken(s);
  if (magnitude == null) return null;
  final rounded = roundToCents(magnitude.abs());
  return rounded == 0 ? null : rounded;
}
