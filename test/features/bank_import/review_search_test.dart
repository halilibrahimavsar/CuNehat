import 'package:cunehat/features/bank_import/presentation/review_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('draftAmountMatches', () {
    test('tam sayı yazımı kuruşlu tutarı bulur (913 → 913,15)', () {
      expect(draftAmountMatches(913.15, '913'), isTrue);
    });

    test('Türkçe ondalık virgül ve binlik nokta', () {
      expect(draftAmountMatches(913.15, '913,15'), isTrue);
      expect(draftAmountMatches(913.15, '913,1'), isTrue);
      expect(draftAmountMatches(1234.56, '1.234,56'), isTrue);
      expect(draftAmountMatches(1234.56, '1.234'), isTrue);
      expect(draftAmountMatches(1234567.89, '1.234.567'), isTrue);
    });

    test('İngilizce klavyeden ondalık nokta', () {
      expect(draftAmountMatches(913.15, '913.15'), isTrue);
      expect(draftAmountMatches(913.15, '913.1'), isTrue);
    });

    test('tutarın ORTASINDAN eşleşmez', () {
      expect(draftAmountMatches(913.15, '13'), isFalse);
      expect(draftAmountMatches(913.15, '15'), isFalse);
    });

    test('para simgesi ve boşluk yok sayılır', () {
      expect(draftAmountMatches(913.15, '913 ₺'), isTrue);
      expect(draftAmountMatches(913.15, '₺913'), isTrue);
    });

    test('metin sorgusu tutar araması değildir', () {
      expect(draftAmountMatches(913.15, 'bim'), isFalse);
      expect(draftAmountMatches(913.15, ''), isFalse);
      expect(draftAmountMatches(913.15, ','), isFalse);
      expect(draftAmountMatches(913.15, '9a'), isFalse);
    });
  });
}
