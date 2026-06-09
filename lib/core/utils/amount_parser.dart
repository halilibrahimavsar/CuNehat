/// Parasal girdi alanları için ortak ayrıştırma/doğrulama.
///
/// Tüm formlar (işlem, cüzdan, borç/alacak, yatırım) kullanıcı tutarını
/// buradan geçirir; virgül/nokta ondalık ayracı ve üst sınır tek yerde
/// tanımlı kalır.
library;

/// Kabul edilen en büyük tutar; double hassasiyeti içinde güvenli bölge.
const double kMaxAmount = 999999999;

/// Trim + `,` → `.` normalize edip ayrıştırır. Ayrıştırılamazsa `null`.
double? parseAmount(String input) {
  final raw = input.trim().replaceAll(',', '.');
  if (raw.isEmpty) return null;
  return double.tryParse(raw);
}

/// Geçerliyse `null`, değilse Türkçe hata mesajı döndürür.
String? validateAmount(String input, {bool allowZero = false}) {
  final amount = parseAmount(input);
  if (amount == null) return 'Geçerli bir tutar girin';
  if (amount < 0 || (!allowZero && amount == 0)) {
    return 'Tutar sıfırdan büyük olmalı';
  }
  if (amount > kMaxAmount) return 'Tutar çok büyük';
  return null;
}
