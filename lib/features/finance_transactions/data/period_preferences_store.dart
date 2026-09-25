import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [PeriodPreferences]'ı cihazda saklar (kalıcı ayar: uygulama her açılışta
/// kullanıcının birimiyle başlar).
///
/// Okumada her alan AYRI doğrulanır; bilinmeyen/bozuk bir değer o alanı
/// varsayılana düşürür — bir ayarın bozulması dönem çubuğunu kırmamalı.
class PeriodPreferencesStore {
  const PeriodPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String unitKey = 'period_unit';
  static const String weekStartKey = 'period_week_start';
  static const String biweekAnchorKey = 'period_biweek_anchor';
  static const String monthStartDayKey = 'period_month_start_day';

  PeriodPreferences read() {
    final unitName = _prefs.getString(unitKey);
    final unit = PeriodUnit.values
            .where((u) => u.name == unitName)
            .firstOrNull ??
        PeriodUnit.month;
    final weekStart = _prefs.getInt(weekStartKey);
    final monthStart = _prefs.getInt(monthStartDayKey);
    final anchor = DateTime.tryParse(_prefs.getString(biweekAnchorKey) ?? '');
    return PeriodPreferences(
      unit: unit,
      weekStart: weekStart != null && weekStart >= 1 && weekStart <= 7
          ? weekStart
          : DateTime.monday,
      biweekAnchor: anchor,
      monthStartDay: monthStart != null && monthStart >= 1 && monthStart <= 28
          ? monthStart
          : 1,
    );
  }

  Future<void> write(PeriodPreferences p) async {
    await _prefs.setString(unitKey, p.unit.name);
    await _prefs.setInt(weekStartKey, p.weekStart);
    await _prefs.setInt(monthStartDayKey, p.monthStartDay);
    final anchor = p.biweekAnchor;
    if (anchor == null) {
      await _prefs.remove(biweekAnchorKey);
    } else {
      await _prefs.setString(biweekAnchorKey,
          DateTime(anchor.year, anchor.month, anchor.day).toIso8601String());
    }
  }
}
