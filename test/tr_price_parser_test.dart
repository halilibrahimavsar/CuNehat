import 'package:cunehat/core/utils/tr_price_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseTrPrice', () {
    test('num değerleri doğrudan döner', () {
      expect(parseTrPrice(4250.5), 4250.5);
      expect(parseTrPrice(4250), 4250.0);
      expect(parseTrPrice(0), 0.0);
    });

    test('Türkçe biçim: binlik nokta + ondalık virgül', () {
      expect(parseTrPrice('4.318,24'), 4318.24);
      expect(parseTrPrice('1.234.567,89'), 1234567.89);
      expect(parseTrPrice('12,5'), 12.5);
      expect(parseTrPrice(' 4.318,24 '), 4318.24);
    });

    test('virgülsüz string: nokta ondalık kabul edilir', () {
      expect(parseTrPrice('4250.5'), 4250.5);
      expect(parseTrPrice('4250'), 4250.0);
    });

    test('geçersiz girdiler null döner', () {
      expect(parseTrPrice(null), isNull);
      expect(parseTrPrice(''), isNull);
      expect(parseTrPrice('   '), isNull);
      expect(parseTrPrice('N/A'), isNull);
      expect(parseTrPrice('1,2,3'), isNull);
      expect(parseTrPrice(['4250']), isNull);
      expect(parseTrPrice({'Satış': '4250'}), isNull);
    });
  });
}
