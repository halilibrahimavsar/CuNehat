/// Ekstre metninde baskın para birimini (varsa) sezer. Amaç: kullanıcı bir
/// USD ekstresini TRY cüzdana (ya da tersi) aktarırken tutarların sessizce
/// karışmasını önlemek — inceleme ekranında uyarı göstermek için.
///
/// Yalnız açık bir sinyal (₺/$/€ simgesi ya da TRY/TL/USD/EUR kodu) varsa
/// döner; simgesiz sade sayılardan tahmin yapmaz (yanlış-pozitif olmasın).
/// Saf/test-edilebilir.
library;

/// Metinde en çok geçen para birimi kodunu ('TRY'|'USD'|'EUR') döner; hiç
/// belirgin sinyal yoksa `null`.
String? detectDominantCurrency(String text) {
  final counts = <String, int>{
    'TRY': '₺'.allMatches(text).length +
        RegExp(r'\b(TRY|TL)\b', caseSensitive: false).allMatches(text).length,
    'USD': r'$'.allMatches(text).length +
        RegExp(r'\bUSD\b', caseSensitive: false).allMatches(text).length,
    'EUR': '€'.allMatches(text).length +
        RegExp(r'\bEUR\b', caseSensitive: false).allMatches(text).length,
  };

  String? best;
  var bestCount = 0;
  counts.forEach((code, count) {
    if (count > bestCount) {
      bestCount = count;
      best = code;
    }
  });
  return bestCount == 0 ? null : best;
}
