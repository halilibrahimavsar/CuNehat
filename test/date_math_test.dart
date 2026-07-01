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

  // Negatif ay (geriye gitme) yolu mevcut testte yoktu; Dart'ın % ve ~/
  // operatörleri pozitif totalMonths için doğru sonuç verdiğinden geçmiş
  // tarihler de doğru hesaplanır.
  group('addMonthsClamped — negatif ay', () {
    test('Mart 15 − 2 ay → Ocak 15', () {
      expect(
          addMonthsClamped(DateTime(2026, 3, 15), -2), DateTime(2026, 1, 15));
    });

    test('Ocak 15 − 1 ay → önceki yıl Aralık 15 (yıl alt-taşması)', () {
      expect(
          addMonthsClamped(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
    });

    test('31 Mart − 1 ay → 28 Şubat (geriye giderken de kenetlenir)', () {
      expect(
          addMonthsClamped(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
    });

    test('31 Mart − 1 ay → 29 Şubat (artık yıl)', () {
      expect(
          addMonthsClamped(DateTime(2028, 3, 31), -1), DateTime(2028, 2, 29));
    });

    test('Haziran 10 − 12 ay → önceki yıl Haziran 10', () {
      expect(
          addMonthsClamped(DateTime(2026, 6, 10), -12), DateTime(2025, 6, 10));
    });

    test('+1 sonra −1 kenetlenmeyen günde başa döner', () {
      final d = DateTime(2026, 5, 15);
      expect(addMonthsClamped(addMonthsClamped(d, 1), -1), d);
    });
  });
}
