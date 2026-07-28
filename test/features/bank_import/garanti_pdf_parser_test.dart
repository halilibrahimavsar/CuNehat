import 'package:cunehat/features/bank_import/data/pdf_parsers/garanti_pdf_parser.dart';
import 'package:cunehat/features/bank_import/data/pdf_parsers/pdf_parser_strategy.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kullanıcının GERÇEK Garanti BBVA ekstresinden (syncfusion `layoutText`
/// çıktısı) alınmış kesit. Üç sayfalık belgenin sayfa geçişi dahil edildi:
/// künye + sayfa numarası + tekrar eden sütun başlığı, tarihle başlamadıkları
/// için bir önceki hareketin açıklamasına yapışıyordu.
const _realGarantiText = '''
T. Garanti Bankası A.Ş.
Genel Müdürlük: Nispetiye Mah. Aytar Cad. No:2, Beşiktaş, Levent, 34340, İstanbul
Büyük Mükellefler Vergi Dairesi Başkanlığı Vergi No: 8790017566
Mersis Numarası: 0879 0017 5660 0379
www.garantibbva.com.tr
1 / 3
Bakiye:12,28 TL
25/07/2024 - 25/07/2026 aralığında 85 kayıt bulunmuştur.
TarihAçıklamaEtiketTutarBakiye
05.09.2025ATM PARA ÇEKME-5170********4626-ATM Kodu:01582CRS222Para Çekme -4.400,00 TL12,28 TL
03.09.2025SATIŞ-517040*4626-BİM L508 YUNUS EMRE-SULAlışveriş -134,75 TL4.412,28 TL
04.07.2025MAAŞ ÖDEMESİMaaş +24.279,26 TL39.535,96 TL
07.07.2025KESİNTİ VE EKLERİ-Diğer -12,80 TL10.228,16 TL
T. Garanti Bankası A.Ş.
Genel Müdürlük: Nispetiye Mah. Aytar Cad. No:2, Beşiktaş, Levent, 34340, İstanbul
Büyük Mükellefler Vergi Dairesi Başkanlığı Vergi No: 8790017566
Mersis Numarası: 0879 0017 5660 0379
www.garantibbva.com.tr
2 / 3
TarihAçıklamaEtiketTutarBakiye
05.06.2025SATIŞ-517040*4626-TRENDYOL.COMAlışveriş -619,90 TL21.375,30 TL
''';

void main() {
  group('GarantiPdfParser (gerçek ekstre)', () {
    const parser = GarantiPdfParser();

    test('başlıktaki banka adından tanınır', () {
      expect(parser.canParse(_realGarantiText), isTrue);
    });

    test('tüm hareketler doğru tarih/tutar/işaretle çıkar', () {
      final drafts = parser.parseLines(_realGarantiText).drafts;
      expect(drafts.length, 5);

      expect(drafts[0].date, DateTime(2025, 9, 5));
      expect(drafts[0].amount, 4400.00); // bakiye (12,28) DEĞİL
      expect(drafts[0].type, TransactionTypeModel.expense);

      expect(drafts[2].date, DateTime(2025, 7, 4));
      expect(drafts[2].amount, 24279.26);
      expect(drafts[2].type, TransactionTypeModel.income); // +
    });

    test('REGRESYON: açıklamada "TLTL" artığı kalmaz', () {
      final drafts = parser.parseLines(_realGarantiText).drafts;
      for (final d in drafts) {
        expect(d.description, isNot(contains('TLTL')));
        expect(d.description.trim(), isNot(endsWith('TL')));
      }
    });

    test('REGRESYON: banka etiketi açıklamadan ayrılır ve sourceTag olur', () {
      final drafts = parser.parseLines(_realGarantiText).drafts;

      expect(drafts[0].sourceTag, 'Para Çekme');
      expect(drafts[0].description,
          'ATM PARA ÇEKME-5170********4626-ATM Kodu:01582CRS222');

      expect(drafts[1].sourceTag, 'Alışveriş');
      expect(drafts[1].description, 'SATIŞ-517040*4626-BİM L508 YUNUS EMRE-SUL');

      expect(drafts[2].sourceTag, 'Maaş');
      expect(drafts[2].description, 'MAAŞ ÖDEMESİ');

      expect(drafts[3].sourceTag, 'Diğer');
      expect(drafts[3].description, 'KESİNTİ VE EKLERİ-');
    });

    test('REGRESYON: sayfa künyesi/altbilgisi açıklamaya sızmaz', () {
      final drafts = parser.parseLines(_realGarantiText).drafts;
      for (final d in drafts) {
        expect(d.description, isNot(contains('Genel Müdürlük')));
        expect(d.description, isNot(contains('Mersis')));
        expect(d.description, isNot(contains('garantibbva')));
        expect(d.description, isNot(contains('TarihAçıklama')));
      }
      // Sayfa sonundaki son hareket en çok etkileneni: bir önceki tasarımda
      // 5 satırlık künye + "2 / 3" + sütun başlığı bunun başlığına yapışıyordu.
      expect(drafts[3].description, 'KESİNTİ VE EKLERİ-');
    });
  });

  group('splitTrailingTag', () {
    test('bitişik etiket ayrılır', () {
      expect(PdfParserStrategy.splitTrailingTag('MAAŞ ÖDEMESİMaaş'),
          ('MAAŞ ÖDEMESİ', 'Maaş'));
    });

    test('uzun etiket kısa olandan önce denenir', () {
      expect(PdfParserStrategy.splitTrailingTag('ELEKTRIKFatura Ödemesi'),
          ('ELEKTRIK', 'Fatura Ödemesi'));
    });

    test('boşlukla ayrılmış kelime etiket sayılmaz (açıklamanın parçası)', () {
      expect(PdfParserStrategy.splitTrailingTag('ODEME Fatura'),
          ('ODEME Fatura', null));
    });

    test('açıklamanın tamamı etiketse dokunulmaz', () {
      expect(
          PdfParserStrategy.splitTrailingTag('Alışveriş'), ('Alışveriş', null));
    });

    test('etiket yoksa değişmez', () {
      expect(PdfParserStrategy.splitTrailingTag('TRENDYOL.COM'),
          ('TRENDYOL.COM', null));
    });
  });
}
