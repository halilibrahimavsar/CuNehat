/// Parasal girdi alanları için ortak ayrıştırma/doğrulama.
///
/// Tüm formlar (işlem, cüzdan, borç/alacak, yatırım) kullanıcı tutarını
/// buradan geçirir; virgül/nokta ondalık ayracı ve üst sınır tek yerde
/// tanımlı kalır.
library;

import 'package:cunehat/core/utils/money_math.dart';

/// Kabul edilen en büyük tutar; double hassasiyeti içinde güvenli bölge.
const double kMaxAmount = 999999999;

/// Trim + `,` → `.` normalize edip ayrıştırır. Ayrıştırılamazsa `null`.
///
/// Yuvarlama YAPMAZ: yatırım adedi ve faiz oranı gibi para olmayan alanlar
/// da bunu kullanır. Para alanları için [parseMoney] kullanın.
double? parseAmount(String input) {
  final raw = input.trim().replaceAll(',', '.');
  if (raw.isEmpty) return null;
  return double.tryParse(raw);
}

/// Para tutarı ayrıştırma: [parseAmount] + kuruşa yuvarlama.
/// Kaydedilecek her parasal değer buradan geçmeli ki depo kuruş-temiz kalsın.
double? parseMoney(String input) {
  final v = parseAmount(input);
  return v == null ? null : roundToCents(v);
}

/// Geçerliyse `null`, değilse Türkçe hata mesajı döndürür.
///
/// [max] verilirse tutar yarım kuruş toleransıyla üst sınıra karşı denetlenir
/// (314.56, kalan 314.5599… iken geçer); mesajı [maxExceededMessage] sağlar —
/// l10n çağıran tarafta kalır.
String? validateAmount(
  String input, {
  bool allowZero = false,
  double? max,
  String? maxExceededMessage,
}) {
  assert(max == null || maxExceededMessage != null,
      'max verildiğinde maxExceededMessage zorunlu');
  final amount = parseAmount(input);
  if (amount == null) return 'Geçerli bir tutar girin';
  if (amount < 0 || (!allowZero && amount == 0)) {
    return 'Tutar sıfırdan büyük olmalı';
  }
  if (amount > kMaxAmount) return 'Tutar çok büyük';
  if (max != null && moneyGreaterThan(amount, max)) {
    return maxExceededMessage;
  }
  return null;
}
