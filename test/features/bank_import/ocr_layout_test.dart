import 'package:cunehat/features/bank_import/data/ocr_layout.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

OcrLine _line(String text, double top, double left, {double height = 20}) =>
    OcrLine(text: text, top: top, left: left, height: height);

void main() {
  group('layoutTextFromLines', () {
    test('aynı yükseklikteki parçalar TEK satırda, soldan sağa birleşir', () {
      // ML Kit tabloyu bloklara böler; blok sırası okuma sırasını korumaz.
      // Burada tarih/açıklama/tutar bilerek KARIŞIK sırada veriliyor.
      final text = layoutTextFromLines([
        _line('-4.400,00', 100, 700),
        _line('05.09.2025', 100, 20),
        _line('ATM PARA ÇEKME', 100, 200),
      ]);
      expect(text, '05.09.2025 ATM PARA ÇEKME -4.400,00');
    });

    test('farklı satırlar ayrılır ve yukarıdan aşağıya sıralanır', () {
      final text = layoutTextFromLines([
        _line('B', 140, 20),
        _line('C', 180, 20),
        _line('A', 100, 20),
      ]);
      expect(text, 'A\nB\nC');
    });

    test('hafif dikey kayma aynı satır sayılır (tolerans yüksekliğe göre)', () {
      // Aynı satırdaki parçaların kutuları birkaç piksel kayabilir.
      final text = layoutTextFromLines([
        _line('05.09.2025', 100, 20),
        _line('-134,75', 106, 700),
      ]);
      expect(text, '05.09.2025 -134,75');
    });

    test('boş/boşluk parçalar atılır', () {
      final text = layoutTextFromLines([
        _line('  ', 100, 10),
        _line('A', 100, 20),
      ]);
      expect(text, 'A');
    });

    test('girdi boşsa boş string', () {
      expect(layoutTextFromLines(const []), '');
    });

    test('bozuk (sıfır yükseklikli) kutular toleransı çökertmez', () {
      final text = layoutTextFromLines([
        _line('A', 100, 20, height: 0),
        _line('B', 100, 60, height: 0),
      ]);
      expect(text, 'A B');
    });
  });

  group('OCR metni ayrıştırıcıya bağlanır', () {
    test('yeniden kurulan düzenden taslak çıkar', () {
      // Uçtan uca: OCR parçaları → düzen metni → mevcut PDF ayrıştırıcısı.
      // Böylece banka stratejileri/işaret sezgisi OCR yolunda da çalışır.
      final text = layoutTextFromLines([
        _line('Tutar', 40, 700),
        _line('Tarih', 40, 20),
        _line('-134,75', 100, 700),
        _line('05.09.2025', 100, 20),
        _line('SATIŞ-BİM', 100, 200),
        _line('+2.000,00', 150, 700),
        _line('03.09.2025', 150, 20),
        _line('MAAŞ ÖDEMESİ', 150, 200),
      ]);

      final result = PdfStatementParser().parseText(text);
      expect(result.drafts.length, 2);
      expect(result.drafts[0].date, DateTime(2025, 9, 5));
      expect(result.drafts[0].amount, 134.75);
      expect(result.drafts[0].type, TransactionTypeModel.expense);
      expect(result.drafts[0].description, 'SATIŞ-BİM');
      expect(result.drafts[1].amount, 2000.00);
      expect(result.drafts[1].type, TransactionTypeModel.income);
    });
  });
}
