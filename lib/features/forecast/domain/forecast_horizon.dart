import 'dart:math' as math;

import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';

/// Gelecek sayfasının ufku: kullanıcının dönem biriminin SONU.
///
/// Sabit 30 gün aylık kullanıcıda ay sonunu kaçırıyor, haftalıkta dört
/// haftayı birden gösteriyordu. Ufuk artık içinde bulunulan dönemin son
/// günüdür (maaş günü dahil, bkz. [PeriodPreferences.periodContaining]).
///
/// Dönemin son çeyreğindeyse (kalan gün < max(2, ⌈uzunluk/4⌉): ayda son ~7
/// gün, haftada son 2 gün) ufuk SONRAKİ dönemin sonuna uzar: ayın 28'inde
/// "üç gün" göstermek hiçbir şey söylemez. Gün biriminde ufuk 7 gündür.
DateTime forecastHorizonEnd(PeriodPreferences prefs, DateTime today) {
  final t = CardCycle.dateOnly(today);
  if (prefs.unit == PeriodUnit.day) {
    return DateTime(t.year, t.month, t.day + 7);
  }
  final current = prefs.periodContaining(t);
  final start = CardCycle.dateOnly(current.start);
  final end = CardCycle.dateOnly(current.end);
  final length = CardCycle.daysBetween(start, end) + 1;
  final left = CardCycle.daysBetween(t, end);
  if (left < math.max(2, (length / 4).ceil())) {
    return CardCycle.dateOnly(prefs.step(current, 1).end);
  }
  return end;
}

/// [forecastHorizonEnd]'e kadar gün sayısı (motorun `horizonDays`'i);
/// 1..120 arasında.
int forecastHorizonDays(PeriodPreferences prefs, DateTime today) =>
    CardCycle.daysBetween(
            CardCycle.dateOnly(today), forecastHorizonEnd(prefs, today))
        .clamp(1, 120);
