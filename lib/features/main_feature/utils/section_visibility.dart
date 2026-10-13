import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Ana ekranda hangi bölümlerin göründüğü: Birikim ve Borç **kullandıkça
/// açılır**; İşlemler her zaman açıktır.
///
/// Uygulamayı hiç bilmeyen biri için ana ekran üç bölümlü bir kaydırıcıyla
/// açılıyordu. Çoğu kullanıcı yalnız gelir/gider yazar (13 testerın bir kısmı
/// Birikim ve Borç'u hiç kullanmıyor); o kullanıcı için öteki iki bölüm boş
/// sayfalar ve anlamı bilinmeyen iki düğmedir. Yeni kurulum yalnız
/// İşlemler'le başlar; bölüm ilk kaydıyla ya da kullanıcı isteyince açılır.
///
/// Kurallar:
/// - **Güncellemeyle gelen kurulumda ikisi de açık kalır.** Birikim'i hiç
///   kullanmamış bir tester onu güncellemeden sonra göremezse "özellik
///   kayboldu" der; bkz. [ensureInitialized].
/// - **Açılan bölüm açık kalır** (kalıcı). Kayıt oluşunca [enable] çağrılır.
/// - **Kaydı olan bölüm kapatılamaz** ([disable]): gizli bir bölümün kaydı
///   görünen rakamları (net durum, çekmecedeki borç) değiştirmeye devam
///   ederdi.
///
/// Durum `SharedPreferences`'ta: cihaz tercihidir, yedeğe girmez. Yedeği
/// geri yüklenen kurulumda bölümler kayıtlardan yeniden açılır
/// ([syncWithRecords]).
class SectionVisibility extends ChangeNotifier {
  SectionVisibility(this._prefs)
      : _savings = _prefs.getBool(savingsKey) ?? false,
        _debt = _prefs.getBool(debtKey) ?? false;

  final SharedPreferences _prefs;

  static const String initializedKey = 'sections_initialized';
  static const String savingsKey = 'section_savings_enabled';
  static const String debtKey = 'section_debt_enabled';

  bool _savings;
  bool _debt;

  bool get savingsEnabled => _savings;
  bool get debtEnabled => _debt;

  bool isEnabled(SliderState section) => switch (section) {
        SliderState.savedMoney => _savings,
        SliderState.transactions => true,
        SliderState.debt => _debt,
      };

  /// Etkin bölümler. İşlemler ortada ve her zaman içinde olduğu için küme
  /// bitişiktir: {İşlemler}, {Birikim, İşlemler}, {İşlemler, Borç} ya da hepsi.
  Set<SliderState> get enabledStates => {
        if (_savings) SliderState.savedMoney,
        SliderState.transactions,
        if (_debt) SliderState.debt,
      };

  /// Tek bölüm varken kaydıracak bir şey yoktur: kaydırıcı yerine sade
  /// Gelir/Gider çubuğu gösterilir.
  bool get hasOnlyTransactions => !_savings && !_debt;

  /// İlk çalıştırmada başlangıç durumunu yazar; sonraki açılışlarda dokunmaz.
  ///
  /// [existingInstall]: bu sürümden ÖNCE kullanılmış bir kurulum mu. Öyleyse
  /// iki bölüm de açık başlar — kullanıcının alıştığı ekran değişmez.
  Future<void> ensureInitialized({required bool existingInstall}) async {
    if (_prefs.getBool(initializedKey) ?? false) return;
    _savings = existingInstall;
    _debt = existingInstall;
    await _prefs.setBool(savingsKey, _savings);
    await _prefs.setBool(debtKey, _debt);
    await _prefs.setBool(initializedKey, true);
    notifyListeners();
  }

  /// [section]'ı açar (kalıcı). Zaten açıksa hiçbir şey yapmaz.
  Future<void> enable(SliderState section) async {
    switch (section) {
      case SliderState.savedMoney:
        if (_savings) return;
        _savings = true;
        await _prefs.setBool(savingsKey, true);
      case SliderState.debt:
        if (_debt) return;
        _debt = true;
        await _prefs.setBool(debtKey, true);
      case SliderState.transactions:
        return;
    }
    notifyListeners();
  }

  /// [section]'ı kapatır. Kapatıldıysa `true`.
  ///
  /// [hasRecords] true ise KAPATMAZ ve `false` döner (bkz. sınıf belgesi).
  /// İşlemler kapatılamaz.
  Future<bool> disable(
    SliderState section, {
    required bool hasRecords,
  }) async {
    if (hasRecords) return false;
    switch (section) {
      case SliderState.savedMoney:
        if (!_savings) return true;
        _savings = false;
        await _prefs.setBool(savingsKey, false);
      case SliderState.debt:
        if (!_debt) return true;
        _debt = false;
        await _prefs.setBool(debtKey, false);
      case SliderState.transactions:
        return false;
    }
    notifyListeners();
    return true;
  }

  /// Kaydı olan bölümleri açar; hiçbirini KAPATMAZ.
  ///
  /// Açılışta ve yedek geri yüklendikten sonra çağrılır: tercih cihazda
  /// durduğu için, yedeğini yeni telefonuna yükleyen kullanıcının birikimi
  /// kapalı bir bölümün arkasında kalabilirdi.
  Future<void> syncWithRecords({
    required bool savingsHasRecords,
    required bool debtHasRecords,
  }) async {
    if (savingsHasRecords) await enable(SliderState.savedMoney);
    if (debtHasRecords) await enable(SliderState.debt);
  }
}
