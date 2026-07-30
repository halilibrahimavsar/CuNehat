import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Para gösteriminin TEK noktası [formatMoney]/[formatMoneyCompact] için
/// testler. İki şeyi sabitler:
///
///  1. Biçim: locale'in binlik/ondalık ayracı + sonek sembol. Uygulamada
///     üç ayrı biçimleyici vardı (`toStringAsFixed`+sembol,
///     `NumberFormat.currency` — sembolü ÖNE alıyordu — ve paketin
///     `formatGroupedAmount`'ı); aynı tutar ekrana üç türlü yazılıyordu.
///  2. `double` para tipinin kaçınılmaz kayan-nokta sapmasının
///     (0.1+0.2 = 0.30000000000000004) GÖSTERİMDE doğru yuvarlandığı.
void main() {
  // Locale'i her testte açıkça kur: formatMoney Intl.defaultLocale'e bakar,
  // kurulmamışsa 'tr'ye düşer — ikisini de doğruluyoruz.
  setUp(() => Intl.defaultLocale = 'tr');
  tearDown(() => Intl.defaultLocale = null);

  group('formatMoney', () {
    test('binlik ayraçlı, 2 ondalıklı, sonek sembollü', () {
      expect(formatMoney(1), '1,00 ₺');
      expect(formatMoney(1000), '1.000,00 ₺');
      expect(formatMoney(1234567.891), '1.234.567,89 ₺');
    });

    test('negatif değer işareti korur', () {
      expect(formatMoney(-5.5), '-5,50 ₺');
      expect(formatMoney(-1234.5), '-1.234,50 ₺');
    });

    test('cüzdan birimi sembolü sonda', () {
      expect(formatMoney(12.5, currency: 'USD'), r'12,50 $');
      expect(formatMoney(12.5, currency: 'EUR'), '12,50 €');
    });

    test('bilinmeyen birimde kodun kendisi yazılır', () {
      expect(formatMoney(12.5, currency: 'GBP'), '12,50 GBP');
    });

    test('symbol:false sembolsüz sayı gövdesi verir', () {
      expect(formatMoney(1234.5, symbol: false), '1.234,50');
      expect(formatMoneyNumber(1234.5), '1.234,50');
    });

    test('decimals parametresi ondalık sayısını değiştirir', () {
      expect(formatMoney(3.14159, decimals: 4), '3,1416 ₺');
      expect(formatMoney(3, decimals: 0), '3 ₺');
      expect(formatMoney(1500, decimals: 0), '1.500 ₺');
    });

    test('3. ondalıkta yuvarlama (yukarı/aşağı)', () {
      expect(formatMoney(2.349), '2,35 ₺');
      expect(formatMoney(2.341), '2,34 ₺');
    });

    test('sıfıra yuvarlanan küçük negatif "-0,00" yazmaz', () {
      expect(formatMoney(-0.004), '0,00 ₺');
      expect(formatMoney(-0.0), '0,00 ₺');
      expect(formatMoney(0), '0,00 ₺');
    });

    test('locale değişince ayraçlar da değişir, sembol yine sonda', () {
      Intl.defaultLocale = 'en';
      expect(formatMoney(1234.5), '1,234.50 ₺');
    });

    test('locale hiç kurulmamışsa uygulamanın varsayılanına (tr) düşer', () {
      Intl.defaultLocale = null;
      expect(formatMoney(1234.5), '1.234,50 ₺');
    });

    group('kayan-nokta sapması gösterimde yuvarlanır', () {
      test('0.1 + 0.2 (=0.30000000000000004) → "0,30 ₺"', () {
        expect(formatMoney(0.1 + 0.2), '0,30 ₺');
      });

      test('10 × 0.1 toplamı (~0.999…) → "1,00 ₺"', () {
        var s = 0.0;
        for (var i = 0; i < 10; i++) {
          s += 0.1;
        }
        expect(s, closeTo(1.0, 1e-9)); // ham değer ~0.9999999999999999
        expect(formatMoney(s), '1,00 ₺');
      });

      test('1000 × 0.01 toplamı (~9.999…831) → "10,00 ₺"', () {
        var s = 0.0;
        for (var i = 0; i < 1000; i++) {
          s += 0.01;
        }
        expect(s, closeTo(10.0, 1e-6));
        expect(formatMoney(s), '10,00 ₺');
      });
    });
  });

  group('formatMoneyCompact', () {
    test('1000 altı ham sayı (ondalıksız)', () {
      expect(formatMoneyCompact(320), '320 ₺');
      expect(formatMoneyCompact(999), '999 ₺');
    });

    test('bin → K (gereksiz ",0" kırpılır)', () {
      expect(formatMoneyCompact(1500), '1,5K ₺');
      expect(formatMoneyCompact(2000), '2K ₺');
    });

    test('milyon → M', () {
      expect(formatMoneyCompact(2400000), '2,4M ₺');
    });

    test('negatif işaret korunur', () {
      expect(formatMoneyCompact(-1500), '-1,5K ₺');
    });

    test('symbol:false sembol eklemez', () {
      expect(formatMoneyCompact(1500, symbol: false), '1,5K');
    });

    test('birim sembolü [currency] ile gelir', () {
      expect(formatMoneyCompact(1500, currency: 'USD'), r'1,5K $');
    });

    test('sıfıra yuvarlanan küçük negatif "-0" yazmaz', () {
      expect(formatMoneyCompact(-0.4, symbol: false), '0');
    });

    test('locale ondalık ayracını izler', () {
      Intl.defaultLocale = 'en';
      expect(formatMoneyCompact(1500, symbol: false), '1.5K');
    });
  });
}
