/// Kullanıcı metni karşılaştırma/arama için TEK normalizasyon noktası.
///
/// `toLowerCase()` tek başına Türkçe'de yanlıştır: 'I'.toLowerCase() 'i'
/// verir, 'ı' değil. Yani "Işık" araması "ışık"ı bulamaz — ve ekstre gibi
/// BÜYÜK HARF yazılmış metinlerde ("IŞIK" → "işik") kullanıcının doğal
/// yazımıyla hiçbir zaman eşleşmez.
///
/// (Ölçüldü, Dart 3.12: 'İ'.toLowerCase() düz 'i' üretiyor — birleşen noktalı
/// biçim değil. Yani bozan yön yalnız noktasız I; katlama yine de iki yönü de
/// tek anahtara indiriyor.)
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
