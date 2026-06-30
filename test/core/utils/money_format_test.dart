import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

/// Para gösteriminin tek noktası [formatMoney]/[formatMoneyCompact] için
/// testler. Asıl amaç: `double` para tipinin kaçınılmaz kayan-nokta sapmasının
/// (0.1+0.2 = 0.30000000000000004) GÖSTERİMDE doğru yuvarlandığını sabitlemek —
/// kullanıcı her zaman 2-hane doğru tutarı görür, ham sapmayı değil.
void main() {
  group('formatMoney', () {
    test('tam sayıyı 2 ondalıkla ve ₺ ile yazar', () {
      expect(formatMoney(1), '1.00 ₺');
      expect(formatMoney(1000), '1000.00 ₺');
    });

    test('negatif değer işareti korur', () {
      expect(formatMoney(-5.5), '-5.50 ₺');
    });

    test('decimals parametresi ondalık sayısını değiştirir', () {
      expect(formatMoney(3.14159, decimals: 4), '3.1416 ₺');
      expect(formatMoney(3, decimals: 0), '3 ₺');
    });

    test('3. ondalıkta yuvarlama (yukarı/aşağı)', () {
      expect(formatMoney(2.349), '2.35 ₺');
      expect(formatMoney(2.341), '2.34 ₺');
    });

    group('kayan-nokta sapması gösterimde yuvarlanır', () {
      test('0.1 + 0.2 (=0.30000000000000004) → "0.30 ₺"', () {
        expect(formatMoney(0.1 + 0.2), '0.30 ₺');
      });

      test('10 × 0.1 toplamı (~0.999…) → "1.00 ₺"', () {
        var s = 0.0;
        for (var i = 0; i < 10; i++) {
          s += 0.1;
        }
        expect(s, closeTo(1.0, 1e-9)); // ham değer ~0.9999999999999999
        expect(formatMoney(s), '1.00 ₺');
      });

      test('1000 × 0.01 toplamı (~9.999…831) → "10.00 ₺"', () {
        var s = 0.0;
        for (var i = 0; i < 1000; i++) {
          s += 0.01;
        }
        expect(s, closeTo(10.0, 1e-6));
        expect(formatMoney(s), '10.00 ₺');
      });
    });
  });

  group('formatMoneyCompact', () {
    test('1000 altı ham sayı (ondalıksız)', () {
      expect(formatMoneyCompact(320), '320 ₺');
      expect(formatMoneyCompact(999), '999 ₺');
    });

    test('bin → K (gereksiz .0 kırpılır)', () {
      expect(formatMoneyCompact(1500), '1.5K ₺');
      expect(formatMoneyCompact(2000), '2K ₺');
    });

    test('milyon → M', () {
      expect(formatMoneyCompact(2400000), '2.4M ₺');
    });

    test('negatif işaret korunur', () {
      expect(formatMoneyCompact(-1500), '-1.5K ₺');
    });

    test('symbol:false ₺ eklemez', () {
      expect(formatMoneyCompact(1500, symbol: false), '1.5K');
    });
  });
}
