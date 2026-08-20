import 'package:cunehat/core/utils/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldTr', () {
    test('İ ve I Türkçe kurallarına göre katlanır', () {
      // Bu iki satır düz toLowerCase() ile BAŞARISIZ olur: 'İ' → 'i̇'
      // (i + U+0307), 'I' → 'i'.
      expect(foldTr('İnternet'), 'internet');
      expect(foldTr('Işık'), 'ışık');
    });

    test('katlanmış İ birleşen nokta taşımaz', () {
      expect(foldTr('İ').codeUnits, [0x69]);
    });

    test('diğer Türkçe büyük harfler', () {
      expect(foldTr('ŞGÜÖÇ'), 'şgüöç');
      expect(foldTr('Ğ'), 'ğ');
    });

    test('kırpar ve iç boşlukları tekler', () {
      expect(foldTr('  Su   &  İçecek '), 'su & içecek');
    });
  });

  group('matchesFolded', () {
    test('boş sorgu her şeyi eşler', () {
      expect(matchesFolded('herhangi', ''), isTrue);
    });

    test('Türkçe büyük harfli sorgu küçük harfli metni bulur', () {
      expect(matchesFolded('internet faturası', foldTr('İNTERNET')), isTrue);
      expect(matchesFolded('IŞIK gideri', foldTr('ışık')), isTrue);
    });

    test('eşleşmeyen sorgu false döner', () {
      expect(matchesFolded('market', foldTr('kira')), isFalse);
    });
  });
}
