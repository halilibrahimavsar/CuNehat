import 'package:cunehat/core/utils/money_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roundToCents', () {
    test('FP artığını kuruşa toplar (borç senaryosu)', () {
      expect(roundToCents(314.55999999999995), 314.56);
      expect(roundToCents(0.1 + 0.2), 0.3); // 0.30000000000000004
    });

    test('tam kuruş değerlerini değiştirmez', () {
      expect(roundToCents(314.56), 314.56);
      expect(roundToCents(100.0), 100.0);
      expect(roundToCents(0.0), 0.0);
    });

    test('en yakın kuruşa yuvarlar (negatifte de simetrik)', () {
      // Not: tam .xx5 "bağ" değerleri double'da temsil edilemez (1.005
      // aslında 1.00499…); bağ davranışı ikili temsile göre düşer. Para
      // girdileri en fazla 2 hane olduğundan bu kenar pratikte oluşmaz.
      expect(roundToCents(1.006), 1.01);
      expect(roundToCents(1.004), 1.0);
      expect(roundToCents(-1.006), -1.01);
      expect(roundToCents(-2.678), -2.68);
    });

    test('büyük tutarlarda kuruş hassasiyeti korunur (kMaxAmount bölgesi)', () {
      expect(roundToCents(999999999.994999), 999999999.99);
      expect(roundToCents(999999999.995001), 1000000000.0);
    });
  });

  group('tolerans karşılaştırmaları (sınır ±0.005)', () {
    test('moneyGreaterThan: yarım kuruş içindeki fark "fazla" sayılmaz', () {
      expect(moneyGreaterThan(314.56, 314.55999999999995), false);
      expect(moneyGreaterThan(314.56, 314.56), false);
      expect(moneyGreaterThan(314.57, 314.56), true);
      expect(moneyGreaterThan(314.565, 314.56), false); // tam sınır: > değil
    });

    test('moneyGte: eksik yarım kuruş ödemeyi tam kabul eder', () {
      expect(moneyGte(314.556, 314.56), true);
      expect(moneyGte(314.56, 314.56), true);
      expect(moneyGte(314.55, 314.56), false);
      expect(moneyGte(314.554, 314.56), false);
    });

    test('moneyEquals: simetrik ve sınır dahil', () {
      expect(moneyEquals(1.0, 1.004), true);
      expect(moneyEquals(1.004, 1.0), true);
      expect(moneyEquals(1.0, 1.005), true); // <= eps
      expect(moneyEquals(1.0, 1.006), false);
    });

    test('moneyIsPositive: −0.001 artığı kalan borç sayılmaz', () {
      expect(moneyIsPositive(-0.001), false);
      expect(moneyIsPositive(0.004), false);
      expect(moneyIsPositive(0.01), true);
    });
  });
}
