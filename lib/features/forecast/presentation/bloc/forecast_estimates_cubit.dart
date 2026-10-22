import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tahmin katmanı açık mı (uygulama geneli tek ayar).
///
/// Kapalıyken (VARSAYILAN) Gelecek, bakiye hattının gelecek kısmı, gün fişi
/// ve bütçe gidişatı yalnız PLANLI kalemleri gösterir: şablon, taksit, kredi,
/// kesilmiş ekstre — tarihleriyle, kesin. Açıkken bunların üstüne hızdan ve
/// beklentiden türeyen kısım MOR olarak eklenir; plan içeriği değişmez.
///
/// Cihaz tercihi: yedeğe girmez, Hive şeması değişmez (bkz.
/// `LedgerViewStore`). Tahmin bildirimleri bu ayardan BAĞIMSIZDIR (kendi
/// ayarları Bildirimler'de).
class ForecastEstimatesCubit extends Cubit<bool> {
  ForecastEstimatesCubit(this._prefs) : super(_prefs.getBool(key) ?? false);

  final SharedPreferences _prefs;

  static const String key = 'forecast_estimates_enabled';

  Future<void> set(bool enabled) async {
    if (enabled == state) return;
    emit(enabled);
    await _prefs.setBool(key, enabled);
  }
}

extension ForecastEstimatesContext on BuildContext {
  /// Tahmin katmanı açık mı? `watch`: anahtar çevrilince her yüzey yeniden
  /// çizilir. Cubit sağlanmamış bağlamda (yalıtılmış testler) `false` —
  /// varsayılanla aynı. Yalnız build içinde okunur.
  bool get forecastEstimates {
    try {
      return watch<ForecastEstimatesCubit>().state;
    } on ProviderNotFoundException {
      return false;
    }
  }
}
