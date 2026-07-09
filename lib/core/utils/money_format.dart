import 'package:cunehat/core/utils/currencies.dart';

/// Tek noktadan para metni. Varsayılan TRY ile mevcut çıktıyla bayt-aynı
/// (binlik ayraç yok); tr_TR NumberFormat'a geçiş post-1.0 işi —
/// o zaman yalnız bu fonksiyon değişir. Cüzdan kapsamlı görünümler
/// [currency] ile cüzdanın birimini geçer.
String formatMoney(double amount,
        {int decimals = 2, String currency = kDefaultCurrency}) =>
    '${amount.toStringAsFixed(decimals)} ${currencySymbol(currency)}';

/// Dar alanlar (takvim hücreleri, rozetler) için kısaltılmış para metni.
/// Örn: 1500 → "1.5K", 2.400.000 → "2.4M", 320 → "320". [symbol] true ise
/// sonuna birim sembolü eklenir. Yaklaşıktır; tam değer için [formatMoney].
String formatMoneyCompact(double amount,
    {bool symbol = true, String currency = kDefaultCurrency}) {
  final suffix = symbol ? ' ${currencySymbol(currency)}' : '';
  final sign = amount < 0 ? '-' : '';
  final abs = amount.abs();

  String body;
  if (abs >= 1000000) {
    body = '${_trimZero(abs / 1000000)}M';
  } else if (abs >= 1000) {
    body = '${_trimZero(abs / 1000)}K';
  } else {
    body = abs.toStringAsFixed(0);
  }
  return '$sign$body$suffix';
}

/// 1.0 → "1", 1.2 → "1.2" (tek ondalık, gereksiz ".0" kırpılır).
String _trimZero(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
