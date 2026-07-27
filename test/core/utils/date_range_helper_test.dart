import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateRangeHelper.isBudgetPeriod', () {
    // Ayın son günü: "Bu Ay" ile "Son 7 Gün" aynı gün biter, ayrım yalnız
    // aralığın başından gelir.
    final now = DateTime(2026, 6, 30);

    test('"Bu Ay" bütçe dönemidir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isTrue);
    });

    test('"Bu Yıl" bütçe dönemidir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isTrue);
    });

    test('bugünle biten "Son 7 Gün" bütçe dönemi değildir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 6, 24),
        end: DateTime(2026, 6, 30),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isFalse);
    });

    test('ay sonunda biten "Son 3 Ay" bütçe dönemi değildir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 6, 30),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isFalse);
    });

    test('"Geçen Ay" bütçe dönemi değildir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 31),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isFalse);
    });

    test('uçlardaki saat bilgisi kararı değiştirmez', () {
      final range = DateTimeRange(
        start: DateTime(2026, 6, 1, 13, 45),
        end: DateTime(2026, 6, 30, 23, 59, 59),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isTrue);
    });

    test('aralık başka bir ayın tamamıysa bütçe dönemi değildir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 31),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isFalse);
    });

    test('aralık sonu ay sonundan önceyse bütçe dönemi değildir', () {
      final range = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 29),
      );

      expect(DateRangeHelper.isBudgetPeriod(range, now: now), isFalse);
    });

    test('aralık Aralık ayıysa yıl taşması doğru hesaplanır', () {
      final range = DateTimeRange(
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 31),
      );

      expect(
        DateRangeHelper.isBudgetPeriod(range, now: DateTime(2026, 12, 15)),
        isTrue,
      );
    });
  });
}
