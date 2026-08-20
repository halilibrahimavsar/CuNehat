import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('periodKindOf', () {
    test('ayın tamamı → month', () {
      expect(
          periodKindOf(monthRangeOf(DateTime(2026, 8, 14))), PeriodKind.month);
    });

    test('yılın tamamı → year (ay kontrolünden ÖNCE eşleşmemeli)', () {
      expect(periodKindOf(yearRangeOf(DateTime(2026, 5, 5))), PeriodKind.year);
    });

    test('Pazartesi–Pazar → week', () {
      // 2026-08-10 Pazartesi.
      expect(periodKindOf(weekRangeOf(DateTime(2026, 8, 12))), PeriodKind.week);
    });

    test('tek gün → day', () {
      expect(periodKindOf(dayRangeOf(DateTime(2026, 8, 14))), PeriodKind.day);
    });

    test('"son 7 gün" hafta DEĞİL, custom', () {
      // Çarşamba–Salı: 7 gün ama takvim haftası değil.
      final range = DateTimeRange(
        start: DateTime(2026, 8, 12),
        end: DateTime(2026, 8, 18, 23, 59, 59),
      );
      expect(periodKindOf(range), PeriodKind.custom);
    });

    test('Ocak ayı yıl başlangıcıyla aynı günde başlar ama year değildir', () {
      expect(
          periodKindOf(monthRangeOf(DateTime(2026, 1, 5))), PeriodKind.month);
    });
  });

  group('shiftPeriod', () {
    test('ay aralığı takvim ayı atlar', () {
      final next = shiftPeriod(monthRangeOf(DateTime(2026, 1, 15)), 1);
      expect(next.start, DateTime(2026, 2, 1));
      expect(next.end.day, 28);
      expect(next.end.month, 2);
    });

    test('31 gün çeken aydan sonra kısa aya geçiş kenetlenir', () {
      // Ocak aralığı 31 Ocak'ta biter; naif +30 gün yaklaşımı 2 Mart'a taşardı.
      final next = shiftPeriod(monthRangeOf(DateTime(2026, 1, 31)), 1);
      expect(periodKindOf(next), PeriodKind.month);
      expect(next.start.month, 2);
    });

    test('yıl sınırında geriye gider', () {
      final prev = shiftPeriod(monthRangeOf(DateTime(2026, 1, 10)), -1);
      expect(prev.start, DateTime(2025, 12, 1));
      expect(prev.end.day, 31);
    });

    test('hafta 7 gün kayar ve hafta kalır', () {
      final next = shiftPeriod(weekRangeOf(DateTime(2026, 8, 12)), 1);
      expect(periodKindOf(next), PeriodKind.week);
      expect(next.start, DateTime(2026, 8, 17));
    });

    test('gün bir gün kayar', () {
      final next = shiftPeriod(dayRangeOf(DateTime(2026, 8, 14)), 1);
      expect(next.start, DateTime(2026, 8, 15));
      expect(periodKindOf(next), PeriodKind.day);
    });

    test('özel aralık KENDİ uzunluğu kadar kayar, pencereler bitişik olur', () {
      // 12–18 Ağustos: 7 günlük pencere. Bir önceki pencere 5–11 olmalı,
      // 6–12 değil (uçlar dahil olduğu için uzunluk fark + 1 gündür).
      final range = DateTimeRange(
        start: DateTime(2026, 8, 12),
        end: DateTime(2026, 8, 18, 23, 59, 59),
      );
      final prev = shiftPeriod(range, -1);
      expect(prev.start, DateTime(2026, 8, 5));
      expect(dayOf(prev.end), DateTime(2026, 8, 11));
    });

    test('step 0 aynı aralığı döner', () {
      final range = monthRangeOf(DateTime(2026, 8, 1));
      expect(shiftPeriod(range, 0), same(range));
    });

    test('yıl aralığı bir yıl kayar', () {
      final next = shiftPeriod(yearRangeOf(DateTime(2026, 6, 6)), 1);
      expect(periodKindOf(next), PeriodKind.year);
      expect(next.start.year, 2027);
    });
  });

  group('focusDayFor', () {
    test('aralık bugünü kapsıyorsa bugüne odaklanır', () {
      final now = DateTime(2026, 8, 14);
      expect(focusDayFor(monthRangeOf(now), now: now), DateTime(2026, 8, 14));
    });

    test('geçmiş aralıkta aralığın başına odaklanır', () {
      final now = DateTime(2026, 8, 14);
      expect(
        focusDayFor(monthRangeOf(DateTime(2026, 3, 3)), now: now),
        DateTime(2026, 3, 1),
      );
    });
  });

  group('isDayInRange', () {
    final range = monthRangeOf(DateTime(2026, 8, 1));

    test('uçlar dahildir', () {
      expect(isDayInRange(DateTime(2026, 8, 1), range), isTrue);
      expect(isDayInRange(DateTime(2026, 8, 31, 23, 59), range), isTrue);
    });

    test('dışarısı false', () {
      expect(isDayInRange(DateTime(2026, 7, 31), range), isFalse);
      expect(isDayInRange(DateTime(2026, 9, 1), range), isFalse);
    });

    test('gün içi saat aralığın sonunu düşürmez', () {
      // Aralığın sonu 23:59:59; 31 Ağustos 08:00 hâlâ içeride olmalı.
      expect(isDayInRange(DateTime(2026, 8, 31, 8), range), isTrue);
    });
  });
}
