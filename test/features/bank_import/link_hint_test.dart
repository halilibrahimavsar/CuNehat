import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('linkHintOf', () {
    test('Yatırım kategorisindeki gider → birikim alımı', () {
      expect(
        linkHintOf('MB Transfer Alıcı:Midas Menkul Değerler',
            isIncome: false, inInvestmentCategory: true),
        LinkHint.investment,
      );
    });

    test('kredi taksidi → borç ödemesi', () {
      expect(linkHintOf('KREDI TAKSIT TAHSILATI 12/36', isIncome: false),
          LinkHint.debtPayment);
      expect(linkHintOf('İhtiyaç Kredisi Ödemesi', isIncome: false),
          LinkHint.debtPayment);
    });

    test(
        'kart ÖDEMESİ borç ödemesi DEĞİL, kart ödemesidir (karta transfer — '
        'ölçüldü: 10+ satır)', () {
      expect(linkHintOf('545847 5690 NOLU KART ODEMESI', isIncome: false),
          LinkHint.cardPayment);
      expect(
          linkHintOf('5690 ILE BITEN QNB KREDI KARTI ODEMESI', isIncome: false),
          LinkHint.cardPayment);
      expect(
          linkHintOf('EFT KART ISLEMLERI KREDI KARTLARI OTOMATIK ODEME',
              isIncome: false),
          LinkHint.cardPayment);
    });

    test('çıplak "kredi kartı" (aidat, alışveriş) kart ödemesi sayılmaz', () {
      expect(linkHintOf('KREDI KARTI YILLIK UYELIK UCRETI', isIncome: false),
          isNull);
    });

    test('kredi kullandırımı (gelir) → kredi girişi', () {
      expect(linkHintOf('IHTIYAC KREDISI KULLANDIRIM', isIncome: true),
          LinkHint.loanDisbursement);
      expect(linkHintOf('KREDI KULLANDIRIM 50.000', isIncome: true),
          LinkHint.loanDisbursement);
    });

    test('sıradan satırlar öneri değildir', () {
      expect(linkHintOf('BIM L508 YUNUS EMRE', isIncome: false), isNull);
      expect(linkHintOf('MAAS ODEMESI', isIncome: true), isNull);
      // Gelir tarafında "taksit" borç ödemesi sayılmaz.
      expect(linkHintOf('KREDI TAKSIT IADESI', isIncome: true), isNull);
    });
  });

  group('kart dökümünde (onCard) yön terstir', () {
    test('karta yapılan ödeme gelir DEĞİL, kendi hesabından gelen paradır', () {
      expect(
        linkHintOf('Ödeme - Teşekkür Ederiz', isIncome: true, onCard: true),
        LinkHint.cardPaymentReceived,
      );
    });

    test('iade satırı ödeme sayılmaz', () {
      expect(
        linkHintOf('E/OTOKOC AVIS', isIncome: true, onCard: true),
        isNull,
      );
    });

    test('karttan başka hesaba havale: kendi hesabına mı diye SORULUR', () {
      expect(
        linkHintOf('ALICI : ORNEK BANK A.S. SORGU NO: 238',
            isIncome: false, onCard: true),
        LinkHint.ownTransfer,
      );
      // Havalenin ücret satırları düz giderdir.
      expect(
        linkHintOf('Kredi Kartı EFT İşlem Ücreti',
            isIncome: false, onCard: true),
        isNull,
      );
    });

    test('hesap ekstresinde aynı metinler bu önerileri ÜRETMEZ', () {
      expect(linkHintOf('Ödeme - Teşekkür Ederiz', isIncome: true), isNull);
      expect(
        linkHintOf('ALICI : ORNEK BANK A.S. SORGU NO: 238', isIncome: false),
        isNull,
      );
    });

    test('kart harcaması öneri değildir', () {
      expect(
        linkHintOf('ORNEK MARKET (2/3)', isIncome: false, onCard: true),
        isNull,
      );
    });
  });

  group('cardIdByLast4', () {
    const cards = [
      (id: 'bonus', last4: '5690'),
      (id: 'world', last4: '1234'),
    ];

    test('açıklamada ayrı sayı olarak geçen TEK kart bulunur', () {
      expect(cardIdByLast4('545847 5690 NOLU KART ODEMESI', cards), 'bonus');
      expect(cardIdByLast4('KART 545847******1234 ODEME', cards), 'world');
    });

    test('daha uzun bir sayının parçası eşleşme sayılmaz', () {
      expect(cardIdByLast4('REF 956901 KART ODEMESI', cards), isNull);
    });

    test('iki kart birden uyuyorsa sormak için null', () {
      expect(cardIdByLast4('5690 VE 1234 KART ODEMELERI', cards), isNull);
    });
  });
}
