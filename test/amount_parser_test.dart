import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmount', () {
    test('virgül ondalık ayracını kabul eder', () {
      expect(parseAmount('12,5'), 12.5);
    });

    test('nokta ondalık ayracını kabul eder', () {
      expect(parseAmount('12.5'), 12.5);
    });

    test('baş/son boşlukları kırpar', () {
      expect(parseAmount(' 12,5 '), 12.5);
    });

    test('boş girişte null döner', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('   '), isNull);
    });

    test('sayı olmayan girişte null döner', () {
      expect(parseAmount('abc'), isNull);
    });
  });

  group('validateAmount', () {
    test('geçerli tutarda null döner', () {
      expect(validateAmount('100,50'), isNull);
    });

    test('sıfırı varsayılan olarak reddeder', () {
      expect(validateAmount('0'), isNotNull);
    });

    test('allowZero ile sıfırı kabul eder', () {
      expect(validateAmount('0', allowZero: true), isNull);
    });

    test('negatifi reddeder', () {
      expect(validateAmount('-5'), isNotNull);
    });

    test('üst sınırı aşan tutarı reddeder', () {
      expect(validateAmount('1000000000'), isNotNull);
      expect(validateAmount('1e12'), isNotNull);
    });

    test('ayrıştırılamayan girişte hata mesajı döner', () {
      expect(validateAmount('abc'), isNotNull);
      expect(validateAmount(''), isNotNull);
    });
  });
}
