/// İşlemler ekranının ZAMAN EKSENİ — liste ve takvim görünümünün ortak dili.
///
/// Ekranda iki ayrı zaman kavramı vardı: filtrenin tarih aralığı (yalnız liste
/// modunda uygulanıyordu) ve takvimin kendi ay/hafta gezinmesi. Kullanıcı
/// takvimdeyken tarih filtresini değiştirdiğinde hiçbir şey olmuyordu. Artık
/// tek bir aralık var; takvimde ay değiştirmek onu YAZAR, listede aralık
/// seçmek takvimi oraya ODAKLAR.
///
/// Buradaki her şey saftır: takvim/aralık aritmetiği I/O ve BuildContext
/// bilmez. Sınırlar GÜN hassasiyetinde karşılaştırılır (seçicilerden gelen
/// aralıklar saat taşıyabiliyor).
library;

import 'package:cunehat/core/utils/date_math.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Bir aralığın hangi "doğal" döneme denk geldiği.
///
/// İleri/geri adımının ne kadar olacağını ve etiketin nasıl yazılacağını bu
/// belirler: ay aralığında ok bir AY atlar, hafta aralığında 7 gün.
enum PeriodKind { day, week, month, year, custom }

/// Saat/dakika kırpılmış gün.
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDayValue(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Ayın tamamı: 1'i 00:00 → son gün 23:59:59.
DateTimeRange monthRangeOf(DateTime d) => DateTimeRange(
      start: DateTime(d.year, d.month, 1),
      end: DateTime(d.year, d.month + 1, 0, 23, 59, 59),
    );

/// Pazartesi başlangıçlı haftanın tamamı.
DateTimeRange weekRangeOf(DateTime d) {
  final day = dayOf(d);
  final start =
      day.subtract(Duration(days: (day.weekday - DateTime.monday) % 7));
  final end = start.add(const Duration(days: 6));
  return DateTimeRange(
    start: start,
    end: DateTime(end.year, end.month, end.day, 23, 59, 59),
  );
}

/// Tek günün tamamı.
DateTimeRange dayRangeOf(DateTime d) => DateTimeRange(
      start: dayOf(d),
      end: DateTime(d.year, d.month, d.day, 23, 59, 59),
    );

/// Yılın tamamı.
DateTimeRange yearRangeOf(DateTime d) => DateTimeRange(
      start: DateTime(d.year, 1, 1),
      end: DateTime(d.year, 12, 31, 23, 59, 59),
    );

/// [range] hangi doğal döneme oturuyor?
///
/// Yalnız TAM oturanlar isimlendirilir: ayın 1'i–son günü ay, Pazartesi–Pazar
/// hafta. "Son 7 gün" (Çarşamba–Salı) hafta DEĞİLDİR, `custom` döner — okun
/// 7 gün atlaması yine de doğru davranıştır, bkz. [shiftPeriod].
PeriodKind periodKindOf(DateTimeRange range) {
  // DateTimeRange kendi kurucusunda start <= end güvence altına alır;
  // burada ters aralık savunması gereksiz.
  final start = dayOf(range.start);
  final end = dayOf(range.end);

  if (isSameDayValue(start, end)) return PeriodKind.day;

  final month = monthRangeOf(start);
  if (isSameDayValue(start, month.start) && isSameDayValue(end, month.end)) {
    return PeriodKind.month;
  }

  final year = yearRangeOf(start);
  if (isSameDayValue(start, year.start) && isSameDayValue(end, year.end)) {
    return PeriodKind.year;
  }

  final week = weekRangeOf(start);
  if (isSameDayValue(start, week.start) && isSameDayValue(end, week.end)) {
    return PeriodKind.week;
  }

  return PeriodKind.custom;
}

/// Aralığı kendi doğasına göre [step] dönem ileri/geri kaydırır.
///
/// Ay aralığı takvim ayı atlar ([addMonthsClamped] — 31 Ocak → 28 Şubat
/// tuzağı orada çözülü). Diğerlerinde aralık KENDİ uzunluğu kadar kayar:
/// "son 7 gün" bir önceki 7 güne, 45 günlük özel aralık bir önceki 45 güne.
/// Böylece özel aralıklarda da ok tutarlı, bitişik pencereler üretir.
DateTimeRange shiftPeriod(DateTimeRange range, int step) {
  if (step == 0) return range;
  final kind = periodKindOf(range);

  switch (kind) {
    case PeriodKind.month:
      return monthRangeOf(addMonthsClamped(dayOf(range.start), step));
    case PeriodKind.year:
      return yearRangeOf(DateTime(range.start.year + step, 1, 1));
    case PeriodKind.week:
      return weekRangeOf(dayOf(range.start).add(Duration(days: 7 * step)));
    case PeriodKind.day:
      return dayRangeOf(dayOf(range.start).add(Duration(days: step)));
    case PeriodKind.custom:
      final start = dayOf(range.start);
      final end = dayOf(range.end);
      // Uçlar dahil olduğu için pencere uzunluğu fark + 1 gündür; bitişik
      // pencereler istiyorsak kaydırma da bu kadar olmalı.
      final lengthInDays = end.difference(start).inDays + 1;
      final offset = Duration(days: lengthInDays * step);
      final newStart = start.add(offset);
      final newEnd = end.add(offset);
      return DateTimeRange(
        start: newStart,
        end: DateTime(newEnd.year, newEnd.month, newEnd.day, 23, 59, 59),
      );
  }
}

/// Takvimin odaklanacağı gün: aralık bugünü kapsıyorsa BUGÜN, kapsamıyorsa
/// aralığın başı.
///
/// "Bu ay" seçiliyken takvim ayın 1'ine değil bugüne bakmalı; geçmiş bir
/// aralığa gidildiğinde ise o aralığın başına.
DateTime focusDayFor(DateTimeRange range, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  final start = dayOf(range.start);
  final end = dayOf(range.end);
  if (!today.isBefore(start) && !today.isAfter(end)) return today;
  return start;
}

/// [day] aralığın içinde mi (uçlar dahil, gün hassasiyetinde)?
bool isDayInRange(DateTime day, DateTimeRange range) {
  final d = dayOf(day);
  return !d.isBefore(dayOf(range.start)) && !d.isAfter(dayOf(range.end));
}

/// [range] ile AYNI türden ama bugünü içeren dönem.
///
/// "Bugüne dön" düğmesi bunu kullanır: haftalık bakan kullanıcı bu haftaya,
/// aylık bakan bu aya döner. Kullanıcının seçtiği pencere GENİŞLİĞİ bir
/// gezinme eylemiyle değişmemeli — özel aralık da uzunluğunu korur, yalnız
/// bugünde biter.
DateTimeRange currentPeriodLike(DateTimeRange range, {DateTime? now}) {
  final today = dayOf(now ?? DateTime.now());
  final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

  switch (periodKindOf(range)) {
    case PeriodKind.day:
      return dayRangeOf(today);
    case PeriodKind.week:
      return weekRangeOf(today);
    case PeriodKind.month:
      return monthRangeOf(today);
    case PeriodKind.year:
      return yearRangeOf(today);
    case PeriodKind.custom:
      final lengthInDays =
          dayOf(range.end).difference(dayOf(range.start)).inDays;
      return DateTimeRange(
        start: today.subtract(Duration(days: lengthInDays)),
        end: endOfToday,
      );
  }
}

/// Aralığın kapsadığı günler (uçlar dahil, gün hassasiyetinde).
///
/// Gün şeridi bunun üzerinde kurulur. Yaz saati geçişlerinde gün eklemek
/// `Duration(days: 1)` ile 23 ya da 25 saat sürebildiği için ilerleme
/// takvim alanı üzerinden yapılır.
List<DateTime> daysOf(DateTimeRange range) {
  final end = dayOf(range.end);
  final days = <DateTime>[];
  var cursor = dayOf(range.start);
  while (!cursor.isAfter(end)) {
    days.add(cursor);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
  return days;
}
