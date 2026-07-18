import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// [text] sonuna tek tek karakter ekleyerek gerçek klavye yazımını simüle
/// eder; her adımda formatter'ın ürettiği metin bir sonraki adımın eski
/// değeri olur.
String _typeSequence(AmountInputFormatter f, String text) {
  var value = const TextEditingValue(text: '');
  for (final ch in text.split('')) {
    final next = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = f.formatEditUpdate(value, next);
  }
  return value.text;
}

void main() {
  group('AmountInputFormatter — canlı yazım', () {
    test('binlik gruplama tam sayıda artarak oluşur', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '1'), '1');
      expect(_typeSequence(f, '12'), '12');
      expect(_typeSequence(f, '123'), '123');
      expect(_typeSequence(f, '1234'), '1.234');
      expect(_typeSequence(f, '12345'), '12.345');
      expect(_typeSequence(f, '123456'), '123.456');
      expect(_typeSequence(f, '1234567'), '1.234.567');
    });

    test('yazılan nokta ondalık virgüle döner', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '1234.5'), '1.234,5');
    });

    test('virgülle yazım doğrudan çalışır', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '1234,56'), '1.234,56');
    });

    test('decimalDigits sınırını aşan hane eklenmez', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '1234,5678'), '1.234,56');
    });

    test('decimalDigits: 0 iken virgül girilemez, sonraki rakam tam kısma eklenir',
        () {
      final f = AmountInputFormatter(decimalDigits: 0);
      expect(_typeSequence(f, '1234,5'), '12.345');
    });

    test('baş sıfırlar temizlenir', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '007'), '7');
    });

    test('yalnız virgülle başlanırsa 0, eklenir', () {
      final f = AmountInputFormatter();
      final r = f.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
            text: ',5', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(r.text, '0,5');
    });

    test('allowNegative olmadan eksi kabul edilmez', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '-500'), '500');
    });

    test('allowNegative ile eksi bakiye desteklenir', () {
      final f = AmountInputFormatter(allowNegative: true);
      expect(_typeSequence(f, '-1234,5'), '-1.234,5');
    });

    test('tam kısım kMaxAmount ile uyumlu 9 haneyle sınırlıdır', () {
      final f = AmountInputFormatter();
      expect(_typeSequence(f, '1234567890'), '123.456.789');
    });

    test('gruplama noktası silinince bitişik rakam da silinir', () {
      final f = AmountInputFormatter();
      // "1.234" içinde imleç noktanın hemen sağındayken backspace: Flutter
      // yalnız noktayı siler ("1234"); nokta yeniden ekleneceğinden bu boşa
      // giderdi, o yüzden formatter solundaki rakamı da düşürür → "234".
      const old = TextEditingValue(text: '1.234');
      const withoutDot = TextEditingValue(
        text: '1234',
        selection: TextSelection.collapsed(offset: 1),
      );
      final r = f.formatEditUpdate(old, withoutDot);
      expect(r.text, '234');
    });

    test('yapıştırma: nokta gruplama, virgül ondalık olarak yorumlanır', () {
      final f = AmountInputFormatter();
      final r = f.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1.234,56'),
      );
      expect(r.text, '1.234,56');
    });

    test('yapıştırma: tek nokta ondalık sayılır (üç haneli kuyruk hariç)',
        () {
      final f = AmountInputFormatter();
      final r = f.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '12.5'),
      );
      expect(r.text, '12,5');
    });
  });

  group('formatAmountForInput', () {
    test('tam sayıda ondalık gösterilmez', () {
      expect(formatAmountForInput(1234), '1.234');
    });

    test('kuruş varsa sondaki sıfırlar atılır', () {
      expect(formatAmountForInput(1234.5), '1.234,5');
      expect(formatAmountForInput(1234.56), '1.234,56');
    });

    test('negatif tutar işareti korunur', () {
      expect(formatAmountForInput(-500.5), '-500,5');
    });

    test('decimalDigits artırılabilir (adet/oran alanları)', () {
      expect(formatAmountForInput(0.125, decimalDigits: 4), '0,125');
    });
  });

  group('parseAmountInput / parseMoneyInput / validateAmountInput', () {
    test('gruplu metni doğru sayıya çevirir', () {
      expect(parseAmountInput('1.234,56'), 1234.56);
      expect(parseAmountInput('123.456.789'), 123456789);
    });

    test('parseMoneyInput kuruşa yuvarlar', () {
      expect(parseMoneyInput('1.234,566'), 1234.57);
    });

    test('validateAmountInput sıfırı reddeder, formatlı geçerli tutarı kabul eder',
        () {
      expect(validateAmountInput('0'), isNotNull);
      expect(validateAmountInput('1.234,56'), isNull);
    });
  });
}
