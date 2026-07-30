/// Uygulamadaki TEK para gösterim noktası. Parasal bir sayı ekrana
/// yazılacaksa buradan geçer — `toStringAsFixed`, `NumberFormat.currency`
/// ya da elle sembol ekleme YOK.
///
/// Biçim: locale'in binlik/ondalık ayracı + SONEK sembol —
/// tr'de `1.234,50 ₺`, en'de `1,234.50 ₺`. Sembolün sonda olması bilinçli
/// (bkz. `currencies.dart`); `NumberFormat.currency` sembolü öne alırdı
/// (`₺1.234,50`), o yüzden sayı gövdesi `decimalPatternDigits` ile üretilip
/// sembol elle eklenir.
///
/// Locale `Intl.defaultLocale`'den gelir; tarih biçimleyicileri
/// (`AppFormatters`) de aynı kaynağa bakar. Uygulamada bu değeri LanguageBloc
/// açılışta yazar (kayıtlı dil, yoksa `tr`), yani gerçek çalışmada seçili dil
/// neyse para da odur.
///
/// DİKKAT — testlerde: `Intl.defaultLocale` boşken `intl` ilk biçimlendirmede
/// onu SESSİZCE sistem locale'ine bağlar (intl.dart: `defaultLocale ??=
/// systemLocale`). Test makinesinde bu genelde `en_US`'tir, yani para metnini
/// doğrulayan testler locale'i açıkça sabitlemelidir
/// (`Intl.defaultLocale = 'tr'`) — yoksa sonuç makineye göre değişir.
library;

import 'package:cunehat/core/utils/currencies.dart';
import 'package:intl/intl.dart';

/// Dil seçimi yapılmadan önceki varsayılan; LanguageBloc de aynı değere düşer.
const String _fallbackLocale = 'tr';

/// [amount] için para metni. [symbol] false ise birim sembolü eklenmez
/// (sembolü ayrı bir widget'ta gösteren yerler için).
String formatMoney(
  double amount, {
  int decimals = 2,
  String currency = kDefaultCurrency,
  bool symbol = true,
}) {
  final body = formatMoneyNumber(amount, decimals: decimals);
  return symbol ? '$body ${currencySymbol(currency)}' : body;
}

/// Para metninin yalnız sayı gövdesi (sembolsüz): `1.234,50`.
///
/// `double`'ın kayan-nokta sapması (0.1+0.2 = 0.30000000000000004) burada
/// yuvarlanır; kullanıcı her zaman [decimals] haneli doğru tutarı görür.
String formatMoneyNumber(double amount, {int decimals = 2}) {
  final text = _decimalFormat(decimals).format(amount);
  // Sıfıra yuvarlanan küçük negatifler "-0,00" yazardı; işareti düşür.
  if (text.startsWith('-') && !text.contains(_anyNonZeroDigit)) {
    return text.substring(1);
  }
  return text;
}

/// Dar alanlar (takvim hücreleri, grafik ekseni, rozetler) için kısaltılmış
/// para metni. Örn: 1500 → "1,5K", 2.400.000 → "2,4M", 320 → "320".
/// [symbol] true ise sonuna birim sembolü eklenir. Yaklaşıktır; tam değer
/// için [formatMoney].
String formatMoneyCompact(
  double amount, {
  bool symbol = true,
  String currency = kDefaultCurrency,
}) {
  final suffix = symbol ? ' ${currencySymbol(currency)}' : '';
  final abs = amount.abs();

  final String body;
  if (abs >= 1000000) {
    body = '${_trimZero(abs / 1000000)}M';
  } else if (abs >= 1000) {
    body = '${_trimZero(abs / 1000)}K';
  } else {
    body = formatMoneyNumber(abs, decimals: 0);
  }
  // İşaret gövdeden sonra eklenir: kısaltma sıfıra inebilir ("-0,4K" değil).
  final sign = amount < 0 && body != '0' ? '-' : '';
  return '$sign$body$suffix';
}

/// 1.0 → "1", 1.2 → "1,2" (tek ondalık, gereksiz sıfır kırpılır).
String _trimZero(double v) {
  final format = _decimalFormat(1);
  final s = format.format(v);
  final zeroDecimal = '${format.symbols.DECIMAL_SEP}0';
  return s.endsWith(zeroDecimal)
      ? s.substring(0, s.length - zeroDecimal.length)
      : s;
}

final RegExp _anyNonZeroDigit = RegExp('[1-9]');

NumberFormat _decimalFormat(int decimals) => NumberFormat.decimalPatternDigits(
      locale: Intl.defaultLocale ?? _fallbackLocale,
      decimalDigits: decimals,
    );
