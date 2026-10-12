import 'package:cunehat/features/investments/domain/investment_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Birikim sayfasının sıralama tercihini cihazda saklar (bkz.
/// `PeriodPreferencesStore` — aynı kalıp). Bilinmeyen/bozuk değer
/// varsayılana düşer.
class InvestmentSortStore {
  const InvestmentSortStore(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'investment_sort';

  /// Varsayılan: büyükten küçüğe — portföyde en çok yer tutan en üstte.
  static const InvestmentSort fallback = InvestmentSort.value;

  InvestmentSort read() {
    final name = _prefs.getString(key);
    return InvestmentSort.values.where((s) => s.name == name).firstOrNull ??
        fallback;
  }

  Future<void> write(InvestmentSort sort) => _prefs.setString(key, sort.name);
}
