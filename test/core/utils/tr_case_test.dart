import 'package:cunehat/core/utils/tr_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('upperTr', () {
    test('noktalı i büyürken noktasını korur', () {
      expect(upperTr('Vadesiz Hesap'), 'VADESİZ HESAP');
      expect(upperTr('Bakiye'), 'BAKİYE');
      expect(upperTr('iş'), 'İŞ');
    });

    test('noktasız ı büyürken noktasız kalır', () {
      expect(upperTr('Yatırım'), 'YATIRIM');
      expect(upperTr('ışık'), 'IŞIK');
    });

    test('diğer Türkçe harfler Unicode varsayılanıyla doğru', () {
      expect(upperTr('çğöşü'), 'ÇĞÖŞÜ');
      expect(upperTr('Borç'), 'BORÇ');
    });

    test('toUpperCase() ile farkı ölçülür — regresyon kilidi', () {
      expect('Vadesiz'.toUpperCase(), 'VADESIZ'); // hatalı davranış
      expect(upperTr('Vadesiz'), 'VADESİZ'); // doğrusu
    });

    test('zaten büyük harfli ve boş girdi bozulmaz', () {
      expect(upperTr('VADESİZ'), 'VADESİZ');
      expect(upperTr(''), '');
    });
  });
}
