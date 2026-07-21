import 'package:cunehat/features/bank_import/data/pdf_parsers/akbank_pdf_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AkbankPdfParser', () {
    const parser = AkbankPdfParser();

    test('canParse: başlıkta akbank geçerse true', () {
      expect(parser.canParse('AKBANK T.A.Ş. HESAP ÖZETİ\n25/03/2026 ...'), isTrue);
      expect(parser.canParse('Akbank T.A.Ş.\n25/03/2026 ...'), isTrue);
      expect(parser.canParse('Garanti BBVA\n...'), isFalse);
    });

    test('canParse: başlık dışında (işlem açıklamasında) geçen banka adını YOK sayar', () {
      // Gerçek senaryo: bir Garanti ekstresinde bir EFT açıklamasında karşı
      // tarafın bankası olarak "Akbank" geçebilir — bu, ekstrenin Akbank'a
      // ait olduğu anlamına gelmez. canParse yalnız başlığa (ilk 20 satır)
      // bakmalı, 20+ satır sonraki gövde metnine değil.
      final bodyMentionsAkbank = StringBuffer('GARANTİ BBVA HESAP ÖZETİ\n');
      for (var i = 0; i < 25; i++) {
        bodyMentionsAkbank.writeln('dolgu satırı $i');
      }
      bodyMentionsAkbank.writeln(
          '25/03/2026 FEFT Transfer - Alıcı Akbank T.A.Ş. Şubesi 100.00 200.00');
      expect(parser.canParse(bodyMentionsAkbank.toString()), isFalse);
    });

    test('parses exact Akbank image sample with correct amounts and types', () {
      const sampleText = '''
AKBANK T.A.Ş. HESAP ÖZETİ
25/03/2026 FEFT Transfer İşlemleri - Gönderen: HALİL İBRAHİM AVŞAR Sorgu No: 1131155 - 5534888152 Halil İbrahim Avşa Akbank T.A.Ş. 6,500.00 7,958.43
25/03/2026 MB Transfer İşlemleri - Alıcı:Midas Menkul Değerler Anonim Şirketi-KA44QAPE4U Al.Hs: 101213755 Mobil Bankacılık -7,000.00 958.43
25/03/2026 POS Kart İşlemleri - 000000003598401-DEMIR MARKET ISTANBUL TR Pos satış. -67.00 891.43
26/03/2026 POS Kart İşlemleri - 000000000713593-SHELL ACIBADEM ISTANBUL TR Pos satış. -293.62 597.81
01/04/2026 POS Kart İşlemleri - 000000000269480-DEMKAR PETROL ISTANBUL TR Pos satış. -350.00 247.81
04/04/2026 POS Kart İşlemleri - 0000000002419511-SOK-10419-USKUDAR YU ISTANBUL TR Pos satış. -203.40 44.41
''';

      final drafts = parser.parseLines(sampleText).drafts;

      expect(drafts.length, 6);

      // Row 1: Income (+6500.00)
      expect(drafts[0].date, DateTime(2026, 3, 25));
      expect(drafts[0].amount, 6500.00);
      expect(drafts[0].type, TransactionTypeModel.income);
      expect(drafts[0].description, contains('Transfer İşlemleri - Gönderen: HALİL İBRAHİM AVŞAR'));

      // Row 2: Expense (-7000.00)
      expect(drafts[1].date, DateTime(2026, 3, 25));
      expect(drafts[1].amount, 7000.00);
      expect(drafts[1].type, TransactionTypeModel.expense);
      expect(drafts[1].description, contains('Midas Menkul'));

      // Row 3: Expense (-67.00)
      expect(drafts[2].date, DateTime(2026, 3, 25));
      expect(drafts[2].amount, 67.00);
      expect(drafts[2].type, TransactionTypeModel.expense);
      expect(drafts[2].description, contains('DEMIR MARKET'));

      // Row 4: Expense (-293.62)
      expect(drafts[3].date, DateTime(2026, 3, 26));
      expect(drafts[3].amount, 293.62);
      expect(drafts[3].type, TransactionTypeModel.expense);
      expect(drafts[3].description, contains('SHELL ACIBADEM'));

      // Row 5: Expense (-350.00)
      expect(drafts[4].date, DateTime(2026, 4, 1));
      expect(drafts[4].amount, 350.00);
      expect(drafts[4].type, TransactionTypeModel.expense);
      expect(drafts[4].description, contains('DEMKAR PETROL'));

      // Row 6: Expense (-203.40)
      expect(drafts[5].date, DateTime(2026, 4, 4));
      expect(drafts[5].amount, 203.40);
      expect(drafts[5].type, TransactionTypeModel.expense);
      expect(drafts[5].description, contains('SOK-10419'));
    });

    test('satıra sarılmış (iki fiziksel satırlık) açıklama kesilmeden korunur', () {
      // Gerçek ekran görüntüsündeki FEFT satırı: syncfusion'ın layoutText:true
      // çıktısında uzun açıklama ikinci bir görsel satıra sarar (o satırda ne
      // tarih ne tutar vardır). Devam satırı önceki taslağa eklenmeli, sessizce
      // düşürülmemeli.
      const wrapped = '''
AKBANK T.A.Ş. HESAP ÖZETİ
25/03/2026 FEFT Transfer İşlemleri - Gönderen: HALİL İBRAHİM AVŞAR Şubesi No: 1191155 - 999/4688492 6,500.00 7,958.43
Halil İbrahim Avşa Akbank T.A.Ş.
25/03/2026 MB Transfer İşlemleri - Alıcı:Midas Menkul Değerler Anonim Şirketi -7,000.00 958.43
''';

      final drafts = parser.parseLines(wrapped).drafts;

      expect(drafts.length, 2);
      expect(drafts[0].amount, 6500.00);
      expect(drafts[0].type, TransactionTypeModel.income);
      // Sarılan devam satırı açıklamaya EKLENMİŞ olmalı, kaybolmamalı.
      expect(drafts[0].description, contains('999/4688492'));
      expect(drafts[0].description, contains('Halil İbrahim Avşa Akbank T.A.Ş.'));
      // İkinci satır kendi taslağı olarak bozulmadan devam etmeli.
      expect(drafts[1].amount, 7000.00);
      expect(drafts[1].type, TransactionTypeModel.expense);
    });

    test('belge başlığından önce gelen sarılmış satır (taslak yoksa) yok sayılır', () {
      const text = '''
Bu bir başlık devam metnidir.
25/03/2026 FEFT Transfer 100.00 200.00
''';
      final drafts = parser.parseLines(text).drafts;
      expect(drafts.length, 1);
      expect(drafts[0].description, isNot(contains('başlık')));
    });

    test('atlanan satır sayısı raporlanır (tarihli ama tutarsız satır)', () {
      const text = '''
25/03/2026 FEFT Sadece açıklama tutar yok
25/03/2026 MB Transfer 100.00 200.00
''';
      final result = parser.parseLines(text);
      expect(result.drafts.length, 1);
      expect(result.skippedLines, 1);
    });
  });
}
