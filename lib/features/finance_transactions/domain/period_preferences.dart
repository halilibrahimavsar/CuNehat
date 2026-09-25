import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:flutter/material.dart' show DateTimeRange, immutable;

/// Dönem çubuğunun adım birimi.
///
/// Uygulama uzun süre fiilen AYA bağlıydı: oklar ay atlıyordu, hafta ancak
/// özel aralık olarak seçilebiliyordu ve hep Pazartesi başlıyordu. Haftalık
/// ya da iki haftada bir ödeme alan, maaşı ayın 15'inde yatan kullanıcı kendi
/// "dönemine" bakamıyordu.
enum PeriodUnit { day, week, biweek, month }

/// Kullanıcının dönem tercihi: birim + birimin başlangıç ayarı.
///
/// Saf veri; kalıcılığı `PeriodPreferencesStore` taşır. Dönemler gün
/// hassasiyetindedir ve uygulamanın geri kalanı gibi 00:00 → 23:59:59 aralığı
/// üretir (bkz. [monthRangeOf]).
@immutable
class PeriodPreferences {
  final PeriodUnit unit;

  /// Hafta birimi: haftanın başladığı gün ([DateTime.monday] … sunday).
  /// Çarşamba seçilirse dönem Çarşamba–Salı olur.
  final int weekStart;

  /// 2 hafta birimi: bilinen bir ödeme günü. İki haftalık dönemin HANGİ
  /// haftadan başladığını ancak gerçek bir tarih belirleyebilir; verilmezse
  /// içinde bulunulan haftanın [weekStart]'ı kullanılır.
  final DateTime? biweekAnchor;

  /// Ay birimi: dönemin ayın kaçında başladığı (1–28). 15 → 15'i ile ertesi
  /// ayın 14'ü. 28'le sınırlı: her ayda var olan son gün.
  final int monthStartDay;

  const PeriodPreferences({
    this.unit = PeriodUnit.month,
    this.weekStart = DateTime.monday,
    this.biweekAnchor,
    this.monthStartDay = 1,
  })  : assert(weekStart >= DateTime.monday && weekStart <= DateTime.sunday),
        assert(monthStartDay >= 1 && monthStartDay <= 28);

  /// Varsayılan: takvim ayı (uygulamanın eski davranışı).
  static const calendarMonth = PeriodPreferences();

  PeriodPreferences copyWith({
    PeriodUnit? unit,
    int? weekStart,
    DateTime? biweekAnchor,
    int? monthStartDay,
  }) =>
      PeriodPreferences(
        unit: unit ?? this.unit,
        weekStart: weekStart ?? this.weekStart,
        biweekAnchor: biweekAnchor ?? this.biweekAnchor,
        monthStartDay: monthStartDay ?? this.monthStartDay,
      );

  static DateTimeRange _range(DateTime start, DateTime lastDay) =>
      DateTimeRange(
        start: dayOf(start),
        end: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
      );

  /// Takvim günleri arası fark — yaz saati geçişinde `Duration.inDays` bir
  /// gün kayabildiği için UTC tarihler üzerinden.
  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  static DateTime _plusDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  DateTime _weekStartOf(DateTime d) {
    final day = dayOf(d);
    return _plusDays(day, -((day.weekday - weekStart + 7) % 7));
  }

  /// [day]'i içeren dönem.
  DateTimeRange periodContaining(DateTime day) {
    final d = dayOf(day);
    switch (unit) {
      case PeriodUnit.day:
        return _range(d, d);
      case PeriodUnit.week:
        final start = _weekStartOf(d);
        return _range(start, _plusDays(start, 6));
      case PeriodUnit.biweek:
        final anchor = dayOf(biweekAnchor ?? _weekStartOf(DateTime.now()));
        final diff = _daysBetween(anchor, d);
        // Negatif farkta da doğru pencere: tabana yuvarlanır.
        final k = (diff / 14).floor();
        final start = _plusDays(anchor, 14 * k);
        return _range(start, _plusDays(start, 13));
      case PeriodUnit.month:
        final s = monthStartDay;
        final start = d.day >= s
            ? DateTime(d.year, d.month, s)
            : DateTime(d.year, d.month - 1, s);
        // s = 1 → ertesi ayın 0'ı = bu ayın son günü.
        final last = DateTime(start.year, start.month + 1, s - 1);
        return _range(start, last);
    }
  }

  /// [range] bu tercihin ürettiği bir dönem mi (oklar birimle mi kaymalı)?
  bool isUnitPeriod(DateTimeRange range) {
    final p = periodContaining(range.start);
    return isSameDayValue(p.start, range.start) &&
        isSameDayValue(p.end, range.end);
  }

  /// Birim dönemini [step] kadar kaydırır: sonraki dönem, bu dönemin son
  /// gününün ERTESİ gününü içeren dönemdir (öncekisi: ilk gününün bir gün
  /// öncesi). Ay uzunlukları farklı olsa da kayma hep bitişik kalır.
  DateTimeRange step(DateTimeRange range, int step) {
    var current = periodContaining(range.start);
    for (var i = 0; i < step.abs(); i++) {
      current = step > 0
          ? periodContaining(_plusDays(dayOf(current.end), 1))
          : periodContaining(_plusDays(dayOf(current.start), -1));
    }
    return current;
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodPreferences &&
      other.unit == unit &&
      other.weekStart == weekStart &&
      other.biweekAnchor == biweekAnchor &&
      other.monthStartDay == monthStartDay;

  @override
  int get hashCode => Object.hash(unit, weekStart, biweekAnchor, monthStartDay);
}
