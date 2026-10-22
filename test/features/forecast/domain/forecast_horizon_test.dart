import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/forecast/domain/forecast_horizon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ay birimi', () {
    const month = PeriodPreferences();

    test('ayın ortasında ufuk ay sonu', () {
      expect(forecastHorizonEnd(month, DateTime(2026, 10, 10, 15)),
          DateTime(2026, 10, 31));
      expect(forecastHorizonDays(month, DateTime(2026, 10, 10)), 21);
    });

    test('son çeyreğe girmeden (8 gün kala) hâlâ bu ayın sonu', () {
      expect(forecastHorizonEnd(month, DateTime(2026, 10, 23)),
          DateTime(2026, 10, 31));
    });

    test('son çeyrekte (7 gün kala) sonraki ayın sonuna uzar', () {
      expect(forecastHorizonEnd(month, DateTime(2026, 10, 24)),
          DateTime(2026, 11, 30));
      expect(forecastHorizonEnd(month, DateTime(2026, 10, 31)),
          DateTime(2026, 11, 30));
    });

    test('Şubat: 28 günlük ayda eşik 7 gün', () {
      expect(forecastHorizonEnd(month, DateTime(2027, 2, 20)),
          DateTime(2027, 2, 28));
      expect(forecastHorizonEnd(month, DateTime(2027, 2, 22)),
          DateTime(2027, 3, 31));
    });

    test('maaş günü 15: dönem 15\'i – ertesi ayın 14\'ü', () {
      const salary = PeriodPreferences(monthStartDay: 15);
      expect(forecastHorizonEnd(salary, DateTime(2026, 10, 23)),
          DateTime(2026, 11, 14));
      expect(forecastHorizonEnd(salary, DateTime(2026, 11, 10)),
          DateTime(2026, 12, 14));
    });
  });

  group('hafta birimi', () {
    const week = PeriodPreferences(unit: PeriodUnit.week);

    test('Pazartesi–Cuma: bu haftanın Pazar\'ı', () {
      // 19 Eki 2026 Pazartesi.
      expect(forecastHorizonEnd(week, DateTime(2026, 10, 19)),
          DateTime(2026, 10, 25));
      expect(forecastHorizonEnd(week, DateTime(2026, 10, 23)),
          DateTime(2026, 10, 25));
    });

    test('Cumartesi ve Pazar: sonraki haftanın Pazar\'ı', () {
      expect(forecastHorizonEnd(week, DateTime(2026, 10, 24)),
          DateTime(2026, 11, 1));
      expect(forecastHorizonEnd(week, DateTime(2026, 10, 25)),
          DateTime(2026, 11, 1));
    });

    test('Çarşamba başlayan hafta', () {
      const wed = PeriodPreferences(
          unit: PeriodUnit.week, weekStart: DateTime.wednesday);
      // 23 Eki Cuma: dönem 21–27 Eki.
      expect(forecastHorizonEnd(wed, DateTime(2026, 10, 23)),
          DateTime(2026, 10, 27));
    });
  });

  group('2 hafta birimi', () {
    final biweek = PeriodPreferences(
        unit: PeriodUnit.biweek, biweekAnchor: DateTime(2026, 10, 12));

    test('kalan gün 3\'ten fazlaysa bu dönemin sonu', () {
      // Dönem 12–25 Eki.
      expect(forecastHorizonEnd(biweek, DateTime(2026, 10, 21)),
          DateTime(2026, 10, 25));
    });

    test('son 3 günde sonraki dönemin sonu', () {
      expect(forecastHorizonEnd(biweek, DateTime(2026, 10, 22)),
          DateTime(2026, 11, 8));
    });
  });

  test('gün biriminde ufuk 7 gün', () {
    const day = PeriodPreferences(unit: PeriodUnit.day);
    expect(forecastHorizonEnd(day, DateTime(2026, 10, 23, 22)),
        DateTime(2026, 10, 30));
    expect(forecastHorizonDays(day, DateTime(2026, 10, 23)), 7);
  });
}
