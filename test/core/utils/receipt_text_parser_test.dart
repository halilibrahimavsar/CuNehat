import 'package:cunehat/core/utils/receipt_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMoneyToken', () {
    test('Türkçe biçim: nokta binlik, virgül ondalık', () {
      expect(parseMoneyToken('1.234,56'), 1234.56);
      expect(parseMoneyToken('2.500,00'), 2500.00);
      expect(parseMoneyToken('123,45'), 123.45);
      expect(parseMoneyToken('12,50'), 12.50);
    });

    test('İngiliz biçim: virgül binlik, nokta ondalık', () {
      expect(parseMoneyToken('1,234.56'), 1234.56);
      expect(parseMoneyToken('123.45'), 123.45);
    });

    test('ayraçsız / gruplama-yalnız tam sayılar', () {
      expect(parseMoneyToken('1500'), 1500);
      expect(parseMoneyToken('1.500'), 1500); // TR binlik, ondalık yok
      expect(parseMoneyToken('12.000'), 12000);
    });

    test('geçersiz token null döner', () {
      expect(parseMoneyToken('abc'), isNull);
      expect(parseMoneyToken(''), isNull);
    });
  });

  group('parseReceiptText - tutar', () {
    test('TOPLAM anahtarındaki tutarı seçer (ARA TOPLAM/KDV değil)', () {
      const raw = '''
MIGROS
ARA TOPLAM      90,00
KDV %10          9,00
TOPLAM          99,00
NAKIT          100,00
''';
      final r = parseReceiptText(raw);
      expect(r.amount, 99.00);
    });

    test('GENEL TOPLAM, TOPLAM\'a göre önceliklidir', () {
      const raw = '''
TOPLAM          50,00
GENEL TOPLAM   150,00
''';
      final r = parseReceiptText(raw);
      expect(r.amount, 150.00);
    });

    test('anahtar satırında tutar yoksa bir alt satıra bakar', () {
      const raw = '''
TOPLAM
       250,75
''';
      final r = parseReceiptText(raw);
      expect(r.amount, 250.75);
    });

    test('anahtar yoksa en büyük para benzeri değere düşer', () {
      const raw = '''
Bir Kahve       45,50
Su               5,00
''';
      final r = parseReceiptText(raw);
      expect(r.amount, 45.50);
    });

    test('binlik ayraçlı büyük tutarı doğru okur', () {
      const raw = 'GENEL TOPLAM   1.234,56 TL';
      final r = parseReceiptText(raw);
      expect(r.amount, 1234.56);
    });

    test('tutar bulunamazsa null', () {
      const raw = 'Teşekkür ederiz\nyine bekleriz';
      final r = parseReceiptText(raw);
      expect(r.amount, isNull);
    });
  });

  group('parseReceiptText - tarih', () {
    test('gg.aa.yyyy okur', () {
      final r = parseReceiptText('Tarih: 15.06.2026 Saat 14:30');
      expect(r.date, DateTime(2026, 6, 15));
    });

    test('gg/aa/yy okur (2000+ yıl)', () {
      final r = parseReceiptText('05/03/26');
      expect(r.date, DateTime(2026, 3, 5));
    });

    test('geçersiz ay elenir', () {
      final r = parseReceiptText('45.99.2026');
      expect(r.date, isNull);
    });
  });

  group('parseReceiptText - satıcı', () {
    test('en üst anlamlı satırı satıcı olarak alır', () {
      const raw = '''
BIM BIRLESIK MAGAZALAR
Fiş No: 123
TOPLAM 20,00
''';
      final r = parseReceiptText(raw);
      expect(r.merchant, 'BIM BIRLESIK MAGAZALAR');
    });
  });

  test('hasAnyField boş metinde false', () {
    final r = parseReceiptText('');
    expect(r.hasAnyField, isFalse);
    expect(r.rawText, '');
  });
}
