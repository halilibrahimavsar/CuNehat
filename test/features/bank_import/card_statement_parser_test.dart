import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:flutter_test/flutter_test.dart';

/// QNB kart HESAP EKSTRESİ biçimi (sentetik veriler). Künyedeki bazı harfler
/// gerçek dosyadaki gibi eşlemesiz glif olarak gelir ("D2 nem", "3 deme",
/// "Eyl6 l"): okuyucu bunlara rağmen künyeyi çıkarmalı.
const _closed = '''
QNB Kredi Kartı
Kredi Kartı Numarası:1234 56** **** 4321 Son 3 deme Tarihi: 04 Eyl6 l 2026, Cuma
Hesap Kesim Tarihi : 25/08/2026
D2 nem Borcu : 1,750.00 TL
Asgari 3 deme Tutarı : 620.00 TL
Kredi Kartı Limiti:50,000.00 TL
3 nceki D2 nem Bakiyeniz 100.00
ASIL KART: 1234 56** **** 4321 - AD SOYAD
01/08/2026 4 deme - Tesekk0 r Ederiz - -100.00
27/07/2026 ORNEK MARKET 9 STANBUL TRTR 1,200.00
Bu alı1 veri1 inizin sipari1 kodu: 111
10/08/2026 ORNEK AKARYAKIT 500.00
14/08/2026 ORNEK KIRALAMA 300.00
14/08/2026 ORNEK KIRALAMA -300.00
20/08/2026 ORNEK MOBILYA 50.00 2/6
Genel Toplam - TL Hesap Ekstresi 1,750.00
''';

const _period = '''
23/09/2026 tarihli son 4 hanesi 4321 olan kartınıza ait Dönem İçi Hareketler
İşlem Tarihi Açıklama Tutar Güncel / Toplam ParaPuan
Taksitler
27/08/2026 Ödeme - Tesekkür Ederiz - -1550,0 TRY 0/0,0 0,0
27/08/2026 ORNEK ABONELIK 75,0 TRY 1/1,0 0,0
01/09/2026 ORNEK BUFE 32,25 TRY 0/0,0 0,0
11/09/2026 20260911 ORNEK MAGAZA 1. Taksit 503,03 TRY 1/3,0 0,0
11/09/2026 ORNEK SIGORTA 5265,46 TRY 0/0,0 0,0
''';

void main() {
  group('hesap ekstresi', () {
    final r = parseCardStatement(_closed)!;

    test(
        'künye: kesim, son ödeme (bozuk ay adından), dönem borcu, asgari, '
        'limit, önceki bakiye, son 4 hane', () {
      final f = r.facts;
      expect(f.isClosedStatement, isTrue);
      expect(f.closingDate, DateTime(2026, 8, 25));
      expect(f.dueDate, DateTime(2026, 9, 4));
      expect(f.statementBalance, 1750);
      expect(f.minimumPayment, 620);
      expect(f.limit, 50000);
      expect(f.previousBalance, 100);
      expect(f.last4, '4321');
    });

    test('KART işaret kuralı: artı harcama, eksi ödeme/iade', () {
      expect(r.drafts, hasLength(6));
      final byDesc = {
        for (final d in r.drafts) '${d.description}|${d.amount}': d.isIncome
      };
      expect(byDesc['ORNEK AKARYAKIT|500.0'], isFalse);
      expect(byDesc['ORNEK KIRALAMA|300.0'], isNotNull);
      expect(r.drafts.where((d) => d.isIncome), hasLength(2),
          reason: 'ödeme + iade');
    });

    test(
        'bozuk glifli ödeme satırı tanınıp düzeltilir; devam satırları '
        'harekete karışmaz', () {
      final payment = r.drafts.firstWhere((d) => d.isIncome && d.amount == 100);
      expect(payment.description, 'Ödeme - Teşekkür Ederiz');
      expect(r.drafts.any((d) => d.description.contains('sipari')), isFalse);
    });

    test('taksit numarası açıklamaya işlenir (2/6, 1/6\'nın tekrarı değil)',
        () {
      expect(
          r.drafts.any((d) => d.description == 'ORNEK MOBILYA (2/6)'), isTrue);
    });
  });

  test(
      'önceki bakiye + hareketler = dönem borcu → DOĞRULANDI; tutmazsa '
      'BAŞARISIZ', () {
    // 100 − 100 + 1200 + 500 + 300 − 300 + 50 = 1750
    expect(parseCardStatement(_closed)!.verification.status,
        StatementVerificationStatus.verified);
    final bad = parseCardStatement(_closed.replaceAll(
        'D2 nem Borcu : 1,750.00 TL', 'D2 nem Borcu : 1,550.00 TL'))!;
    expect(bad.verification.status, StatementVerificationStatus.failed);
  });

  group('dönem içi hareketler', () {
    final r = parseCardStatement(_period)!;

    test(
        'tek ondalıklı tutarlar ve TRY eki okunur; başlık satırı atlanmış '
        'SAYILMAZ', () {
      expect(r.drafts, hasLength(5));
      expect(r.skippedLines, 0);
      expect(r.drafts.map((d) => d.amount),
          containsAll([1550.0, 75.0, 32.25, 503.03, 5265.46]));
    });

    test('ödeme gelir, harcama gider; taksit işareti eklenir', () {
      expect(r.drafts.first.isIncome, isTrue);
      expect(r.drafts.where((d) => !d.isIncome), hasLength(4));
      expect(r.drafts.any((d) => d.description.endsWith('1. Taksit (1/3)')),
          isTrue);
      // Tek çekimde (1/1) işaret eklenmez.
      expect(r.drafts.any((d) => d.description == 'ORNEK ABONELIK'), isTrue);
    });

    test('künye yalnız son 4 hane; doğrulama yapılamaz', () {
      expect(r.facts.isClosedStatement, isFalse);
      expect(r.facts.last4, '4321');
      expect(r.verification.status, StatementVerificationStatus.unavailable);
    });
  });

  test('banka hesabı ekstresi kart okuyucusuna GİRMEZ', () {
    expect(
      parseCardStatement('GARANTİ BBVA\n01/08/2026 MARKET -100,00 1.000,00'),
      isNull,
    );
  });

  test('PDF okuyucusu kart ekstresini kart yoluna yönlendirir', () {
    final result = PdfStatementParser().parseText(_period);
    expect(result.cardFacts?.last4, '4321');
    expect(result.drafts, hasLength(5));
  });
}
