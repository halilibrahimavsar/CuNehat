import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kategori seçicideki "son kullanılanlar" şeridinin kaynağı.
///
/// **Neden işlem defterinden TÜRETİLMİYOR:** seçici banka ekstresi
/// incelemesinden de açılıyor ve orada henüz kaydedilmiş işlem yok; ayrıca bir
/// kolaylık şeridi için her açılışta defteri taramak pahalı.
///
/// Bu bir **önbellektir, gerçeğin kaynağı değil.** Kaybolursa birkaç seçimde
/// kendini yeniden doldurur; bu yüzden Hive'a değil `SharedPreferences`'a
/// yazılır, yedeğe girmez ve `DataSerializationService.schemaVersion`'ı
/// ETKİLEMEZ — kapalı test sürerken şema dokunulmazlığı için bu önemli
/// (bkz. `CLAUDE.md`).
///
/// Silinmiş kategorilerin kimlikleri listede kalabilir; çözümleme sırasında
/// eşleşmeyen kimlikler sessizce düşer (bkz. `CategoryPickerSheet`), o yüzden
/// kategori silmede ayrıca temizlik kancası gerekmez.
@lazySingleton
class RecentCategoriesService {
  final SharedPreferences _prefs;

  RecentCategoriesService(this._prefs);

  /// Şeritte tutulacak en fazla kayıt.
  static const int maxEntries = 6;

  /// Gelir ve gider ayrı listeler: seçici zaten tek seferde tek türü gösteriyor
  /// ve karışık liste kullanıcıya seçemeyeceği çipler gösterirdi.
  static String _key(bool isExpense) =>
      isExpense ? 'recent_categories_expense' : 'recent_categories_income';

  /// En son kullanılan kategori kimlikleri, yeniden eskiye.
  List<String> ids(bool isExpense) =>
      _prefs.getStringList(_key(isExpense)) ?? const [];

  /// [id]'yi listenin başına taşır. Zaten varsa kopyalanmaz, TAŞINIR — aksi
  /// halde sık kullanılan bir kategori şeridi tek başına doldururdu.
  Future<void> remember(String id, bool isExpense) async {
    final key = _key(isExpense);
    final current = List<String>.from(_prefs.getStringList(key) ?? const []);
    current
      ..remove(id)
      ..insert(0, id);
    if (current.length > maxEntries) {
      current.removeRange(maxEntries, current.length);
    }
    await _prefs.setStringList(key, current);
  }
}
