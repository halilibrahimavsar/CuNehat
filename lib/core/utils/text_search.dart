/// Kullanıcı metni karşılaştırma/arama için TEK normalizasyon noktası.
///
/// `toLowerCase()` tek başına Türkçe'de yanlıştır ve bu iki yönlü bozar:
/// - 'İ'.toLowerCase() Dart'ta 'i̇' (i + U+0307 birleşen nokta) üretir; 'i'
///   ile eşleşmez. Yani "İnternet" araması "internet" faturasını bulamaz.
/// - 'I'.toLowerCase() 'i' verir, 'ı' değil. "Işık" araması "ışık"ı bulamaz.
///
/// Bu yüzden büyük harfler ÖNCE elle katlanır, sonra küçültme yapılır.
library;

/// Türkçe-duyarlı katlama: büyük harfleri eşle, küçült, kırp, iç boşlukları
/// tekle. Aynı sözcüğün farklı yazımları tek anahtara iner.
String foldTr(String input) {
  final folded = input
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç')
      .toLowerCase();
  return folded.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// [haystack] içinde [foldedQuery] geçiyor mu?
///
/// [foldedQuery] ZATEN [foldTr]'den geçmiş olmalıdır — sorgu tuş başına bir
/// kez katlanır, aday satır başına değil.
bool matchesFolded(String haystack, String foldedQuery) {
  if (foldedQuery.isEmpty) return true;
  return foldTr(haystack).contains(foldedQuery);
}
