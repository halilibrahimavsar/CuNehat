import 'package:shared_preferences/shared_preferences.dart';

/// Üst çubuktaki cüzdan karuselinin tek seferlik "göz kırpma" ipucu.
///
/// Başlığın yana kaydırılabildiğini gösteren tek işaret rozetteki noktalar;
/// ikinci cüzdanını yeni kuran kullanıcıya başlık bir kez komşu cüzdana doğru
/// kıpırdayıp geri döner. Bir kez oynar (bkz. `SliderPeekStore` — aynı kalıp).
class WalletCarouselHintStore {
  const WalletCarouselHintStore(this._prefs);

  final SharedPreferences _prefs;

  static const String seenKey = 'wallet_carousel_hint_seen';

  bool get seen => _prefs.getBool(seenKey) ?? false;

  Future<void> markSeen() => _prefs.setBool(seenKey, true);
}
