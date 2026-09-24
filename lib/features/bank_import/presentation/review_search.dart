/// İnceleme aramasının TUTAR tarafı: "913" yazan kullanıcı 913,15'lik satırı
/// bulmalı. Eskiden arama yalnız açıklamaya bakıyordu; ekstreyi elinde tutan
/// kullanıcı çoğu zaman satırı tutarından tanır.
///
/// Sorgu Türkçe yazımla yorumlanır: virgül ondalık, nokta binlik ayırıcıdır
/// ("1.234,56"). Yalnız nokta varsa ve ardından tam üç hane geliyorsa (ya da
/// birden çok nokta varsa) binlik sayılır ("1.234"); aksi hâlde ondalıktır
/// ("913.15" — İngilizce klavyeden yazan kullanıcı).
///
/// Eşleşme tutarın BAŞINDAN yapılır ("913" → 913,15 ve 9.130,00; "13" →
/// 913,15 değil): yazdıkça daralan arama böyle davranır, tutarın ortasından
/// yakalamak ise yüzlerce alakasız satır getirirdi.
bool draftAmountMatches(double amount, String rawQuery) {
  var q = rawQuery.replaceAll(RegExp(r'[\s₺$€£]'), '');
  if (q.isEmpty || !RegExp(r'^[\d.,]+$').hasMatch(q)) return false;
  if (!RegExp(r'\d').hasMatch(q)) return false;
  if (q.contains(',')) {
    q = q.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'\.\d{3}$').hasMatch(q) || '.'.allMatches(q).length > 1) {
    q = q.replaceAll('.', '');
  }
  return amount.abs().toStringAsFixed(2).startsWith(q);
}
