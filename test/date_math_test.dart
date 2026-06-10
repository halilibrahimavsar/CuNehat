import 'package:cunehat/core/utils/date_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addMonthsClamped', () {
    test('31 Ocak + 1 ay → 28 Şubat (artık olmayan yıl)', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('31 Ocak + 1 ay → 29 Şubat (artık yıl)', () {
      expect(addMonthsClamped(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    });

    test('Aralık + 1 ay yıl devri', () {
      expect(
          addMonthsClamped(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
    });

    test('31 Ocak + 3 ay → 30 Nisan', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 3), DateTime(2026, 4, 30));
    });

    test('12 ay tam yıl', () {
      expect(
          addMonthsClamped(DateTime(2026, 6, 10), 12), DateTime(2027, 6, 10));
    });

    test('saat korunur', () {
      final r = addMonthsClamped(DateTime(2026, 1, 15, 14, 30), 1);
      expect(r, DateTime(2026, 2, 15, 14, 30));
    });
  });
}
