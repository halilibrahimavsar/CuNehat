import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class NotificationSettingsService {
  final SharedPreferences _prefs;

  static const String _keyRandomFrequency = 'notification_random_frequency';
  static const String _keyEnableDebt = 'notification_enable_debt';
  static const String _keyEnableRecurring = 'notification_enable_recurring';
  static const String _keyEnableBudget = 'notification_enable_budget';
  static const String _keyForecastWarnings =
      'notification_enable_forecast_warnings';
  static const String _keyWeeklyDigest = 'notification_enable_weekly_digest';
  static const String _keyWeeklyDigestOffered =
      'notification_weekly_digest_offered';

  /// Eski sürümlerin motivasyon aralığına yazdığı TEK ATIŞLIK planların bir
  /// kez temizlendiğini işaretler.
  static const String _keyLegacyRandomPurged =
      'notification_legacy_random_purged';

  NotificationSettingsService(this._prefs);

  /// Eski (14 günlük rastgele) planlar temizlendi mi?
  ///
  /// Temizlik 60 kimliği tek tek iptal ediyor ve plugin HER iptalde planlı
  /// bildirim listesinin tamamını JSON'a serileştirip prefs'e yazıyor. Bu
  /// yüzden her açılışta değil, YALNIZ BİR KEZ yapılır.
  bool get isLegacyRandomRangePurged =>
      _prefs.getBool(_keyLegacyRandomPurged) ?? false;

  Future<void> markLegacyRandomRangePurged() async {
    await _prefs.setBool(_keyLegacyRandomPurged, true);
  }

  NotificationFrequency getRandomFrequency() {
    final val = _prefs.getString(_keyRandomFrequency);
    return NotificationFrequencyExtension.fromValueString(val);
  }

  Future<void> setRandomFrequency(NotificationFrequency frequency) async {
    await _prefs.setString(_keyRandomFrequency, frequency.toValueString());
  }

  bool get isDebtRemindersEnabled {
    return _prefs.getBool(_keyEnableDebt) ?? true; // Default true
  }

  Future<void> setDebtRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyEnableDebt, enabled);
  }

  bool get isRecurringRemindersEnabled {
    return _prefs.getBool(_keyEnableRecurring) ?? true; // Default true
  }

  Future<void> setRecurringRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyEnableRecurring, enabled);
  }

  bool get isBudgetAlertsEnabled {
    return _prefs.getBool(_keyEnableBudget) ?? true; // Default true
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_keyEnableBudget, enabled);
  }

  /// Tahmine dayalı erken uyarılar ("bu hızla 6 gün erken dolacak", "bakiye
  /// eksiye düşebilir"). Varsayılan AÇIK: bütçe uyarıları gibi kaçırılmaması
  /// gereken bir sinyal; monitör olay başına tek, günde en fazla bir uyarı
  /// gönderir.
  bool get isForecastWarningsEnabled =>
      _prefs.getBool(_keyForecastWarnings) ?? true;

  Future<void> setForecastWarningsEnabled(bool enabled) async {
    await _prefs.setBool(_keyForecastWarnings, enabled);
  }

  /// Pazartesi sabahı haftalık özet. Varsayılan KAPALI: düzenli bir mesaj
  /// kullanıcının seçimi olmalı (Gelecek sayfası bir kez teklif eder).
  bool get isWeeklyDigestEnabled => _prefs.getBool(_keyWeeklyDigest) ?? false;

  Future<void> setWeeklyDigestEnabled(bool enabled) async {
    await _prefs.setBool(_keyWeeklyDigest, enabled);
    await _prefs.setBool(_keyWeeklyDigestOffered, true);
  }

  /// Haftalık özet teklifi gösterildi mi (kabul ya da ret fark etmez).
  bool get isWeeklyDigestOffered =>
      _prefs.getBool(_keyWeeklyDigestOffered) ?? false;

  Future<void> markWeeklyDigestOffered() async {
    await _prefs.setBool(_keyWeeklyDigestOffered, true);
  }
}
