import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının "Yoksay" dediği düzenli ödeme önerilerinin kalıcılığı.
///
/// Kalıcı olmak zorunda: öneri geçmiş işlemlerden HER AÇILIŞTA yeniden
/// türetilir. Yalnız bellekte tutulan bir yoksayma, uygulama kapanınca
/// unutulur ve kullanıcının istemediği örüntü (nakit çekme, arkadaşa
/// gönderilen sabit tutar) geri gelirdi — tek kurtuluş şablonu gerçekten
/// eklemek olurdu.
///
/// **Cüzdan bazlı DEĞİL:** yoksayma "bu başlığı düzenli ödeme diye önerme"
/// demektir; başlık cüzdandan bağımsızdır. Cüzdana bağlansaydı silinen her
/// cüzdan ardında öksüz bir anahtar bırakırdı.
class RecurringSuggestionDismissStore {
  const RecurringSuggestionDismissStore(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'recurring_suggestion_dismissed';

  Set<String> read() => (_prefs.getStringList(key) ?? const <String>[]).toSet();

  Future<void> add(String suggestionKey) async {
    final next = read()..add(suggestionKey);
    await _prefs.setStringList(key, next.toList());
  }
}
