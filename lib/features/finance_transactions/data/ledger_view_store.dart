import 'package:shared_preferences/shared_preferences.dart';

/// İşlemler ekranının görünümü.
enum LedgerView {
  /// Bakiye hattı + gün fişi (varsayılan).
  balanceLine,

  /// Gün başlıklı defter listesi.
  list,
}

/// Kullanıcının seçtiği görünüm. Cihaz tercihi: yedeğe girmez, Hive şeması
/// değişmez (bkz. [PeriodPreferencesStore] — aynı kalıp).
class LedgerViewStore {
  const LedgerViewStore(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'ledger_view';

  /// Bakiye hattının tanıtım şeridi görüldü mü (bir kez gösterilir).
  static const String introKey = 'ledger_view_intro_seen';

  LedgerView read() =>
      LedgerView.values
          .where((v) => v.name == _prefs.getString(key))
          .firstOrNull ??
      LedgerView.balanceLine;

  Future<void> write(LedgerView view) => _prefs.setString(key, view.name);

  /// Tanıtım şeridi gösterilmeli mi. Güncellemeyle varsayılan görünüm
  /// listeden bakiye hattına geçti; listesi "kaybolan" kullanıcı geri dönüşü
  /// yazısız bir ikonda arıyordu (QA O6). Görünümü bir kez bile elle seçen
  /// kullanıcı geçişi zaten biliyor: ona gösterilmez.
  bool introSeen() =>
      _prefs.getBool(introKey) == true || _prefs.containsKey(key);

  Future<void> markIntroSeen() => _prefs.setBool(introKey, true);
}
