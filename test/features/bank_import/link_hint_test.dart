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
        'kart ÖDEMESİ borç ödemesi DEĞİLDİR (karta transfer — ölçüldü: 10+ '
        'satır)', () {
      expect(
          linkHintOf('545847 5690 NOLU KART ODEMESI', isIncome: false), isNull);
      expect(
          linkHintOf('5690 ILE BITEN QNB KREDI KARTI ODEMESI', isIncome: false),
          isNull);
      expect(
          linkHintOf('EFT KART ISLEMLERI KREDI KARTLARI OTOMATIK ODEME',
              isIncome: false),
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
}
