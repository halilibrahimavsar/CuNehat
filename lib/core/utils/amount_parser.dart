/// Parasal girdi alanları için ortak ayrıştırma/doğrulama/biçimleme.
///
/// İki aile vardır:
/// - [parseAmount]/[parseMoney]/[validateAmount]: CSV gibi dış kaynaklı ham
///   metin için; tek ayraç (virgül YA DA nokta) ondalıktır.
/// - `...Input` türevleri: [AmountInputFormatter] takılı UI alanları için;
///   bu alanlarda nokta HER ZAMAN binlik gruplama, virgül ondalıktır
///   ("1.234,56"). Formatter'lı alan metnini asla [parseAmount]'a vermeyin
///   ("1.234" → 1.234 okunur, 1234 değil).
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

// ---------------------------------------------------------------------------
// Binlik ayraçlı giriş alanları (AmountInputFormatter ile eşleşen aile)
// ---------------------------------------------------------------------------

/// Formatter'lı alan metnini sade forma çevirir: "1.234,56" → "1234.56".
/// Noktalar gruplama sayılıp atılır; yalnız UI girişi için, CSV'de kullanmayın.
String normalizeAmountInput(String input) =>
    input.trim().replaceAll('.', '').replaceAll(',', '.');

/// Binlik ayraçlı giriş metnini ayrıştırır. Yuvarlama yapmaz (adet/oran).
double? parseAmountInput(String input) {
  final raw = normalizeAmountInput(input);
  if (raw.isEmpty) return null;
  return double.tryParse(raw);
}

/// Binlik ayraçlı giriş metninden para tutarı: ayrıştırma + kuruşa yuvarlama.
double? parseMoneyInput(String input) {
  final v = parseAmountInput(input);
  return v == null ? null : roundToCents(v);
}

/// [validateAmount]'ın binlik ayraçlı giriş alanları için karşılığı.
String? validateAmountInput(
  String input, {
  bool allowZero = false,
  double? max,
  String? maxExceededMessage,
}) {
  return validateAmount(
    normalizeAmountInput(input),
    allowZero: allowZero,
    max: max,
    maxExceededMessage: maxExceededMessage,
  );
}

/// Rakam dizisini sağdan üçerli noktayla gruplar: "1234567" → "1.234.567".
String groupThousands(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Bir tutarı giriş alanına yazılacak biçime çevirir: 1234.5 → "1.234,5".
/// En çok [decimalDigits] hane gösterir, sondaki sıfırları atar. Alan
/// metinleri programatik yazılırken (ön doldurma, hızlı seçim, otomatik
/// öneri) formatter devreye girmediğinden bu fonksiyon kullanılmalıdır.
/// Kuruş-temiz para için varsayılan yeter; oran/adet gibi hassas alanlarda
/// [decimalDigits] artırılabilir (saklanan değeri kırpmamak için).
String formatAmountForInput(double v, {int decimalDigits = 2}) {
  final negative = v < 0;
  var s = v.abs().toStringAsFixed(decimalDigits);
  if (decimalDigits > 0) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  final dot = s.indexOf('.');
  final intPart = dot >= 0 ? s.substring(0, dot) : s;
  final decPart = dot >= 0 ? s.substring(dot + 1) : '';
  final grouped = groupThousands(intPart);
  final out = decPart.isEmpty ? grouped : '$grouped,$decPart';
  return negative ? '-$out' : out;
}
