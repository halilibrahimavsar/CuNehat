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

  LedgerView read() =>
      LedgerView.values
          .where((v) => v.name == _prefs.getString(key))
          .firstOrNull ??
      LedgerView.balanceLine;

  Future<void> write(LedgerView view) => _prefs.setString(key, view.name);
}
