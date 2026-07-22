import 'package:cunehat/features/bank_import/data/statement_currency_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectDominantCurrency', () {
    test('₺ simgesi → TRY', () {
      expect(detectDominantCurrency('MARKET 150,00 ₺\nMAAŞ 5.000,00 ₺'), 'TRY');
    });

    test('\$ simgesi → USD', () {
      expect(
          detectDominantCurrency(r'AMAZON $12.50' '\n' r'REFUND $3.00'), 'USD');
    });

    test('EUR kodu → EUR', () {
      expect(detectDominantCurrency('SEPA 40,00 EUR\nSEPA 10,00 EUR'), 'EUR');
    });

    test('TL kodu → TRY', () {
      expect(detectDominantCurrency('ODEME 100 TL\nODEME 50 TL'), 'TRY');
    });

    test('simge yoksa null (sade sayılar tahmin edilmez)', () {
      expect(detectDominantCurrency('15.06.2026 MARKET 150,00'), isNull);
    });

    test('baskın olan kazanır (çoğunluk USD)', () {
      expect(
        detectDominantCurrency(r'A $10' '\n' r'B $20' '\n' 'C 30 ₺'),
        'USD',
      );
    });
  });
}
