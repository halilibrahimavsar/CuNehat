import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Dikey navigasyon tanıtımının ("peek") kalıcılığı.
///
/// Her ana durum için AYRI bayrak: kullanıcı yalnız İşlemler'i kullanıp
/// Borç'a hiç girmediyse, Borç'a ilk girdiğinde tanıtımı orada da görmeli.
class SliderPeekStore {
  const SliderPeekStore(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(SliderState state) => 'slider_peek_seen_${state.name}';

  /// Henüz tanıtılmamış durumlar.
  Set<SliderState> pending() => SliderState.values
      .where((state) => !(_prefs.getBool(keyFor(state)) ?? false))
      .toSet();

  Future<void> markSeen(SliderState state) =>
      _prefs.setBool(keyFor(state), true);
}

/// Dikey navigasyon tanıtımı ("peek") şu an oynayabilir mi?
///
/// İnteraktif tur tam ekran bir overlay çiziyor. Kabuk turunun üçüncü adımı
/// zaten kaydırıcıyı gösterip dikey sürüklemeyi ANLATIYOR
/// (`OnboardingNavigationHintCard`); tanıtım aynı anda oynarsa hem overlay'in
/// arkasında harcanır hem de kalıcı bayrağı yazılıp bir daha oynamaz.
///
/// Kilitlenme yok: kabuk turu başlarken `_pending`den düşüp `runningFlow`a
/// geçer, bitince ikisi de temizlenir; tur zaten görülmüşse hiç istenmez ve
/// kapı en baştan açıktır.
bool isSliderPeekAllowed(OnboardingCoordinator coordinator) =>
    coordinator.runningFlow == null &&
    !coordinator.isPending(OnboardingFlow.shell);
