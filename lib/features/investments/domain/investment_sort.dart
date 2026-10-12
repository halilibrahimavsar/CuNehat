import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

/// Birikim sayfasındaki listelerin (kasalar, hedef üyeleri, bağsız
/// varlıklar) sıralama ölçütü.
enum InvestmentSort {
  /// Güncel değer, büyükten küçüğe.
  value,

  /// Eklenme tarihi, yeniden eskiye.
  date,

  /// Ad, A'dan Z'ye (Türkçe duyarlı).
  name,
}

/// [items]'ı [sort]'a göre sıralar; girdi değişmez.
///
/// Eşitlikte sıra BELİRLENİMLİ kalır (ad, sonra kimlik): iki kaydın değeri
/// aynıyken liste her yenilemede yer değiştirmemeli.
List<InvestmentEntity> sortInvestments(
  Iterable<InvestmentEntity> items,
  InvestmentSort sort,
) {
  int byName(InvestmentEntity a, InvestmentEntity b) {
    final n = _trSortKey(a.name).compareTo(_trSortKey(b.name));
    return n != 0 ? n : (a.id ?? '').compareTo(b.id ?? '');
  }

  int compare(InvestmentEntity a, InvestmentEntity b) {
    final primary = switch (sort) {
      InvestmentSort.value => b.currentValue.compareTo(a.currentValue),
      InvestmentSort.date => b.dateAdded.compareTo(a.dateAdded),
      InvestmentSort.name => 0,
    };
    return primary != 0 ? primary : byName(a, b);
  }

  return [...items]..sort(compare);
}

/// Türk alfabesi sırası (q, w, x yerlerinde).
const String _trAlphabet = 'abcçdefgğhıijklmnoöpqrsştuüvwxyz';

/// Ada göre sıralama anahtarı: harfler Türk alfabesindeki SIRASINA çevrilir.
///
/// [foldTr] yalnız büyük/küçük harfi eşler; kod noktası sırası yine yanlış
/// kalır ('ç' U+00E7, 'z'den SONRA gelir) ve "Çeyrek", "Zeytin"in ardına
/// düşerdi. Harf olmayan karakterler (rakam, boşluk) kendi kod noktasıyla
/// kalır ve harflerden önce sıralanır.
String _trSortKey(String name) {
  final folded = foldTr(name);
  final buffer = StringBuffer();
  for (final rune in folded.runes) {
    final at = _trAlphabet.indexOf(String.fromCharCode(rune));
    buffer.writeCharCode(at < 0 ? rune : 0x2000 + at);
  }
  return buffer.toString();
}
