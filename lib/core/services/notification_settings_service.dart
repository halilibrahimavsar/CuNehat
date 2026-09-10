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

  /// Eski sürümlerin motivasyon aralığına yazdığı TEK ATIŞLIK planların bir
  /// kez temizlendiğini işaretler.
  static const String _keyLegacyRandomPurged = 'notification_legacy_random_purged';

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
}
