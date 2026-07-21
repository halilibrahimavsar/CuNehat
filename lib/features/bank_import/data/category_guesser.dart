import 'package:injectable/injectable.dart';

import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Banka ekstresi açıklamasından kategori tahmini (best-effort/tahminî).
///
/// Yalnız şu ikisi birden sağlandığında bir kategori döner: (1) açıklamada
/// bilinen bir anahtar kelime geçiyor VE (2) tahmin edilen grup adına
/// karşılık gelen kategori kullanıcının GERÇEK listesinde var (silinmemiş/
/// yeniden adlandırılmamış). Aksi halde `null` — çağıran taraf mevcut
/// varsayılana (türün ilk kategorisi) düşer; yani bu sınıf hiçbir zaman
/// önceki davranıştan daha kötü bir sonuç üretmez. Kullanıcı yine de her
/// satırın kategorisini elle değiştirebilir (bkz. inceleme ekranı).
@lazySingleton
class CategoryGuesser {
  /// Grup adları mevcut varsayılan kategori adlarıyla (`CategoryModel`)
  /// birebir eşleşecek şekilde seçildi ki kurulumdan hiç dokunulmamış
  /// kategori listesinde doğrudan tutsun.
  static const Map<String, List<String>> _expenseGroups = {
    'Yemek': [
      'starbucks', 'burger king', 'mcdonalds', "mcdonald's", ' kfc ',
      'domino', 'pizza', 'sushi', 'yemeksepeti', 'trendyol yemek',
      'restoran', 'restaurant', 'lokanta', 'cafe', 'kafe', 'simit saray',
      'kahve dunyasi', 'baklava',
    ],
    'Ulaşım': [
      'shell', 'opet', 'petrol ofisi', ' total ', 'aytemiz', 'akaryakit',
      'otopark', 'otoyol', ' hgs ', ' ogs ', ' iett ', 'istanbulkart',
      'marmaray', 'metrobus', 'taksi', 'uber', 'bitaksi', ' bolt ',
      ' marti ', 'benzin', 'motorin', ' lpg ',
    ],
    'Alışveriş': [
      'migros', 'carrefour', 'sok market', ' a101 ', ' bim ', 'market',
      'teknosa', 'mediamarkt', 'lc waikiki', 'defacto', ' koton ',
      ' zara ', 'boyner', 'trendyol', 'hepsiburada', ' n11 ', 'amazon',
      'gratis', 'watsons', 'rossmann', ' ikea ', 'decathlon', 'getir',
    ],
    'Fatura': [
      'elektrik', 'dogalgaz', ' iski ', ' aski ', 'turk telekom',
      'turkcell', 'vodafone', 'superonline', 'turknet', 'tellcom',
      'fatura', 'aidat',
    ],
    'Eğlence': [
      'netflix', 'spotify', 'youtube', 'playstation', 'steam', 'sinema',
      'cinemaximum', 'biletix', 'bilet',
    ],
  };

  static const Map<String, List<String>> _incomeGroups = {
    'Maaş': ['maas', 'salary', 'bordro'],
  };

  /// [description] içinde bilinen bir anahtar kelime bulunursa VE grup adı
  /// [candidates] (kullanıcının o türdeki kategorileri) içinde varsa o
  /// kategorinin gerçek `id`'sini döner; aksi halde `null`.
  String? guess({
    required String description,
    required bool isIncome,
    required List<CategoryEntity> candidates,
  }) {
    final norm = ' ${_normalizeTr(description)} ';
    final groups = isIncome ? _incomeGroups : _expenseGroups;
    for (final entry in groups.entries) {
      if (!entry.value.any(norm.contains)) continue;
      final normGroup = _normalizeTr(entry.key);
      for (final c in candidates) {
        if (_normalizeTr(c.id) == normGroup) return c.id;
      }
    }
    return null;
  }

  /// Türkçe aksanları sadeleştirip küçük harfe çevirir (bkz. `ColumnMapper._norm`
  /// — aynı sadeleştirme, farklı dosyada ayrı kalması bilinçli: kolon başlığı
  /// eşleşmesiyle işlem-açıklaması eşleşmesi ayrı evrilebilir).
  String _normalizeTr(String s) => s
      .replaceAll('İ', 'I')
      .replaceAll('ı', 'i')
      .replaceAll('Ş', 'S')
      .replaceAll('ş', 's')
      .replaceAll('Ğ', 'G')
      .replaceAll('ğ', 'g')
      .replaceAll('Ü', 'U')
      .replaceAll('ü', 'u')
      .replaceAll('Ö', 'O')
      .replaceAll('ö', 'o')
      .replaceAll('Ç', 'C')
      .replaceAll('ç', 'c')
      .toLowerCase()
      .trim();
}
