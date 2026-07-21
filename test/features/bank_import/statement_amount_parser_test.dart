import 'package:cunehat/features/bank_import/data/statement_amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSignedMoney (işaret korunur)', () {
    test('negatif ve pozitif TR biçim', () {
      expect(parseSignedMoney('-45,00'), -45.0);
      expect(parseSignedMoney('1.234,56'), 1234.56);
      expect(parseSignedMoney('+120,50'), 120.50);
      expect(parseSignedMoney('90,00'), 90.0);
    });

    test('muhasebe parantezi negatiftir', () {
      expect(parseSignedMoney('(90,00)'), -90.0);
      expect(parseSignedMoney('(1.234,56)'), -1234.56);
    });

    test('İngiliz biçim nokta ondalık', () {
      expect(parseSignedMoney('1234.56'), 1234.56);
      expect(parseSignedMoney('-1,234.56'), -1234.56);
    });

    test('geçersiz/boş null', () {
      expect(parseSignedMoney(''), isNull);
      expect(parseSignedMoney('  '), isNull);
      expect(parseSignedMoney('abc'), isNull);
    });
  });

  group('parseUnsignedMoney (borç/alacak sütunu)', () {
    test('pozitif büyüklük', () {
      expect(parseUnsignedMoney('90,00'), 90.0);
      expect(parseUnsignedMoney('1.500'), 1500.0);
    });

    test('sıfır ve boş null (sütun boşsa hareket yok)', () {
      expect(parseUnsignedMoney('0,00'), isNull);
      expect(parseUnsignedMoney(''), isNull);
    });
  });
}
